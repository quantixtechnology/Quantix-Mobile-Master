# Tenant Creation Guide

End-to-end playbook for onboarding a new business tenant onto the Quantix Mobile platform.

---

## Overview

Each tenant gets three production apps built from this master repo:

| App | Purpose | Package ID |
|---|---|---|
| Customer App | End-customer storefront | `com.{slug}.customer` |
| Delivery App | Rider / driver interface | `com.{slug}.delivery` |
| Admin App | Operations dashboard | `com.{slug}.admin` |

All apps share the same core (`shared/` submodule). Branding, business logic, and Firebase config are tenant-specific.

---

## Step 1 — Gather tenant information

Before running anything, collect:

| Field | Example | Notes |
|---|---|---|
| Business name | `Arbaz Fresh Meat` | Display name in the app |
| Slug | `arbaz` | Lowercase, no spaces, used everywhere |
| Package base | `com.arbazfreshmeat` | Reverse domain, no hyphens |
| Business type | `meat` | See `branding/templates/README.md` |
| Primary color | `#1E7A35` | Brand hex color |
| Currency | `INR` | ISO 4217 code |
| Support phone | `+91-9876543210` | Shown in app settings |

---

## Step 2 — Run `create_business.sh`

```bash
./scripts/create_business.sh arbaz \
  --app-name "Arbaz Fresh Meat" \
  --package-base com.arbazfreshmeat \
  --shared-repo https://github.com/quantixtechnology/Quantix-Mobile-Shared.git \
  --type meat \
  --primary-color "#1E7A35" \
  --currency INR \
  --yes
```

**What the script does:**

1. Copies master repo structure into `../Arbaz-Mobile/`
2. Adds `shared/` as a git submodule pointing to Quantix-Mobile-Shared
3. Creates `branding/arbaz/config.json` with tenant values in all three apps
4. Writes placeholder `logo.png` and `splash.png`
5. Updates all three `pubspec.yaml` files — name, description, asset path
6. Rewrites `android/app/build.gradle.kts` with correct `applicationId` per app
7. Runs `flutter pub get` in all packages
8. Creates initial git commit

**Output:** `../Arbaz-Mobile/` — a standalone git repo ready to push to GitHub.

---

## Step 3 — Replace placeholder assets

After the script runs:

```
Arbaz-Mobile/
├── customer_app/branding/arbaz/
│   ├── config.json   ← already filled in by script
│   ├── logo.png      ← REPLACE with real 512×512 brand logo
│   └── splash.png    ← REPLACE with real 1242×2688 splash image
├── delivery_app/branding/arbaz/  (same)
└── admin_app/branding/arbaz/     (same)
```

Asset requirements:

| File | Dimensions | Format | Notes |
|---|---|---|---|
| `logo.png` | 512×512 px | PNG, transparent background | App bar + splash brand mark |
| `splash.png` | 1242×2688 px | PNG or JPEG | Launch screen background |

---

## Step 4 — Firebase setup (per app)

Each app that uses push notifications needs its own Firebase project registration.

**Customer App:**

1. Go to [Firebase Console](https://console.firebase.google.com) → Add project: `arbaz-customer`
2. Add Android app → package name: `com.arbazfreshmeat.customer`
3. Download `google-services.json` → place at `customer_app/android/app/google-services.json`
4. Uncomment `Firebase.initializeApp()` in `customer_app/lib/main.dart`
5. Add google-services plugin to `customer_app/android/app/build.gradle.kts`:

```kotlin
plugins {
    // existing plugins ...
    id("com.google.gms.google-services")
}
```

6. Add to `customer_app/android/build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

> `google-services.json` is in `.gitignore` — store it in a secure secrets manager, not source control.

---

## Step 5 — Google Maps setup (customer_app + delivery_app)

1. Go to [Google Cloud Console](https://console.cloud.google.com) → APIs → Maps SDK for Android → Enable
2. Create an API key restricted to `com.{slug}.customer` and `com.{slug}.delivery`
3. Add to `customer_app/android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}"/>
```

4. Pass key via `local.properties` or CI secret — never hardcode it.

---

## Step 6 — Environment configuration

Create `customer_app/.env` (not committed — add to `.gitignore`):

```env
API_BASE_URL=https://api.arbaz.quantix.app/v1
SOCKET_URL=wss://api.arbaz.quantix.app
```

Read in `shared/lib/config/app_config.dart` via `--dart-define`.

---

## Step 7 — CI / CD for the tenant repo

After pushing `Arbaz-Mobile` to GitHub, set up Actions:

1. Copy `.github/workflows/dart.yml` from this master repo into `Arbaz-Mobile/.github/workflows/`
2. Update the `FLAVOR` dart-define to `arbaz`:

```yaml
- name: Build APK
  working-directory: customer_app
  run: flutter build apk --release --dart-define=FLAVOR=arbaz
```

3. Add GitHub secrets:
   - `GOOGLE_SERVICES_JSON` — base64-encoded `google-services.json`
   - `MAPS_API_KEY`

4. Add a CI step to restore `google-services.json` before the build:

```yaml
- name: Restore google-services.json
  run: echo "${{ secrets.GOOGLE_SERVICES_JSON }}" | base64 -d > customer_app/android/app/google-services.json
```

---

## Step 8 — Verify the tenant build

```bash
cd Arbaz-Mobile/customer_app
flutter build apk --release --dart-define=FLAVOR=arbaz
# Expected: ✓ Built build/app/outputs/flutter-apk/app-release.apk

flutter analyze --no-pub
# Expected: No issues found!
```

---

## Step 9 — Receiving future shared updates

When Quantix ships a core update:

```bash
cd Arbaz-Mobile/
./scripts/update_shared.sh   # pulls latest shared, re-runs pub get, analyzes, commits
```

See [UPDATE_GUIDE.md](../UPDATE_GUIDE.md) for rollback instructions.

---

## Tenant checklist

- [ ] `create_business.sh` ran successfully
- [ ] `logo.png` and `splash.png` replaced in all three apps
- [ ] `config.json` values verified (appName, colors, features)
- [ ] Firebase project created and `google-services.json` stored in secrets
- [ ] Maps API key configured and restricted
- [ ] `.env` configured for backend URL
- [ ] GitHub repo created and pushed
- [ ] CI workflow added and passing
- [ ] Release APK built and tested on a real device
- [ ] Play Store listing created with correct `applicationId`

---

## Flavor → app ID mapping

| App | `applicationId` |
|---|---|
| customer_app | `com.{slug}.customer` |
| delivery_app | `com.{slug}.delivery` |
| admin_app | `com.{slug}.admin` |

Always pass `--dart-define=FLAVOR={slug}` to every `flutter run` and `flutter build` command.
