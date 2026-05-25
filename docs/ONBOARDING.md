# Quantix Mobile — Business Onboarding Flow

This document describes the end-to-end process for onboarding a new business tenant onto the Quantix Mobile platform.

---

## Flow Overview

```
1. Business Registration (Core API)
         ↓
2. Tenant Provisioning
         ↓
3. Branding Configuration
         ↓
4. Firebase Project Setup
         ↓
5. App Build & Signing
         ↓
6. Store Publishing
         ↓
7. Go-Live Verification
```

---

## Step 1 — Business Registration

**Actor:** Quantix Operations / Business Owner

The business owner registers via the Quantix Core API or admin portal:

```http
POST /api/businesses
{
  "name": "Fresh Bites",
  "slug": "fresh-bites",
  "type": "restaurant",
  "email": "admin@freshbites.pk",
  "phone": "+92300XXXXXXX",
  "city": "Lahore"
}
```

**Response includes:**
- `businessId` — the tenant identifier used in all API calls
- `adminCredentials` — temporary email + password for the admin app
- `apiKey` — for server-to-server calls

**Artifacts produced:**
- Tenant record in Quantix Core database
- Default delivery zone (city-wide)
- Default delivery fee (PKR 50)

---

## Step 2 — Tenant Provisioning

**Actor:** Quantix System (automated)

The Core API automatically:
- Creates isolated data namespace (all records scoped by `businessId`)
- Sets up default product categories
- Creates default operating hours (9am–10pm)
- Generates seed branding config (`primaryColor: #2563EB`, logo placeholder)

Verify tenant is live:
```http
GET /api/businesses/{businessId}/config
X-Business-ID: {businessId}
```

---

## Step 3 — Branding Configuration

**Actor:** Quantix Operations (from Admin App settings or Core API)

Upload the tenant's brand assets:

```http
PATCH /api/businesses/{businessId}/branding
{
  "appName": "Fresh Bites",
  "primaryColor": "#E11D48",
  "secondaryColor": "#F97316",
  "currency": "PKR",
  "logoUrl": "https://cdn.quantix.pk/fresh-bites/logo.png",
  "splashUrl": "https://cdn.quantix.pk/fresh-bites/splash.png",
  "features": {
    "loyalty": false,
    "trackingMap": true,
    "cashOnDelivery": true,
    "cardPayment": false
  }
}
```

**Branding asset checklist:**
- [ ] App icon (1024×1024 PNG, no alpha)
- [ ] Splash logo (512×512 PNG)
- [ ] Primary brand color (hex)
- [ ] App display name

Place assets in `branding/<tenant-slug>/`:
```
branding/fresh-bites/
  config.json          # BrandConfig JSON
  logo.png
  splash.png
  icon.png
```

---

## Step 4 — Firebase Project Setup

**Actor:** Quantix DevOps

See [DEPLOYMENT.md](./DEPLOYMENT.md#1-firebase-setup-per-tenant) for full steps.

Quick summary:

```bash
# 1. Create Firebase project: quantix-fresh-bites
# 2. Register 3 apps (customer, delivery, admin)
# 3. Enable: Phone Auth, FCM, Crashlytics, Analytics
# 4. Run flutterfire configure for each app
# 5. Store firebase_options.dart contents in GitHub Secrets
# 6. Download google-services.json for Android builds
```

**Time estimate:** 30–45 minutes

---

## Step 5 — App Build & Signing

**Actor:** Quantix DevOps (automated via CI)

### Option A — CI/CD Build (recommended)

1. Push to `main` branch — GitHub Actions triggers automatically
2. CI injects Firebase credentials and keystore from secrets
3. Signed AABs are produced as artifacts:
   - `quantix-customer-release-aab`
   - `quantix-delivery-release-aab`
   - `quantix-admin-release-aab`

### Option B — Local Build

```bash
# Set FLAVOR to the tenant slug
export FLAVOR=fresh-bites

cd customer_app
flutter build appbundle --release --dart-define=FLAVOR=$FLAVOR
```

**Required before building:**
- `branding/fresh-bites/config.json` exists
- `customer_app/lib/firebase_options.dart` generated
- `customer_app/android/app/google-services.json` placed
- `customer_app/android/key.properties` configured

---

## Step 6 — Store Publishing

**Actor:** Quantix Operations / Business Owner

### Google Play (Android)

1. Log in to [Google Play Console](https://play.google.com/console)
2. Create new apps (or use existing Quantix apps for white-label)
3. Upload AABs to **Internal Testing** track
4. Complete store listing:
   - Short description (80 chars)
   - Full description
   - Screenshots (phone + tablet)
   - Feature graphic (1024×500)
   - Content rating questionnaire
5. Submit for review (~2–3 days)
6. Promote to **Production** after approval

### Apple App Store (iOS)

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Create new apps with correct bundle IDs
3. Build and upload `.ipa` via Xcode Organizer
4. Fill in metadata, screenshots
5. Submit for review (~1–2 days)

---

## Step 7 — Go-Live Verification

**Actor:** Quantix QA + Business Owner

Run through this checklist before handing over to the client:

### Customer App
- [ ] Login via OTP (phone number)
- [ ] Browse products by category
- [ ] Add to cart, adjust quantities
- [ ] Checkout with delivery address
- [ ] Place order → receive order status notification
- [ ] Track delivery on map
- [ ] View order history

### Delivery App
- [ ] Login with rider credentials
- [ ] See assigned orders
- [ ] Accept order → receive confirmation
- [ ] Mark as picked up → customer notified
- [ ] Mark as delivered → order closes
- [ ] View daily earnings

### Admin App
- [ ] Login with admin credentials
- [ ] View dashboard stats
- [ ] Manage orders (status updates)
- [ ] Update product inventory
- [ ] View customers list
- [ ] Manage delivery riders

### Notifications
- [ ] Customer receives: order confirmed, rider assigned, delivered
- [ ] Rider receives: new assignment, reassignment
- [ ] Admin receives: new order, low stock alert

---

## Tenant Configuration Reference

```json
{
  "businessId": "fresh-bites-lhr",
  "appName": "Fresh Bites",
  "primaryColor": "#E11D48",
  "secondaryColor": "#F97316",
  "currency": "PKR",
  "defaultDeliveryFee": 50,
  "businessType": "restaurant",
  "features": {
    "loyalty": false,
    "trackingMap": true,
    "cashOnDelivery": true,
    "cardPayment": false,
    "multiLocation": false
  },
  "operatingHours": {
    "open": "09:00",
    "close": "22:00",
    "timezone": "Asia/Karachi"
  }
}
```

---

## Estimated Onboarding Timeline

| Phase | Duration |
|-------|----------|
| Business registration + tenant provisioning | 15 min |
| Branding configuration + asset upload | 1–2 hours |
| Firebase project setup | 30–45 min |
| App build (CI) | 15–20 min |
| Play Store review | 2–3 days |
| App Store review | 1–2 days |
| Go-live verification | 1–2 hours |
| **Total (excluding store review)** | **~4 hours** |
