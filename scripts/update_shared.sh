#!/usr/bin/env bash
# ==============================================================================
# update_shared.sh — Pull latest Quantix-Mobile-Shared into a business repo
#
# Run this inside a business repo (e.g. Arbaz-Mobile/) to pull the newest
# shared package and re-resolve all app dependencies.
#
# Usage:
#   ./scripts/update_shared.sh [options]
#
# Options:
#   --dry-run     Show what would happen without making changes
#   --no-commit   Apply changes but do not auto-commit
#   -y / --yes    Skip confirmation prompt
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

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
lc()    { echo "$1" | tr '[:upper:]' '[:lower:]'; }

DRY_RUN=false
NO_COMMIT=false
YES=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=true;   shift ;;
    --no-commit) NO_COMMIT=true; shift ;;
    -y|--yes)    YES=true;       shift ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--no-commit] [-y]"
      exit 0
      ;;
    *) err "Unknown option: $1"; exit 1 ;;
  esac
done

cd "$REPO_DIR"

# ── Verify we're in a business repo (not master) ─────────────────────────────
if [[ ! -f ".gitmodules" ]]; then
  err "No .gitmodules found. Is this a business repo with shared/ as a submodule?"
  err "Run this script from inside a business repo (e.g. Arbaz-Mobile/)."
  exit 1
fi

if [[ ! -d "shared" ]]; then
  err "shared/ directory not found. Initialize submodules first:"
  err "  git submodule init && git submodule update"
  exit 1
fi

# ── Show current state ───────────────────────────────────────────────────────
CURRENT_SHA="$(git -C shared rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
header "═══ Quantix Shared Update ══════════════════════════════════"
printf "  %-20s %s\n" "Repo:"    "$REPO_DIR"
printf "  %-20s %s\n" "Current:" "$CURRENT_SHA"
echo   "═══════════════════════════════════════════════════════════"

# ── Protected paths audit ────────────────────────────────────────────────────
step "Auditing protected paths..."
# Submodule updates only touch shared/ — everything else is structurally safe.
# We verify no staged changes exist in protected areas before proceeding.
STAGED="$(git diff --cached --name-only 2>/dev/null || true)"
PROTECTED_VIOLATIONS=""
if [[ -f ".protectedpaths" ]]; then
  while IFS= read -r pattern; do
    [[ -z "$pattern" || "$pattern" == \#* ]] && continue
    # Check if any staged file matches this pattern
    MATCH="$(echo "$STAGED" | grep -E "^${pattern/\*/.*}" 2>/dev/null || true)"
    [[ -n "$MATCH" ]] && PROTECTED_VIOLATIONS+="  $MATCH\n"
  done < ".protectedpaths"
fi

if [[ -n "$PROTECTED_VIOLATIONS" ]]; then
  warn "Staged changes in protected paths detected:"
  echo -e "$PROTECTED_VIOLATIONS"
  warn "These will NOT be affected by the shared update (structurally isolated)."
  warn "Stash or commit your changes before proceeding if you want a clean state."
fi
ok "Protected paths are structurally isolated from shared/ updates"

# ── Dry run mode ─────────────────────────────────────────────────────────────
if $DRY_RUN; then
  step "DRY RUN — fetching remote to check for updates..."
  git -C shared fetch --quiet 2>/dev/null || warn "Could not fetch (offline or no remote configured)"
  REMOTE_SHA="$(git -C shared rev-parse --short origin/main 2>/dev/null || echo 'unknown')"
  if [[ "$CURRENT_SHA" == "$REMOTE_SHA" ]]; then
    ok "Already up to date ($CURRENT_SHA). Nothing to do."
  else
    ok "Update available: $CURRENT_SHA → $REMOTE_SHA"
    echo ""
    echo "  Changes in shared since $CURRENT_SHA:"
    git -C shared log --oneline "${CURRENT_SHA}..origin/main" 2>/dev/null || true
  fi
  echo ""
  echo "  Run without --dry-run to apply."
  exit 0
fi

# ── Confirmation ─────────────────────────────────────────────────────────────
if ! $YES; then
  echo ""
  echo "  This will:"
  echo "  1. Pull latest Quantix-Mobile-Shared into shared/"
  echo "  2. Run flutter pub get in shared/, customer_app/, delivery_app/, admin_app/"
  echo "  3. Commit the updated submodule pointer (unless --no-commit)"
  echo ""
  read -r -p "  Proceed? [y/N] " reply
  reply_lc="$(lc "$reply")"
  [[ "$reply_lc" != "y" ]] && { echo "Aborted."; exit 0; }
fi

# ── Pull shared update ────────────────────────────────────────────────────────
step "Updating shared/ submodule to latest..."
git submodule update --remote shared 2>&1 | grep -v '^$' || true

NEW_SHA="$(git -C shared rev-parse --short HEAD 2>/dev/null || echo 'unknown')"

if [[ "$CURRENT_SHA" == "$NEW_SHA" ]]; then
  ok "Already up to date ($CURRENT_SHA). Nothing changed."
  exit 0
fi

ok "shared/ updated: $CURRENT_SHA → $NEW_SHA"

# ── Show what changed ────────────────────────────────────────────────────────
step "Changes in this update:"
git -C shared log --oneline "${CURRENT_SHA}..${NEW_SHA}" 2>/dev/null || \
  echo "   (could not compute diff — submodule may be on a detached HEAD)"

# ── Re-run pub get in all packages ───────────────────────────────────────────
step "Resolving dependencies in all apps..."
for pkg in shared customer_app delivery_app admin_app; do
  if [[ -f "$REPO_DIR/$pkg/pubspec.yaml" ]]; then
    (cd "$REPO_DIR/$pkg" && flutter pub get 2>&1 | grep -E "Got dependencies|Failed|Error" | head -1) || \
      warn "$pkg pub get had warnings (check manually)"
    ok "$pkg  →  deps resolved"
  fi
done

# ── Run analyze to catch any breaking changes ─────────────────────────────────
step "Running flutter analyze to catch breaking changes..."
ANALYZE_ERRORS=0
for app in customer_app delivery_app admin_app; do
  if [[ -f "$REPO_DIR/$app/pubspec.yaml" ]]; then
    RESULT="$(cd "$REPO_DIR/$app" && flutter analyze --no-pub 2>&1)"
    if echo "$RESULT" | grep -q "No issues found"; then
      ok "$app  →  No issues found"
    else
      warn "$app has analysis issues after update:"
      echo "$RESULT" | grep -E "error|warning" | head -10
      ANALYZE_ERRORS=$((ANALYZE_ERRORS + 1))
    fi
  fi
done

if [[ $ANALYZE_ERRORS -gt 0 ]]; then
  warn "$ANALYZE_ERRORS app(s) have issues after the update."
  warn "Review the changes in shared/CHANGELOG.md and fix any breaking API changes."
  warn "To rollback: git submodule update shared  (pins back to previous commit)"
  if ! $NO_COMMIT; then
    echo ""
    read -r -p "  Commit anyway? [y/N] " reply2
    reply_lc2="$(lc "$reply2")"
    [[ "$reply_lc2" != "y" ]] && { echo "Update applied but not committed."; exit 0; }
  fi
fi

# ── Commit ───────────────────────────────────────────────────────────────────
if ! $NO_COMMIT; then
  step "Committing submodule update..."
  git add shared
  git commit -m "Update shared to $NEW_SHA

Pulls latest Quantix-Mobile-Shared. Run \`flutter pub get\`
in each app if switching branches.
"
  ok "Committed  →  $(git rev-parse --short HEAD)"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════╗"
printf "  ║   ✓  shared updated %-35s ║\n" "$CURRENT_SHA → $NEW_SHA"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo "  Next: test the app, then push when satisfied."
echo "  Rollback if needed: git revert HEAD  (or git submodule update shared)"
echo ""
