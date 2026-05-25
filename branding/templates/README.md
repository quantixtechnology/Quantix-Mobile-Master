# Branding Templates

This directory contains reference templates for creating new tenant brands.

## Files

| File | Purpose |
|---|---|
| `config.json` | Schema reference — copy to `branding/{slug}/` and fill in |

## Required assets per tenant (per app)

| File | Size | Purpose |
|---|---|---|
| `logo.png` | 512×512 px | AppBar logo, splash screen brand mark |
| `splash.png` | 1242×2688 px | Launch screen background |

## businessType values

| Value | Use case |
|---|---|
| `grocery` | Supermarket / convenience |
| `meat` | Butcher / specialty meat |
| `salon` | Hair & beauty services |
| `restaurant` | Food & dining |
| `generic` | Any other business |

## Feature flags

Enable or disable features per tenant in `config.json`:

| Flag | Description |
|---|---|
| `catalog` | Product browsing and search |
| `cart` | Shopping cart |
| `orders` | Order history and detail |
| `tracking` | Real-time delivery tracking |
| `maps` | Maps integration |
| `loyalty` | Points and rewards |
| `appointments` | Booking / scheduling |
| `subscriptions` | Recurring orders |
| `delivery` | Delivery management |
| `notifications` | Push + in-app notifications |

## Quick start

```bash
# Option A — automated (recommended)
./scripts/create_business.sh {slug} \
  --app-name "Business Name" \
  --package-base com.{slug} \
  --shared-repo https://github.com/quantixtechnology/Quantix-Mobile-Shared.git \
  --type grocery \
  --primary-color "#1A73E8" \
  --currency PKR \
  --yes

# Option B — manual
mkdir -p customer_app/branding/{slug}
cp branding/templates/config.json customer_app/branding/{slug}/config.json
# Edit config.json, add logo.png and splash.png
# Update customer_app/pubspec.yaml assets to include branding/{slug}/
```
