# Firebase Per-Tenant Setup

Each tenant business needs three Firebase apps — one per mobile app (customer, delivery, admin). This guide walks through creating them and wiring them into the Quantix CI pipeline.

---

## Overview

| App | Package name | Firebase app | CI Secret |
|---|---|---|---|
| Customer app | `com.{slug}` | Android app | `CUSTOMER_FIREBASE_OPTIONS` / `CUSTOMER_GOOGLE_SERVICES` |
| Delivery app | `com.{slug}.delivery` | Android app | `DELIVERY_FIREBASE_OPTIONS` / `DELIVERY_GOOGLE_SERVICES` |
| Admin app | `com.{slug}.admin` | Android app | `ADMIN_FIREBASE_OPTIONS` / `ADMIN_GOOGLE_SERVICES` |

> **Placeholder stubs committed to git are safe.** Real credentials are injected by CI via GitHub Secrets. `firebase_options.dart` placeholder stubs never contain real API keys. `google-services.json` is gitignored.

---

## Step 1 — Create the Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com) → **Add project**
2. Name: `{TenantName} Quantix` (e.g., `Freshmart Quantix`)
3. Enable Google Analytics if desired → **Create project**

---

## Step 2 — Add Android apps

In the Firebase console, for the new project:

### Customer app
1. **Add app → Android**
2. Android package name: `com.{slug}` (e.g., `com.freshmart`)
3. App nickname: `Freshmart Customer`
4. Download `google-services.json` — save it securely (not in git)
5. Skip SDK setup steps (FlutterFire handles init)

### Delivery app
1. **Add app → Android**
2. Android package name: `com.{slug}.delivery`
3. App nickname: `Freshmart Delivery`
4. Download `google-services.json` — save it securely

### Admin app
1. **Add app → Android**
2. Android package name: `com.{slug}.admin`
3. App nickname: `Freshmart Admin`
4. Download `google-services.json` — save it securely

---

## Step 3 — Enable Firebase services

In the Firebase project, enable as needed:

- **Authentication** → Sign-in method → Phone (for OTP)
- **Cloud Messaging** → required for push notifications (enabled by default)
- **Crashlytics** → Crash reports (enable in console; no extra setup needed since we use manual FlutterFire init)
- **Analytics** → Enabled automatically with Google Analytics

---

## Step 4 — Generate `firebase_options.dart`

Install FlutterFire CLI on your local machine (one-time):

```bash
dart pub global activate flutterfire_cli
```

For **each** of the three apps:

```bash
# Customer app
cd /path/to/{slug}-Mobile/customer_app
flutterfire configure \
  --project={firebase-project-id} \
  --platforms=android \
  --android-package-name=com.{slug} \
  --out=lib/firebase_options.dart \
  --yes

# Delivery app
cd /path/to/{slug}-Mobile/delivery_app
flutterfire configure \
  --project={firebase-project-id} \
  --platforms=android \
  --android-package-name=com.{slug}.delivery \
  --out=lib/firebase_options.dart \
  --yes

# Admin app
cd /path/to/{slug}-Mobile/admin_app
flutterfire configure \
  --project={firebase-project-id} \
  --platforms=android \
  --android-package-name=com.{slug}.admin \
  --out=lib/firebase_options.dart \
  --yes
```

Each command generates a `lib/firebase_options.dart` containing the real API keys for that app.

---

## Step 5 — Add GitHub Secrets to the tenant repo

Go to: **GitHub → {slug}-Mobile repo → Settings → Secrets and variables → Actions**

Add the following secrets:

| Secret | Value |
|---|---|
| `CUSTOMER_FIREBASE_OPTIONS` | Full contents of `customer_app/lib/firebase_options.dart` (generated in Step 4) |
| `DELIVERY_FIREBASE_OPTIONS` | Full contents of `delivery_app/lib/firebase_options.dart` |
| `ADMIN_FIREBASE_OPTIONS` | Full contents of `admin_app/lib/firebase_options.dart` |
| `CUSTOMER_GOOGLE_SERVICES` | Full contents of the customer app's `google-services.json` |
| `DELIVERY_GOOGLE_SERVICES` | Full contents of the delivery app's `google-services.json` |
| `ADMIN_GOOGLE_SERVICES` | Full contents of the admin app's `google-services.json` |

Also add the signing secrets if not already present:

| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | `base64 -i quantix-release.jks` (shared keystore for all tenant builds) |
| `KEY_ALIAS` | Keystore key alias |
| `KEY_PASSWORD` | Key password |
| `STORE_PASSWORD` | Keystore password |
| `PROVISION_WEBHOOK_URL` | `https://mobile.quantixtechnology.in` |
| `PROVISION_API_KEY` | API key matching `API_KEY` in mobile-provision `.env` |

---

## Step 6 — Verify CI picks up the secrets

Trigger a CI run (push any commit):

```bash
git commit --allow-empty -m "chore: trigger CI"
git push
```

In GitHub Actions, check the **Write Firebase options** step — it should print nothing (secrets are masked). The build should complete without `firebase_options.dart not found` errors.

---

## Step 7 — Update provision service `firebaseStatus`

Once Firebase is configured for the tenant, update the provision record:

```bash
curl -X PATCH https://mobile.quantixtechnology.in/mobile/tenants/{slug} \
  -H "X-Api-Key: $PROVISION_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"firebaseStatus": "CONFIGURED"}'
```

The admin dashboard Mobile section will now show **Firebase: Configured** for the tenant.

---

## FCM server key (for push notifications)

If the backend needs to send push notifications directly:

1. Firebase console → Project settings → Cloud Messaging
2. Under **Cloud Messaging API (V1)** → note the **Sender ID**
3. For HTTP v1 API: use a service account JSON key
   - Project settings → Service accounts → Generate new private key
   - Store securely; never commit to git

---

## Checklist per tenant

- [ ] Firebase project created
- [ ] Three Android apps added (customer / delivery / admin)
- [ ] FCM, Crashlytics, Analytics enabled
- [ ] `firebase_options.dart` generated for each app via FlutterFire CLI
- [ ] All 6 Firebase secrets added to tenant GitHub repo
- [ ] CI run completes green with real Firebase credentials
- [ ] `firebaseStatus` updated to `CONFIGURED` in provision service
