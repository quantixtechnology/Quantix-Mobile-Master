# Quantix Mobile — Production Readiness Report

**Date:** 2026-05-25
**Apps:** Customer v1.0.0 · Delivery v1.0.0 · Admin v1.0.0
**Flutter:** 3.41.x (stable) · Dart 3.11.x

---

## A. Production Blockers

| # | Blocker | Severity | Resolution |
|---|---------|----------|------------|
| 1 | `firebase_options.dart` contains placeholder values | CRITICAL | Run `flutterfire configure` per tenant before building |
| 2 | `google-services.json` / `GoogleService-Info.plist` not present | CRITICAL | Download from Firebase Console, inject in CI via secrets |
| 3 | Android keystore not configured | CRITICAL | Generate keystore, set `key.properties`, inject in CI |
| 4 | App icons use Flutter default | HIGH | Replace `ic_launcher` in each app's `mipmap-*` folders with tenant branding |
| 5 | Splash screen not customised | MEDIUM | Update `launch_background.xml` and iOS `LaunchScreen.storyboard` |
| 6 | FCM server-side topic subscriptions not configured | HIGH | Configure Quantix Core to subscribe riders/admins to topics on login |
| 7 | iOS Provisioning Profiles and Distribution Certificate not set up | HIGH | Required for App Store submission |

---

## B. Security

### Token Storage ✅
- Tokens stored via `flutter_secure_storage` (Android Keystore / iOS Keychain)
- `IOSOptions(accessibility: KeychainAccessibility.first_unlock)` — tokens accessible after first unlock post-boot
- FCM token stored separately; survives logout so device can still receive pre-auth notifications

### Refresh Flow ✅
- 401 auto-retry in `_AuthInterceptor` with a fresh Dio instance (no interceptor loop)
- `_isRefreshing` flag prevents concurrent 401s from stacking multiple refresh calls
- Refresh token rotation: new refresh token is saved on each successful refresh
- On refresh failure: `clearAll()` is called, user is redirected to login

### API Security ✅
- All requests carry `X-Business-ID` header for tenant isolation
- Bearer token injected from secure storage on every request
- Base URL from `AppConfig.baseUrl` (compile-time constant)

### Tenant Isolation ✅
- Every API call scoped by `X-Business-ID`
- `BrandLoader` validates flavor matches a known tenant config
- Demo data mode (`USE_DEMO_DATA=true`) disabled by default in production builds

### Logout Cleanup ✅
- `AuthService.logout()` calls `POST /auth/logout` (server-side token revocation, best-effort)
- `SecureStorage.clearAll()` deletes `auth_token`, `refresh_token`, `user_id`
- `FcmService.clearToken()` deletes the FCM token from device and Firebase

### Remaining Security Actions
| Action | Priority |
|--------|----------|
| Enable Android Network Security Config (restrict cleartext traffic) | HIGH |
| Add certificate pinning for `AppConfig.baseUrl` | MEDIUM |
| Enable App Check (Firebase) to prevent API abuse | MEDIUM |
| Obfuscation: `--obfuscate --split-debug-info=build/debug-info` | HIGH |
| Review Proguard rules cover all model classes | MEDIUM |

---

## C. Notifications

### Architecture
```
Quantix Core API
      ↓  (Firebase Admin SDK)
Firebase Cloud Messaging
      ↓
  ┌───────────────────────────────────┐
  │  FcmService (shared/lib/)         │
  │  ├─ Foreground → LocalNotification│
  │  ├─ Background → background handler│
  │  └─ Tap → NotificationRouter      │
  └───────────────────────────────────┘
```

### Notification Types Implemented

| App | Notification | Route |
|-----|-------------|-------|
| Customer | Order confirmed | `/orders/:id` |
| Customer | Rider assigned | `/tracking/:id` |
| Customer | Order delivered | `/orders/:id` |
| Delivery | New assignment | `/orders/:id` |
| Delivery | Order reassigned | `/orders/:id` |
| Admin | New order received | `/orders` |
| Admin | Low stock alert | `/inventory` |

### Required Quantix Core Setup
The Core API must:
1. Accept `POST /users/fcm-token` to register device tokens
2. Subscribe riders to FCM topic `riders-{tenantId}`
3. Subscribe admins to FCM topic `admins-{tenantId}`
4. Send targeted notifications on order events

### Android Channel
- Channel ID: `quantix_high_importance`
- Importance: HIGH (heads-up notifications)
- Notification permission: `POST_NOTIFICATIONS` declared in manifest (Android 13+)

### iOS
- `NSUserNotificationUsageDescription` added to all `Info.plist` files
- `requestPermission()` called at app launch via `FcmService.init()`

---

## D. Mobile Deployment

### Android ✅
| Item | Status |
|------|--------|
| Gradle Kotlin DSL (build.gradle.kts) | ✅ |
| minSdk 21 (Firebase requirement) | ✅ |
| Google Services plugin | ✅ |
| Firebase Crashlytics plugin | ✅ |
| Signing config (key.properties) | ✅ Template ready, secrets needed |
| ProGuard rules | ✅ |
| R8 minification + resource shrinking | ✅ (release builds) |
| AAB output (Play Store format) | ✅ |
| CI build artifacts | ✅ |

### iOS ✅ (scaffolded)
| Item | Status |
|------|--------|
| `ios/` directories created for all 3 apps | ✅ |
| Bundle IDs set (com.quantix.customer/delivery/admin) | ✅ |
| NSUserNotificationUsageDescription | ✅ |
| Xcode project (Runner.xcodeproj) | ✅ |
| Distribution certificate + provisioning profiles | ⏳ Manual step |
| APN key uploaded to Firebase | ⏳ Manual step |

### Flutter Build Flags (production)
```bash
flutter build appbundle \
  --release \
  --dart-define=FLAVOR=quantix \
  --obfuscate \
  --split-debug-info=build/debug-info
```

---

## E. Store Readiness

### Google Play
| Requirement | Status |
|------------|--------|
| App signed with release keystore | ⏳ Keystore needs creation |
| Target API 34+ | ✅ (flutter.targetSdkVersion) |
| 64-bit support | ✅ (Dart/Flutter default) |
| App Bundle (AAB) | ✅ |
| `INTERNET` permission declared | ✅ |
| `POST_NOTIFICATIONS` permission declared | ✅ |
| Crash-free rate target (>99%) | Crashlytics enabled |

### App Store (iOS)
| Requirement | Status |
|------------|--------|
| iOS 12+ support | ✅ (Flutter default) |
| Push notifications entitlement | ⏳ Manual — add in Apple Dev Portal |
| Background modes (remote notifications) | ⏳ Add in Xcode capabilities |
| Privacy usage strings in Info.plist | ✅ Notifications added |
| Distribution IPA | ⏳ Requires macOS build machine |

---

## F. Analytics Events Coverage

| Event | Customer | Delivery | Admin |
|-------|----------|----------|-------|
| login | ✅ | ✅ | ✅ |
| logout | ✅ | ✅ | ✅ |
| view_product | ✅ | — | — |
| add_to_cart | ✅ | — | — |
| begin_checkout | ✅ | — | — |
| order_placed | ✅ | — | — |
| delivery_accepted | — | ✅ | — |
| delivery_completed | — | ✅ | — |
| inventory_update | — | — | ✅ |
| order_status_changed | — | — | ✅ |

Wire `analyticsServiceProvider` into each feature's Notifier to fire events.

---

## G. Recommended Pre-Launch Actions (Priority Order)

1. **[CRITICAL]** Run `flutterfire configure` and populate Firebase secrets in GitHub
2. **[CRITICAL]** Generate release keystore and add to CI secrets
3. **[CRITICAL]** Replace default app icons with tenant branding
4. **[HIGH]** Enable `--obfuscate` flag in CI build commands
5. **[HIGH]** Configure Quantix Core to send FCM notifications on order events
6. **[HIGH]** Add Network Security Config to restrict HTTP traffic on Android
7. **[HIGH]** Set up Apple Developer account + certificates for iOS
8. **[MEDIUM]** Enable Firebase App Check
9. **[MEDIUM]** Add certificate pinning for production API
10. **[MEDIUM]** Customise splash screens with tenant branding
11. **[LOW]** Add integration tests for critical flows (login, checkout)
