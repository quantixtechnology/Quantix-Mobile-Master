#!/usr/bin/env bash
# ==============================================================================
# create_business.sh — Clone Quantix-Mobile-Master for a new business
#
# Usage:
#   ./scripts/create_business.sh <slug> [options]
#
# Examples:
#   ./scripts/create_business.sh arbaz \
#       --app-name "Arbaz Fresh Meat" \
#       --package-id com.arbazfreshmeat.app \
#       --business-id ARB001 \
#       --type meat \
#       --primary-color "#1E7A35" \
#       --currency INR \
#       --phone "+91-9876543210"
#
#   ./scripts/create_business.sh freshmart -y
# ==============================================================================
set -euo pipefail

# ── Directory references ────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Terminal colours ────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

step()  { echo -e "\n${CYAN}▶  $*${NC}"; }
ok()    { echo -e "${GREEN}   ✓  $*${NC}"; }
warn()  { echo -e "${YELLOW}   ⚠  $*${NC}"; }
err()   { echo -e "${RED}   ✗  $*${NC}" >&2; }
header(){ echo -e "\n${BOLD}$*${NC}"; }

# ── Portable string helpers (bash 3.2 safe) ─────────────────────────────────
lc()      { echo "$1" | tr '[:upper:]' '[:lower:]'; }
uc()      { echo "$1" | tr '[:lower:]' '[:upper:]'; }
ucfirst() { echo "$1" | awk '{print toupper(substr($0,1,1)) substr($0,2)}'; }
title_case() {
  echo "$1" | sed 's/-/ /g' | awk '{
    for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))
    print
  }'
}
safe_pkg() { echo "$1" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]'; }

# ── Usage ───────────────────────────────────────────────────────────────────
usage() {
  echo ""
  echo -e "${BOLD}Usage:${NC}"
  echo "  $0 <slug> [options]"
  echo ""
  echo -e "${BOLD}Required:${NC}"
  echo "  slug              Business identifier, lowercase (e.g. arbaz, freshmart)"
  echo ""
  echo -e "${BOLD}Options:${NC}"
  echo "  --app-name        Display name         (default: Title-cased slug)"
  echo "  --package-id      Android package ID   (default: com.<slug>.app)"
  echo "  --business-id     Business code        (default: SLUG uppercased)"
  echo "  --primary-color   Brand hex color      (default: #00B14F)"
  echo "  --accent-color    Accent hex color     (default: #FF6B00)"
  echo "  --type            Business type        (default: generic)"
  echo "                    meat|grocery|salon|restaurant|generic"
  echo "  --currency        Currency code        (default: PKR)"
  echo "  --phone           Support phone        (default: empty)"
  echo "  --features        Comma-separated list (default: catalog,cart,orders)"
  echo "  -y / --yes        Skip confirmation prompt"
  echo ""
  echo -e "${BOLD}Examples:${NC}"
  echo "  $0 arbaz --app-name 'Arbaz Fresh Meat' --package-id com.arbazfreshmeat.app \\"
  echo "      --type meat --primary-color '#1E7A35' --currency INR"
  echo ""
  echo "  $0 salon --type salon --primary-color '#8E24AA' -y"
  echo ""
  exit 1
}

# ── Parse arguments ─────────────────────────────────────────────────────────
[[ $# -lt 1 ]] && usage

RAW_SLUG="$1"
shift

SLUG="$(lc "$RAW_SLUG")"
SLUG="${SLUG// /-}"
SLUG="$(echo "$SLUG" | tr -cd '[:alnum:]-')"

[[ -z "$SLUG" ]] && { err "Invalid slug: '$RAW_SLUG'"; usage; }

# Derive defaults
APP_NAME_DEFAULT="$(title_case "$SLUG")"
PKG_SAFE="$(safe_pkg "$SLUG")"
PACKAGE_ID_DEFAULT="com.${PKG_SAFE}.app"
BUSINESS_ID_DEFAULT="$(uc "${SLUG//-/}")"

# Option flags
APP_NAME="$APP_NAME_DEFAULT"
PACKAGE_ID="$PACKAGE_ID_DEFAULT"
BUSINESS_ID="$BUSINESS_ID_DEFAULT"
PRIMARY_COLOR="#00B14F"
ACCENT_COLOR="#FF6B00"
BUSINESS_TYPE="generic"
CURRENCY="PKR"
SUPPORT_PHONE=""
FEATURES="catalog,cart,orders,tracking,loyalty,delivery"
YES=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name)       APP_NAME="$2";       shift 2 ;;
    --package-id)     PACKAGE_ID="$2";     shift 2 ;;
    --business-id)    BUSINESS_ID="$2";    shift 2 ;;
    --primary-color)  PRIMARY_COLOR="$2";  shift 2 ;;
    --accent-color)   ACCENT_COLOR="$2";   shift 2 ;;
    --type)           BUSINESS_TYPE="$2";  shift 2 ;;
    --currency)       CURRENCY="$2";       shift 2 ;;
    --phone)          SUPPORT_PHONE="$2";  shift 2 ;;
    --features)       FEATURES="$2";       shift 2 ;;
    -y|--yes)         YES=true;            shift   ;;
    -h|--help)        usage ;;
    *) err "Unknown option: $1"; usage ;;
  esac
done

# ── Derived paths ────────────────────────────────────────────────────────────
SLUG_CAP="$(ucfirst "$SLUG")"
FOLDER_NAME="${SLUG_CAP}-Mobile"
TARGET_DIR="$(dirname "$MASTER_DIR")/$FOLDER_NAME"
DART_PKG_NAME="${SLUG//-/_}_mobile"

# ── Convert comma-separated features → JSON array ───────────────────────────
features_json() {
  local result="["
  local first=true
  local IFS=','
  local f
  for f in $1; do
    f="$(echo "$f" | tr -d ' ')"
    [[ -z "$f" ]] && continue
    $first && first=false || result+=", "
    result+="\"$f\""
  done
  result+="]"
  echo "$result"
}
FEATURES_JSON="$(features_json "$FEATURES")"

# ── Map type → mapEnabled / notificationsEnabled defaults ───────────────────
case "$BUSINESS_TYPE" in
  salon|generic) MAP_ENABLED=false ;;
  *)             MAP_ENABLED=true  ;;
esac
NOTIF_ENABLED=true

# ── Summary banner ───────────────────────────────────────────────────────────
header "═══ Quantix Business Clone ════════════════════════════════"
printf "  %-18s %s\n" "App Name:"     "$APP_NAME"
printf "  %-18s %s\n" "Slug:"         "$SLUG"
printf "  %-18s %s\n" "Package ID:"   "$PACKAGE_ID"
printf "  %-18s %s\n" "Business ID:"  "$BUSINESS_ID"
printf "  %-18s %s\n" "Type:"         "$BUSINESS_TYPE"
printf "  %-18s %s\n" "Primary:"      "$PRIMARY_COLOR"
printf "  %-18s %s\n" "Accent:"       "$ACCENT_COLOR"
printf "  %-18s %s\n" "Currency:"     "$CURRENCY"
printf "  %-18s %s\n" "Features:"     "$FEATURES"
printf "  %-18s %s\n" "Source:"       "$MASTER_DIR"
printf "  %-18s %s\n" "Target:"       "$TARGET_DIR"
echo   "═══════════════════════════════════════════════════════════"

# ── Guard: target must not exist ─────────────────────────────────────────────
if [[ -d "$TARGET_DIR" ]]; then
  err "Directory already exists: $TARGET_DIR"
  echo "  Delete it first:  rm -rf \"$TARGET_DIR\""
  exit 1
fi

# ── Confirmation ─────────────────────────────────────────────────────────────
if ! $YES; then
  echo ""
  read -r -p "  Proceed? [y/N] " reply
  reply_lc="$(lc "$reply")"
  [[ "$reply_lc" != "y" ]] && { echo "Aborted."; exit 0; }
fi

# ════════════════════════════════════════════════════════════════════════════
# STEP 1 — Clone master (skip .git, build artefacts, IDE files)
# ════════════════════════════════════════════════════════════════════════════
step "Cloning master repository..."
rsync -a \
  --exclude='.git/' \
  --exclude='build/' \
  --exclude='.dart_tool/' \
  --exclude='.idea/' \
  --exclude='*.iml' \
  "$MASTER_DIR/" "$TARGET_DIR/"
ok "Files cloned  →  $TARGET_DIR"

# ════════════════════════════════════════════════════════════════════════════
# STEP 2 — Remove other brand folders from branding/
# ════════════════════════════════════════════════════════════════════════════
step "Cleaning other brand assets..."
for dir in "$TARGET_DIR/branding"/*/; do
  [[ -d "$dir" ]] || continue
  brand="$(basename "$dir")"
  if [[ "$brand" != "$SLUG" ]]; then
    rm -rf "$dir"
    warn "Removed:  branding/$brand/"
  fi
done
ok "Only branding/$SLUG/ retained"

# ════════════════════════════════════════════════════════════════════════════
# STEP 3 — Write branding/config.json
# ════════════════════════════════════════════════════════════════════════════
step "Writing branding/$SLUG/config.json..."
BRAND_DIR="$TARGET_DIR/branding/$SLUG"
mkdir -p "$BRAND_DIR"

cat > "$BRAND_DIR/config.json" << EOF
{
  "appName": "$APP_NAME",
  "businessId": "$BUSINESS_ID",
  "packageName": "$PACKAGE_ID",
  "businessType": "$BUSINESS_TYPE",
  "primaryColor": "$PRIMARY_COLOR",
  "secondaryColor": "#FFFFFF",
  "accentColor": "$ACCENT_COLOR",
  "currency": "$CURRENCY",
  "supportPhone": "$SUPPORT_PHONE",
  "mapEnabled": $MAP_ENABLED,
  "notificationsEnabled": $NOTIF_ENABLED,
  "features": $FEATURES_JSON
}
EOF
ok "config.json written"

# ════════════════════════════════════════════════════════════════════════════
# STEP 4 — Placeholder logo / splash (1×1 transparent PNG)
# ════════════════════════════════════════════════════════════════════════════
step "Creating placeholder brand images..."
PNG_B64="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
[[ ! -f "$BRAND_DIR/logo.png"   ]] && echo "$PNG_B64" | base64 -d > "$BRAND_DIR/logo.png"
[[ ! -f "$BRAND_DIR/splash.png" ]] && echo "$PNG_B64" | base64 -d > "$BRAND_DIR/splash.png"
ok "branding/$SLUG/logo.png + splash.png ready  (replace with real assets)"

# ════════════════════════════════════════════════════════════════════════════
# STEP 5 — Update pubspec.yaml  (name, description, assets)
# ════════════════════════════════════════════════════════════════════════════
step "Updating pubspec.yaml..."
PUBSPEC="$TARGET_DIR/pubspec.yaml"

sed -i '' "s|^name:.*|name: $DART_PKG_NAME|"                              "$PUBSPEC"
sed -i '' "s|^description:.*|description: $APP_NAME Customer App|"        "$PUBSPEC"

python3 - "$PUBSPEC" "$SLUG" << 'PYEOF'
import sys, re
path, slug = sys.argv[1], sys.argv[2]
with open(path) as f:
    content = f.read()
new_assets = "  assets:\n    - branding/{}/\n".format(slug)
content = re.sub(r'  assets:\n(?:    - branding/[^\n]+\n)+', new_assets, content)
with open(path, 'w') as f:
    f.write(content)
PYEOF

ok "pubspec.yaml  →  name=$DART_PKG_NAME  assets=branding/$SLUG/"

# ════════════════════════════════════════════════════════════════════════════
# STEP 6 — Set default FLAVOR in brand_provider.dart
# ════════════════════════════════════════════════════════════════════════════
step "Setting default FLAVOR in brand_provider.dart..."
PROVIDER="$TARGET_DIR/lib/core/branding/brand_provider.dart"
sed -i '' "s|defaultValue: '[^']*'|defaultValue: '$SLUG'|" "$PROVIDER"
ok "appFlavor default  →  '$SLUG'"

# ════════════════════════════════════════════════════════════════════════════
# STEP 7 — Rewrite android/app/build.gradle.kts  (single brand, no flavors)
# ════════════════════════════════════════════════════════════════════════════
step "Rewriting android/app/build.gradle.kts..."
cat > "$TARGET_DIR/android/app/build.gradle.kts" << EOF
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.quantix_customer_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "$PACKAGE_ID"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appName"] = "$APP_NAME"
    }

    buildTypes {
        release {
            // TODO: replace with production signing config before store upload
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
EOF
ok "build.gradle.kts  →  applicationId=$PACKAGE_ID  (flavors removed)"

# ════════════════════════════════════════════════════════════════════════════
# STEP 8 — Remove stale Android flavor source sets
# ════════════════════════════════════════════════════════════════════════════
step "Removing Android flavor source sets..."
for dir in "$TARGET_DIR/android/app/src"/*/; do
  [[ -d "$dir" ]] || continue
  name="$(basename "$dir")"
  case "$name" in
    main|debug|profile) ;;          # keep Flutter-required source sets
    *)
      rm -rf "$dir"
      warn "Removed:  android/app/src/$name/"
      ;;
  esac
done
ok "Android source sets clean"

# ════════════════════════════════════════════════════════════════════════════
# STEP 9 — Create customer / delivery / admin folders
# ════════════════════════════════════════════════════════════════════════════
step "Creating app-layer folders..."

mkdir -p "$TARGET_DIR/customer"
cat > "$TARGET_DIR/customer/README.md" << EOF
# Customer App — $APP_NAME

The main \`lib/\` directory at the project root is the customer-facing Flutter app.

This folder holds customer-app-specific resources:
- Store listing assets and screenshots
- App Store / Play Store metadata
- Marketing copy

## Screens
Login → OTP → Home → Catalog → Cart → Checkout → Orders → Tracking → Profile
EOF

mkdir -p "$TARGET_DIR/delivery"
cat > "$TARGET_DIR/delivery/README.md" << EOF
# Delivery App — $APP_NAME

**Status: Planned**

Planned features:
- Order assignment queue
- Navigation to pickup and drop-off
- Status updates (picked-up · en-route · delivered)
- Live GPS broadcast  →  socket event \`delivery:location_updated\`
- Earnings dashboard

When implemented this will be a separate Flutter project in this folder.
EOF

mkdir -p "$TARGET_DIR/admin"
cat > "$TARGET_DIR/admin/README.md" << EOF
# Admin Dashboard — $APP_NAME

**Status: Planned**

Planned features:
- Order management and dispatch
- Live rider tracking map
- Inventory / catalog control
- Customer lookup and support
- Promotions and banner management
- Analytics and reports

When implemented this will be a separate Flutter or web project in this folder.
EOF

ok "customer/  delivery/  admin/  created"

# ════════════════════════════════════════════════════════════════════════════
# STEP 10 — Write business-specific README.md
# ════════════════════════════════════════════════════════════════════════════
step "Writing README.md..."
cat > "$TARGET_DIR/README.md" << EOF
# $APP_NAME

Cloned from **Quantix-Mobile-Master**.

| Field | Value |
|---|---|
| App Name | $APP_NAME |
| Slug | \`$SLUG\` |
| Package ID | \`$PACKAGE_ID\` |
| Business ID | \`$BUSINESS_ID\` |
| Type | $BUSINESS_TYPE |
| Currency | $CURRENCY |

---

## Quick Start

\`\`\`bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
\`\`\`

## Customize Branding

| File | Purpose |
|---|---|
| \`branding/$SLUG/config.json\` | Colors, features, currency |
| \`branding/$SLUG/logo.png\` | App bar / splash logo  (512×512 recommended) |
| \`branding/$SLUG/splash.png\` | Launch screen image  (1242×2688 recommended) |

## App Layers

| Folder | Status | Purpose |
|---|---|---|
| \`lib/\` | Active | Customer storefront |
| \`customer/\` | Active | Store listing assets, screenshots |
| \`delivery/\` | Planned | Rider app |
| \`admin/\` | Planned | Operations dashboard |

## Build

\`\`\`bash
# Debug
flutter run

# Release APK
flutter build apk --release

# Play Store Bundle
flutter build appbundle --release
\`\`\`

## Firebase Setup

1. Create a Firebase project for **$APP_NAME**.
2. Register Android app: \`$PACKAGE_ID\`.
3. Download \`google-services.json\` → place at \`android/app/src/main/\`.
4. Uncomment \`Firebase.initializeApp()\` in \`lib/main.dart\`.

---

*Cloned from Quantix-Mobile-Master*
EOF
ok "README.md written"

# ════════════════════════════════════════════════════════════════════════════
# STEP 11 — Initialize git
# ════════════════════════════════════════════════════════════════════════════
step "Initializing git..."
cd "$TARGET_DIR"
git init --quiet
git symbolic-ref HEAD refs/heads/main

git add .
git commit --quiet -m "Initial $APP_NAME from Quantix-Mobile-Master

Slug:        $SLUG
Package ID:  $PACKAGE_ID
Type:        $BUSINESS_TYPE
"
COMMIT_SHA="$(git rev-parse --short HEAD)"
ok "Git initialized  →  branch: main  |  commit: $COMMIT_SHA"

# ════════════════════════════════════════════════════════════════════════════
# STEP 12 — Remove any inherited remote
# ════════════════════════════════════════════════════════════════════════════
git remote remove origin 2>/dev/null && warn "Removed stale 'origin' remote" || true

# ════════════════════════════════════════════════════════════════════════════
# DONE
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════╗"
printf "  ║   ✓  %-51s ║\n" "$APP_NAME created successfully!"
printf "  ║      %-51s ║\n" "$TARGET_DIR"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

cat << INSTRUCTIONS
  ── 1. Open project ────────────────────────────────────────────
     code "$TARGET_DIR"

  ── 2. Install dependencies ────────────────────────────────────
     cd "$TARGET_DIR"
     flutter pub get
     dart run build_runner build --delete-conflicting-outputs

  ── 3. Run the app ─────────────────────────────────────────────
     flutter run

  ── 4. Replace placeholder assets ──────────────────────────────
     branding/$SLUG/logo.png    (512×512 recommended)
     branding/$SLUG/splash.png  (1242×2688 recommended)

  ── 5. Connect to GitHub  (create an EMPTY repo first) ─────────
     git remote add origin https://github.com/<org>/$FOLDER_NAME.git
     git branch -M main
     git push -u origin main

  ── 6. Firebase ────────────────────────────────────────────────
     android/app/src/main/google-services.json
     Uncomment Firebase.initializeApp() in lib/main.dart

  ── 7. Analyze ─────────────────────────────────────────────────
     flutter analyze     # must return: No issues found!

INSTRUCTIONS
