# delivery_app/custom/

Business-specific code for the delivery rider app.

This directory is **never overwritten** by shared updates.

---

## Purpose

Override or extend anything from `package:quantix_shared`:

| Subfolder | Use for |
|---|---|
| `widgets/` | Custom widgets specific to this business's rider UX |
| `screens/` | Business-specific rider screens |
| `providers/` | Extended state (e.g. custom earnings tiers) |
| `theme/` | Brand-specific component styles |

---

## Override Pattern

```dart
// Import your custom version instead of the shared one:
import '../custom/widgets/order_card.dart';
```

---

## What belongs here

- Business-specific rider UI (e.g. custom order card, earnings display)
- Extended assignment logic specific to this business
- Anything that differs from the generic delivery template
