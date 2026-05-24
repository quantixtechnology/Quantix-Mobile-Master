# Quantix Mobile Master

Single Flutter codebase. Multiple white-label apps.  
Each business gets its own branded output — distinct app name, icon, colors, and feature set — built from this repository.

---

## Project Overview

Quantix Mobile Master is a white-label Flutter app platform for the Quantix commerce ecosystem.  
One repository produces production-ready apps for any business registered in the `branding/` folder.

| Flavor | Business | Package ID |
|---|---|---|
| `arbaz` | Arbaz Fresh Meat | `com.arbazfreshmeat.app` |
| `freshmart` | Fresh Mart | `com.freshmart.app` |
| `salon` | Salon App | `com.salon.quantix.app` |
| `restaurant` | Restaurant App | `com.restaurant.quantix.app` |

---

## Architecture

```
lib/
├── core/
│   ├── api/            Dio HTTP client with auth interceptor
│   ├── branding/       White-label engine (BrandConfig, ThemeFactory, FeatureFlags)
│   ├── config/         AppConfig (base URL, timeouts)
│   ├── constants/      App-wide constants
│   ├── exceptions/     AppException hierarchy
│   ├── router/         GoRouter with all named routes
│   ├── sockets/        Socket.IO service (tracking events)
│   ├── storage/        Flutter Secure Storage wrapper
│   ├── theme/          AppTheme (static fallback)
│   └── widgets/        AppScaffold, FeatureGuard
│
└── features/
    ├── auth/           auth_provider + login / otp / register screens
    ├── cart/           cart_provider + cart screen
    ├── catalog/        catalog_provider + categories / products / search / detail
    ├── checkout/       checkout screen
    ├── home/           dashboard screen
    ├── maps/           maps screen
    ├── notifications/  notification_provider + notifications screen
    ├── orders/         order_provider + history / detail / tracking
    └── profile/        customer_provider + account / addresses / loyalty / settings
```

**Stack:**

| Layer | Package |
|---|---|
| State | flutter_riverpod 2.6.x |
| Navigation | go_router 17.x |
| HTTP | dio 5.x |
| Models | freezed + json_serializable |
| Storage | flutter_secure_storage + hive_flutter |
| Real-time | socket_io_client |
| Push | firebase_messaging |
| Maps | google_maps_flutter |
| Images | cached_network_image |

---

## Branding System

Each brand lives in `branding/{flavor}/`:

```
branding/
├── arbaz/
│   ├── config.json   ← app name, colors, features, currency
│   ├── logo.png      ← AppBar / splash logo  (512×512 recommended)
│   └── splash.png    ← Launch screen image   (1242×2688 recommended)
├── freshmart/
├── salon/
└── restaurant/
```

**config.json schema:**

```json
{
  "appName": "Arbaz Fresh Meat",
  "businessId": "ARB001",
  "packageName": "com.arbazfreshmeat.app",
  "businessType": "meat",
  "primaryColor": "#1E7A35",
  "secondaryColor": "#FFFFFF",
  "accentColor": "#D32F2F",
  "currency": "INR",
  "supportPhone": "+91-9876543210",
  "mapEnabled": true,
  "notificationsEnabled": true,
  "features": ["catalog", "cart", "orders", "tracking", "loyalty", "delivery"]
}
```

**businessType values:** `meat` · `grocery` · `salon` · `restaurant` · `generic`

**Feature flags:** `catalog` · `cart` · `orders` · `tracking` · `maps` · `loyalty`  
· `appointments` · `subscriptions` · `delivery` · `notifications`

Use `FeatureGuard` to auto-hide any widget for brands that do not include a feature:

```dart
FeatureGuard(
  feature: 'loyalty',
  child: LoyaltyBanner(),
)
```

---

## Customer Template

The current `lib/` is the **Customer App** template — the storefront that end-customers use.

Screens: Login → OTP → Home → Catalog → Product Detail → Cart → Checkout  
→ Orders → Live Tracking → Profile → Addresses → Notifications

Key providers:

| Provider | Purpose |
|---|---|
| `authProvider` | Auth state (isAuthenticated, userId) |
| `customerProvider` | Customer profile |
| `catalogProvider` | Categories + products |
| `cartProvider` | Cart items + totals |
| `orderProvider` | Order history |
| `trackingProvider` | Real-time driver location + ETA |
| `notificationProvider` | Push + in-app notifications |

Socket events wired:
- `delivery:location_updated`
- `tracking:eta_updated`
- `order:status_changed`
- `notification:new`

---

## Delivery Template

> **Status: Planned**

Separate app for delivery riders.

Planned features:
- Order assignment queue
- Navigation to pickup / drop-off
- Status updates (picked up, en-route, delivered)
- Live location broadcast → `delivery:location_updated`
- Earnings dashboard

---

## Admin Template

> **Status: Planned**

Internal operations dashboard.

Planned features:
- Order management and dispatch
- Rider tracking map
- Inventory / catalog control
- Customer lookup
- Promotion and banner management
- Analytics

---

## Build Steps

### Prerequisites

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Run a specific brand (development)

```bash
flutter run --flavor arbaz      --dart-define=FLAVOR=arbaz
flutter run --flavor freshmart  --dart-define=FLAVOR=freshmart
flutter run --flavor salon      --dart-define=FLAVOR=salon
flutter run --flavor restaurant --dart-define=FLAVOR=restaurant
```

### Release APK

```bash
flutter build apk --flavor arbaz      --dart-define=FLAVOR=arbaz      --release
flutter build apk --flavor freshmart  --dart-define=FLAVOR=freshmart  --release
flutter build apk --flavor salon      --dart-define=FLAVOR=salon      --release
flutter build apk --flavor restaurant --dart-define=FLAVOR=restaurant --release
```

### Play Store App Bundle

```bash
flutter build appbundle --flavor arbaz      --dart-define=FLAVOR=arbaz      --release
flutter build appbundle --flavor freshmart  --dart-define=FLAVOR=freshmart  --release
flutter build appbundle --flavor salon      --dart-define=FLAVOR=salon      --release
flutter build appbundle --flavor restaurant --dart-define=FLAVOR=restaurant --release
```

### Add a new brand

1. Create `branding/{slug}/config.json` and fill in all required fields.
2. Add `logo.png` and `splash.png` to the same folder.
3. Add a `productFlavor` block in `android/app/build.gradle.kts`.
4. Create `android/app/src/{slug}/AndroidManifest.xml`.
5. Add `- branding/{slug}/` to the `assets` list in `pubspec.yaml`.
6. Run `flutter pub get`.

### Analyze

```bash
flutter analyze   # must return: No issues found!
```

---

## Firebase Setup (per brand)

1. Create a Firebase project for the brand.
2. Register the Android app with the flavor `applicationId`.
3. Download `google-services.json` → place at `android/app/src/{flavor}/google-services.json`.
4. Uncomment `Firebase.initializeApp()` in `lib/main.dart`.

> `google-services.json` and `GoogleService-Info.plist` are listed in `.gitignore`. Never commit them.

---

## Backend

OpenAPI contract: `openapi/customer-v1.yaml`  
Base URL: configured in `lib/core/config/app_config.dart`.
