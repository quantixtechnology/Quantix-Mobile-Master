# admin_app/custom/

Business-specific code for the admin operations dashboard.

This directory is **never overwritten** by shared updates.

---

## Purpose

Override or extend anything from `package:quantix_shared`:

| Subfolder | Use for |
|---|---|
| `widgets/` | Custom dashboard widgets, data tables |
| `screens/` | Business-specific admin screens |
| `providers/` | Extended admin state and business rules |
| `reports/` | Custom analytics and report formats |

---

## Override Pattern

```dart
import '../custom/widgets/revenue_chart.dart';
```

---

## What belongs here

- Business-specific KPI displays
- Custom inventory workflows
- Role-based access rules specific to this business
- Anything that differs from the generic admin template
