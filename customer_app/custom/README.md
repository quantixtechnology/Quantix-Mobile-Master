# customer_app/custom/

Business-specific code for the customer storefront.

This directory is **never overwritten** by shared updates.

---

## Purpose

Override or extend anything from `package:quantix_shared`:

| Subfolder | Use for |
|---|---|
| `widgets/` | Custom versions of AppScaffold, FeatureGuard, etc. |
| `screens/` | Business-specific screens not in the shared template |
| `providers/` | Business-specific Riverpod providers |
| `theme/` | Brand-specific typography, spacing, component styles |

---

## Override Pattern

To override a shared widget, create your version here and import from `custom/`:

```dart
// Instead of:
import 'package:quantix_shared/quantix_shared.dart';

// Import your custom version:
import '../custom/widgets/app_scaffold.dart';
```

The shared package is the default. `custom/` replaces only what you put in it.

---

## What belongs here

- Business-specific UI components
- Extended screens with business logic
- Loyalty, subscription, or appointment-specific flows
- Anything that differs from the generic shared template

## What does NOT belong here

- Branding colors/images → `branding/{slug}/`
- Shared infrastructure changes → submit a PR to `Quantix-Mobile-Shared`
- Firebase config → `android/app/google-services.json`
