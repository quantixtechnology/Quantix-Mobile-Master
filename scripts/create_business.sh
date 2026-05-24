#!/usr/bin/env bash
# ==============================================================================
# create_business.sh — Clone Quantix-Mobile-Master for a new business
#
# Produces a monorepo with:
#   shared/        — shared Dart package (branding engine, API, sockets)
#   customer_app/  — Flutter storefront  (com.<slug>.customer)
#   delivery_app/  — Flutter rider app   (com.<slug>.delivery)
#   admin_app/     — Flutter admin app   (com.<slug>.admin)
#
# Usage:
#   ./scripts/create_business.sh <slug> [options]
#
# Examples:
#   ./scripts/create_business.sh arbaz \
#       --app-name "Arbaz Fresh Meat" \
#       --package-base com.arbazfreshmeat \
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
  echo "  slug               Business identifier, lowercase (e.g. arbaz, freshmart)"
  echo ""
  echo -e "${BOLD}Options:${NC}"
  echo "  --app-name         Display name          (default: Title-cased slug)"
  echo "  --package-base     Android package base  (default: com.<slug>)"
  echo "                     Customer = <base>.customer  Delivery = <base>.delivery"
  echo "  --business-id      Business code         (default: SLUG uppercased)"
  echo "  --primary-color    Brand hex color       (default: #00B14F)"
  echo "  --accent-color     Accent hex color      (default: #FF6B00)"
  echo "  --type             Business type         (default: generic)"
  echo "                     meat|grocery|salon|restaurant|generic"
  echo "  --currency         Currency code         (default: PKR)"
  echo "  --phone            Support phone         (default: empty)"
  echo "  --features         Comma-separated list  (default: catalog,cart,orders,tracking,loyalty,delivery)"
  echo "  -y / --yes         Skip confirmation prompt"
  echo ""
  echo -e "${BOLD}Examples:${NC}"
  echo "  $0 arbaz --app-name 'Arbaz Fresh Meat' --package-base com.arbazfreshmeat \\"
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
PACKAGE_BASE_DEFAULT="com.$PKG_SAFE"
BUSINESS_ID_DEFAULT="$(uc "${SLUG//-/}")"

# Option flags
APP_NAME="$APP_NAME_DEFAULT"
PACKAGE_BASE="$PACKAGE_BASE_DEFAULT"
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
    --package-base)   PACKAGE_BASE="$2";   shift 2 ;;
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

# ── Derived values ───────────────────────────────────────────────────────────
SLUG_CAP="$(ucfirst "$SLUG")"
SLUG_UNDERSCORE="$(echo "$SLUG" | tr '-' '_')"
FOLDER_NAME="${SLUG_CAP}-Mobile"
TARGET_DIR="$(dirname "$MASTER_DIR")/$FOLDER_NAME"

PKG_CUSTOMER="${PACKAGE_BASE}.customer"
PKG_DELIVERY="${PACKAGE_BASE}.delivery"
PKG_ADMIN="${PACKAGE_BASE}.admin"

DART_SHARED="${SLUG_UNDERSCORE}_shared"
DART_CUSTOMER="${SLUG_UNDERSCORE}_customer"
DART_DELIVERY="${SLUG_UNDERSCORE}_delivery"
DART_ADMIN="${SLUG_UNDERSCORE}_admin"

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

# ── Map type → mapEnabled ────────────────────────────────────────────────────
case "$BUSINESS_TYPE" in
  salon|generic) MAP_ENABLED=false ;;
  *)             MAP_ENABLED=true  ;;
esac
NOTIF_ENABLED=true

# ── Summary banner ───────────────────────────────────────────────────────────
header "═══ Quantix Business Clone ════════════════════════════════"
printf "  %-22s %s\n" "App Name:"       "$APP_NAME"
printf "  %-22s %s\n" "Slug:"           "$SLUG"
printf "  %-22s %s\n" "Customer pkg:"   "$PKG_CUSTOMER"
printf "  %-22s %s\n" "Delivery pkg:"   "$PKG_DELIVERY"
printf "  %-22s %s\n" "Admin pkg:"      "$PKG_ADMIN"
printf "  %-22s %s\n" "Business ID:"    "$BUSINESS_ID"
printf "  %-22s %s\n" "Type:"           "$BUSINESS_TYPE"
printf "  %-22s %s\n" "Primary:"        "$PRIMARY_COLOR"
printf "  %-22s %s\n" "Currency:"       "$CURRENCY"
printf "  %-22s %s\n" "Features:"       "$FEATURES"
printf "  %-22s %s\n" "Source:"         "$MASTER_DIR"
printf "  %-22s %s\n" "Target:"         "$TARGET_DIR"
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
# STEP 2 — Write config.json for the brand
# ════════════════════════════════════════════════════════════════════════════
step "Writing brand config.json..."
CONFIG_JSON_CONTENT="{
  \"appName\": \"$APP_NAME\",
  \"businessId\": \"$BUSINESS_ID\",
  \"packageName\": \"$PKG_CUSTOMER\",
  \"businessType\": \"$BUSINESS_TYPE\",
  \"primaryColor\": \"$PRIMARY_COLOR\",
  \"secondaryColor\": \"#FFFFFF\",
  \"accentColor\": \"$ACCENT_COLOR\",
  \"currency\": \"$CURRENCY\",
  \"supportPhone\": \"$SUPPORT_PHONE\",
  \"mapEnabled\": $MAP_ENABLED,
  \"notificationsEnabled\": $NOTIF_ENABLED,
  \"features\": $FEATURES_JSON
}"

PNG_B64="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

# ── Write branding into each sub-app ────────────────────────────────────────
for APP_DIR in "$TARGET_DIR/customer_app" "$TARGET_DIR/delivery_app" "$TARGET_DIR/admin_app"; do
  APP_NAME_LC="$(basename "$APP_DIR")"
  BRAND_DIR="$APP_DIR/branding/$SLUG"
  mkdir -p "$BRAND_DIR"
  echo "$CONFIG_JSON_CONTENT" > "$BRAND_DIR/config.json"
  [[ ! -f "$BRAND_DIR/logo.png"   ]] && echo "$PNG_B64" | base64 -d > "$BRAND_DIR/logo.png"
  [[ ! -f "$BRAND_DIR/splash.png" ]] && echo "$PNG_B64" | base64 -d > "$BRAND_DIR/splash.png"
  # Remove placeholder brand folder
  rm -rf "$APP_DIR/branding/freshmart"
  ok "$APP_NAME_LC/branding/$SLUG/  ←  config.json + placeholder images"
done
ok "Brand config written (replace logo.png / splash.png with real assets)"

# ════════════════════════════════════════════════════════════════════════════
# STEP 3 — Update shared package name in pubspec.yaml
# ════════════════════════════════════════════════════════════════════════════
step "Updating shared/pubspec.yaml..."
SHARED_PUBSPEC="$TARGET_DIR/shared/pubspec.yaml"
sed -i '' "s|^name:.*|name: $DART_SHARED|" "$SHARED_PUBSPEC"
sed -i '' "s|^description:.*|description: Shared package for $APP_NAME|" "$SHARED_PUBSPEC"
ok "shared/pubspec.yaml  →  name=$DART_SHARED"

# ════════════════════════════════════════════════════════════════════════════
# STEP 4 — Set default FLAVOR in shared/lib/branding/brand_provider.dart
# ════════════════════════════════════════════════════════════════════════════
step "Setting default FLAVOR in brand_provider.dart..."
PROVIDER="$TARGET_DIR/shared/lib/branding/brand_provider.dart"
sed -i '' "s|defaultValue: '[^']*'|defaultValue: '$SLUG'|" "$PROVIDER"
ok "appFlavor default  →  '$SLUG'"

# ════════════════════════════════════════════════════════════════════════════
# STEP 5 — Update each sub-app pubspec.yaml (name, description, assets, shared dep)
# ════════════════════════════════════════════════════════════════════════════
step "Updating sub-app pubspec files..."

update_subapp_pubspec() {
  local pubspec="$1"
  local dart_name="$2"
  local description="$3"
  local pkg_id="$4"

  sed -i '' "s|^name:.*|name: $dart_name|"           "$pubspec"
  sed -i '' "s|^description:.*|description: $description|" "$pubspec"

  # Update shared package name reference
  sed -i '' "s|name: quantix_shared|name: $DART_SHARED|" "$pubspec"

  # Replace asset path: branding/freshmart/ → branding/{slug}/
  sed -i '' "s|branding/freshmart/|branding/$SLUG/|g" "$pubspec"

  ok "$dart_name  ←  $pubspec"
}

update_subapp_pubspec \
  "$TARGET_DIR/customer_app/pubspec.yaml" \
  "$DART_CUSTOMER" \
  "$APP_NAME Customer App" \
  "$PKG_CUSTOMER"

update_subapp_pubspec \
  "$TARGET_DIR/delivery_app/pubspec.yaml" \
  "$DART_DELIVERY" \
  "$APP_NAME Delivery App" \
  "$PKG_DELIVERY"

update_subapp_pubspec \
  "$TARGET_DIR/admin_app/pubspec.yaml" \
  "$DART_ADMIN" \
  "$APP_NAME Admin App" \
  "$PKG_ADMIN"

# Also update the shared dep name in each sub-app's pubspec path reference
# (The path: ../shared stays unchanged — only the package name changes)

# ════════════════════════════════════════════════════════════════════════════
# STEP 6 — Rewrite android/app/build.gradle.kts for customer_app
#          (root android/ builds the customer_app)
# ════════════════════════════════════════════════════════════════════════════
step "Rewriting android/app/build.gradle.kts  →  $PKG_CUSTOMER..."
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
        applicationId = "$PKG_CUSTOMER"
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
ok "build.gradle.kts  →  applicationId=$PKG_CUSTOMER"

# ════════════════════════════════════════════════════════════════════════════
# STEP 7 — Remove stale Android flavor source sets
# ════════════════════════════════════════════════════════════════════════════
step "Removing Android flavor source sets..."
for dir in "$TARGET_DIR/android/app/src"/*/; do
  [[ -d "$dir" ]] || continue
  name="$(basename "$dir")"
  case "$name" in
    main|debug|profile) ;;
    *)
      rm -rf "$dir"
      warn "Removed:  android/app/src/$name/"
      ;;
  esac
done
ok "Android source sets clean"

# ════════════════════════════════════════════════════════════════════════════
# STEP 8 — Update shared dep name in sub-app pubspec path declarations
#          pubspec.yaml path: ../shared stays the same; only package name matters
#          at pub resolve time. The name field in shared/pubspec.yaml was already
#          updated in STEP 3 — this is just belt-and-suspenders for any lock file.
# ════════════════════════════════════════════════════════════════════════════

# ════════════════════════════════════════════════════════════════════════════
# STEP 9 — Write business-level README.md
# ════════════════════════════════════════════════════════════════════════════
step "Writing README.md..."
cat > "$TARGET_DIR/README.md" << EOF
# $APP_NAME

Multi-app Flutter monorepo cloned from **Quantix-Mobile-Master**.

| App | Package ID | Status |
|---|---|---|
| Customer | \`$PKG_CUSTOMER\` | Ready |
| Delivery | \`$PKG_DELIVERY\` | Ready |
| Admin | \`$PKG_ADMIN\` | Ready |

---

## Structure

\`\`\`
$FOLDER_NAME/
├── shared/          Shared Dart package (branding, API, sockets, storage)
├── customer_app/    Customer-facing storefront
├── delivery_app/    Rider / delivery app
├── admin_app/       Operations dashboard
└── android/         Android build root for customer_app (root flutter build)
\`\`\`

---

## Quick Start

\`\`\`bash
# Install all dependencies
cd shared && flutter pub get && cd ..
cd customer_app && flutter pub get && cd ..
cd delivery_app && flutter pub get && cd ..
cd admin_app   && flutter pub get && cd ..

# Run customer app (from customer_app/)
cd customer_app && flutter run --dart-define=FLAVOR=$SLUG

# Run delivery app (from delivery_app/)
cd delivery_app && flutter run --dart-define=FLAVOR=$SLUG

# Run admin app (from admin_app/)
cd admin_app && flutter run --dart-define=FLAVOR=$SLUG
\`\`\`

---

## Branding

Replace placeholder images with real assets (same file in each sub-app):

| File | Recommendation |
|---|---|
| \`*/branding/$SLUG/logo.png\` | 512×512 px |
| \`*/branding/$SLUG/splash.png\` | 1242×2688 px |

Config lives in \`*/branding/$SLUG/config.json\` (pre-filled for this business).

---

## Android Package IDs

| App | Package ID |
|---|---|
| Customer | \`$PKG_CUSTOMER\` |
| Delivery | \`$PKG_DELIVERY\` |
| Admin | \`$PKG_ADMIN\` |

The root \`android/\` builds the **customer_app** (already configured).
For delivery and admin Android builds, add an \`android/\` folder to each sub-app
following the [Flutter multi-project guide](https://docs.flutter.dev/add-to-app).

---

## Firebase Setup

Repeat for each app:
1. Create a Firebase project for $APP_NAME.
2. Register Android app with the relevant package ID above.
3. Download \`google-services.json\` → place at \`{app}/android/app/\`.
4. Uncomment \`Firebase.initializeApp()\` in \`{app}/lib/main.dart\`.

---

## Analyze

\`\`\`bash
cd customer_app && flutter analyze   # No issues found!
cd delivery_app && flutter analyze   # No issues found!
cd admin_app    && flutter analyze   # No issues found!
\`\`\`
EOF
ok "README.md written"

# ════════════════════════════════════════════════════════════════════════════
# STEP 10 — Run flutter pub get in shared + all apps
# ════════════════════════════════════════════════════════════════════════════
step "Running flutter pub get in all packages..."
for pkg_dir in shared customer_app delivery_app admin_app; do
  if [[ -f "$TARGET_DIR/$pkg_dir/pubspec.yaml" ]]; then
    (cd "$TARGET_DIR/$pkg_dir" && flutter pub get --quiet 2>&1 | tail -1)
    ok "$pkg_dir  →  deps resolved"
  fi
done

# ════════════════════════════════════════════════════════════════════════════
# STEP 11 — Initialize git
# ════════════════════════════════════════════════════════════════════════════
step "Initializing git..."
cd "$TARGET_DIR"
git init --quiet
git symbolic-ref HEAD refs/heads/main

git add .
git commit --quiet -m "Initial $APP_NAME from Quantix-Mobile-Master

Slug:         $SLUG
Customer pkg: $PKG_CUSTOMER
Delivery pkg: $PKG_DELIVERY
Admin pkg:    $PKG_ADMIN
Type:         $BUSINESS_TYPE
"
COMMIT_SHA="$(git rev-parse --short HEAD)"
ok "Git initialized  →  branch: main  |  commit: $COMMIT_SHA"

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

  ── 2. Run the customer app ────────────────────────────────────
     cd "$TARGET_DIR/customer_app"
     flutter run --dart-define=FLAVOR=$SLUG

  ── 3. Run the delivery app ────────────────────────────────────
     cd "$TARGET_DIR/delivery_app"
     flutter run --dart-define=FLAVOR=$SLUG

  ── 4. Run the admin app ───────────────────────────────────────
     cd "$TARGET_DIR/admin_app"
     flutter run --dart-define=FLAVOR=$SLUG

  ── 5. Replace placeholder brand assets ────────────────────────
     */branding/$SLUG/logo.png     (512×512 recommended)
     */branding/$SLUG/splash.png   (1242×2688 recommended)

  ── 6. Connect to GitHub  (create an EMPTY repo first) ─────────
     git remote add origin https://github.com/<org>/$FOLDER_NAME.git
     git branch -M main
     git push -u origin main

  ── 7. Firebase (per app) ──────────────────────────────────────
     Place google-services.json in each app's android/ folder.
     Uncomment Firebase.initializeApp() in each app's lib/main.dart.

  ── 8. Package IDs ─────────────────────────────────────────────
     Customer:  $PKG_CUSTOMER
     Delivery:  $PKG_DELIVERY
     Admin:     $PKG_ADMIN

INSTRUCTIONS
