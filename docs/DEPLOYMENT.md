# Quantix Mobile — Deployment Guide

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.41.x (stable) |
| Dart | 3.11.x |
| Java | 17 |
| Xcode | 16+ (iOS builds) |
| Firebase CLI | latest |
| FlutterFire CLI | latest |

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```

---

## 1. Firebase Setup (per tenant)

Each tenant needs its own Firebase project. Repeat these steps for every new client.

### 1.1 Create Firebase project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create project: `quantix-<tenant-slug>`
3. Enable: **Authentication** (Phone, Email/Password), **Cloud Messaging**, **Crashlytics**, **Analytics**

### 1.2 Register apps in Firebase

Register three apps per tenant:

| App | Android Package | iOS Bundle ID |
|-----|----------------|--------------|
| Customer | `com.quantix.customer` | `com.quantix.customer` |
| Delivery | `com.quantix.delivery` | `com.quantix.delivery` |
| Admin | `com.quantix.admin` | `com.quantix.admin` |

### 1.3 Generate firebase_options.dart

Run this in each app directory:

```bash
# customer_app
cd customer_app
flutterfire configure \
  --project=quantix-<tenant-slug> \
  --out=lib/firebase_options.dart \
  --platforms=android,ios

# delivery_app
cd ../delivery_app
flutterfire configure \
  --project=quantix-<tenant-slug> \
  --out=lib/firebase_options.dart \
  --platforms=android,ios

# admin_app
cd ../admin_app
flutterfire configure \
  --project=quantix-<tenant-slug> \
  --out=lib/firebase_options.dart \
  --platforms=android,ios
```

> `firebase_options.dart` is gitignored. Store the generated file contents in GitHub Secrets
> (`CUSTOMER_FIREBASE_OPTIONS`, `DELIVERY_FIREBASE_OPTIONS`, `ADMIN_FIREBASE_OPTIONS`).

### 1.4 Download platform config files

- **Android**: `google-services.json` → place in `<app>/android/app/`
- **iOS**: `GoogleService-Info.plist` → place in `<app>/ios/Runner/`

Both are gitignored. In CI, inject via secrets (see Section 4).

---

## 2. Android Release Signing

### 2.1 Generate keystore (one-time per organisation)

```bash
keytool -genkey -v \
  -keystore quantix-release.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias quantix \
  -dname "CN=Quantix Technology, OU=Mobile, O=Quantix, L=Lahore, S=Punjab, C=PK"
```

Store `quantix-release.jks` **outside** the repo — never commit it.

### 2.2 Create key.properties

Copy from the template and fill in values:

```bash
cp key.properties.example customer_app/android/key.properties
cp key.properties.example delivery_app/android/key.properties
cp key.properties.example admin_app/android/key.properties
```

Edit each file:

```
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=quantix
storeFile=../quantix-release.jks
```

### 2.3 Build signed APK / AAB locally

```bash
# Customer — APK
cd customer_app
flutter build apk --release --dart-define=FLAVOR=quantix

# Customer — AAB (Play Store)
flutter build appbundle --release --dart-define=FLAVOR=quantix

# Delivery
cd ../delivery_app
flutter build appbundle --release --dart-define=FLAVOR=quantix

# Admin
cd ../admin_app
flutter build appbundle --release --dart-define=FLAVOR=quantix
```

Output paths:
- `<app>/build/app/outputs/flutter-apk/app-release.apk`
- `<app>/build/app/outputs/bundle/release/app-release.aab`

---

## 3. iOS Release (requires macOS + Xcode)

### 3.1 Prerequisites

- Apple Developer account with **App Store Connect** access
- Certificates: **Distribution** certificate in Keychain
- Provisioning profiles for each bundle ID

### 3.2 Create App IDs in Apple Developer portal

| Bundle ID | App Name |
|-----------|----------|
| `com.quantix.customer` | Quantix Customer |
| `com.quantix.delivery` | Quantix Delivery |
| `com.quantix.admin` | Quantix Admin |

Enable capabilities: **Push Notifications**, **Background Modes** (Remote notifications)

### 3.3 Build for App Store

```bash
cd customer_app
flutter build ipa --release --dart-define=FLAVOR=quantix \
  --export-options-plist=ios/ExportOptions.plist
```

Create `ios/ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
```

Upload the `.ipa` via Xcode Organizer or `xcrun altool`.

---

## 4. CI/CD — GitHub Actions Secrets

Configure these secrets in **Settings → Secrets → Actions**:

| Secret | Description |
|--------|-------------|
| `KEYSTORE_BASE64` | `base64 -i quantix-release.jks` |
| `KEY_ALIAS` | Keystore alias (e.g. `quantix`) |
| `KEY_PASSWORD` | Key password |
| `STORE_PASSWORD` | Keystore password |
| `CUSTOMER_FIREBASE_OPTIONS` | Contents of customer `firebase_options.dart` |
| `DELIVERY_FIREBASE_OPTIONS` | Contents of delivery `firebase_options.dart` |
| `ADMIN_FIREBASE_OPTIONS` | Contents of admin `firebase_options.dart` |

### Encode keystore for GitHub Secret

```bash
base64 -i quantix-release.jks | pbcopy   # copies to clipboard (macOS)
```

---

## 5. Play Store Release

1. Create three apps in Google Play Console:
   - **Quantix Customer** — `com.quantix.customer`
   - **Quantix Delivery** — `com.quantix.delivery`
   - **Quantix Admin** — `com.quantix.admin`

2. Complete store listings (screenshots, descriptions, content rating)

3. Upload the `.aab` from CI artifacts to **Internal Testing** track first

4. After validation, promote to **Production**

### Version bumping

Update `version` in each `pubspec.yaml`:
```yaml
version: 1.0.0+1   # format: semver+buildNumber
```

---

## 6. Push Notification Server Keys

After Firebase setup, retrieve the **Server Key** (FCM v1 uses service account):

1. Firebase Console → Project Settings → Cloud Messaging
2. Generate a new service account key (JSON)
3. Pass the key to Quantix Core API (`/api/admin/firebase-credentials`)

---

## 7. Post-Deploy Checklist

- [ ] Firebase Crashlytics dashboard shows app version
- [ ] Test push notification from Firebase Console → Cloud Messaging
- [ ] Verify OTP login flow end-to-end
- [ ] Place a test order → confirm status notifications arrive
- [ ] Delivery rider receives assignment notification
- [ ] Admin receives new order + low stock alerts
- [ ] Crashlytics test crash resolves in dashboard within 5 minutes
- [ ] Analytics events visible in Firebase DebugView
