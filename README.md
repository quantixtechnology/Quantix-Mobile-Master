# Quantix Mobile Master

Multi-app white-label Flutter platform. One master repository produces three production apps — Customer storefront, Delivery rider, and Admin dashboard — for any business tenant.

---

## Repository Structure

```
Quantix-Mobile-Master/
├── customer_app/          Flutter storefront (end customers)
├── delivery_app/          Flutter rider app (delivery drivers)
├── admin_app/             Flutter admin dashboard (operations)
├── shared/                Git submodule → Quantix-Mobile-Shared
│   └── lib/               Shared Dart package: branding, API, sockets, storage, widgets
├── scripts/
│   └── create_business.sh Scaffold a new tenant repo in one command
├── docs/
│   └── TENANT_CREATION.md End-to-end tenant onboarding guide
├── branding/
│   ├── quantix/           Master template brand (used by this repo's CI)
│   └── templates/         Documented schema for new tenants
└── .github/workflows/
    └── dart.yml           CI: analyze + APK + AAB for customer_app
```

---

## Architecture

```
Quantix-Mobile-Shared  (GitHub: quantixtechnology/Quantix-Mobile-Shared)
        │  git submodule (pinned commit)
        ▼
shared/                ← branding engine, API client, socket service, storage, widgets
        │  path: ../shared
        ├── customer_app/  com.{slug}.customer
        ├── delivery_app/  com.{slug}.delivery
        └── admin_app/     com.{slug}.admin
```

Each app reads its brand at runtime from `branding/{flavor}/config.json` via `BrandLoader`. The active flavor is set through `--dart-define=FLAVOR={slug}`.

---

## Branding System

Every tenant has a branded folder in each app:

```
customer_app/branding/
├── quantix/          ← master template
│   ├── config.json
│   ├── logo.png      (512×512 recommended)
│   └── splash.png    (1242×2688 recommended)
└── {slug}/           ← created by create_business.sh
```

**config.json schema:**

```json
{
  "appName":               "Display name shown in the app",
  "businessId":            "Unique tenant ID (e.g. QTX001)",
  "packageName":           "com.{slug}.customer",
  "businessType":          "grocery | meat | salon | restaurant | generic",
  "primaryColor":          "#RRGGBB",
  "secondaryColor":        "#RRGGBB",
  "accentColor":           "#RRGGBB",
  "currency":              "PKR | INR | USD | ...",
  "supportPhone":          "+00-000-0000000",
  "mapEnabled":            true,
  "notificationsEnabled":  true,
  "features": ["catalog", "cart", "orders", "tracking", "loyalty", "delivery", "subscriptions"]
}
```

**Available feature flags:** `catalog` · `cart` · `orders` · `tracking` · `maps` · `loyalty` · `appointments` · `subscriptions` · `delivery` · `notifications`

Use `FeatureGuard` to conditionally render widgets:

```dart
FeatureGuard(
  feature: 'loyalty',
  child: LoyaltyBanner(),
)
```

---

## Shared Package (`shared/`)

The `shared/` directory is a git submodule pointing to [Quantix-Mobile-Shared](https://github.com/quantixtechnology/Quantix-Mobile-Shared.git).

Key exports:

| Module | Purpose |
|---|---|
| `BrandLoader` | Loads `config.json` at startup |
| `BrandConfig` | Freezed model — all tenant config fields |
| `ThemeFactory` | Generates light/dark MaterialTheme from BrandConfig |
| `FeatureFlags` | Checks which features are enabled for the tenant |
| `ApiClient` | Dio HTTP client with auth interceptor |
| `SocketService` | Socket.IO wrapper for real-time events |
| `AppScaffold` | Branded scaffold widget |

To update shared to latest:

```bash
./scripts/update_shared.sh
```

---

## Build

### Prerequisites

```bash
git clone --recurse-submodules https://github.com/quantixtechnology/Quantix-Mobile-Master.git
cd Quantix-Mobile-Master
flutter pub get --directory=shared
flutter pub get --directory=customer_app
flutter pub get --directory=delivery_app
flutter pub get --directory=admin_app
```

### Development

```bash
cd customer_app && flutter run --dart-define=FLAVOR=quantix
cd delivery_app && flutter run --dart-define=FLAVOR=quantix
cd admin_app    && flutter run --dart-define=FLAVOR=quantix
```

### Release APK

```bash
cd customer_app && flutter build apk --release --dart-define=FLAVOR=quantix
cd delivery_app && flutter build apk --release --dart-define=FLAVOR=quantix
cd admin_app    && flutter build apk --release --dart-define=FLAVOR=quantix
```

### Analyze

```bash
cd customer_app && flutter analyze --no-pub   # must return: No issues found!
cd delivery_app && flutter analyze --no-pub
cd admin_app    && flutter analyze --no-pub
```

---

## Creating a New Tenant

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

See [docs/TENANT_CREATION.md](docs/TENANT_CREATION.md) for the full onboarding guide.

---

## CI / CD

GitHub Actions runs on every push to `main`:

| Job | Description |
|---|---|
| `analyze` | `flutter pub get` + `flutter analyze` for all three apps |
| `build-customer-apk` | Release APK — `customer_app` |
| `build-customer-aab` | Release AAB — `customer_app` |

Artifacts are uploaded and downloadable from each workflow run.

---

## Firebase (per tenant)

1. Create a Firebase project for the tenant.
2. Register the Android app with the tenant `applicationId` (`com.{slug}.customer`).
3. Download `google-services.json` → place at `customer_app/android/app/google-services.json`.
4. Uncomment `Firebase.initializeApp()` in `customer_app/lib/main.dart`.

> `google-services.json` and `GoogleService-Info.plist` are listed in `.gitignore`. Never commit them.

---

## Stack

| Layer | Package | Version |
|---|---|---|
| State | flutter_riverpod | 2.6.x |
| Navigation | go_router | 17.x |
| HTTP | dio | 5.x |
| Models | freezed + json_serializable | 2.x |
| Storage | flutter_secure_storage + hive_flutter | — |
| Real-time | socket_io_client | 2.x |
