# Update Guide — Quantix Multi-App Ecosystem

## Architecture Overview

```
Quantix-Mobile-Shared  ←  standalone git repo (reusable core)
        │
        ├─ git submodule  →  Quantix-Mobile-Master/shared/
        │
        └─ git submodule  →  Arbaz-Mobile/shared/
                             Salon-Mobile/shared/
                             {Business}-Mobile/shared/
```

Business repos are **not forks**. They share one version of the core library
via a pinned submodule commit. Updates flow in one direction:

```
Quantix-Mobile-Shared  →  (git push)  →  GitHub
        ↓
Business repos  →  (git submodule update --remote)  →  get new version
```

---

## 1. Shared Package Update (as a core developer)

When you fix a bug or add a feature in `Quantix-Mobile-Shared`:

```bash
# Work in Quantix-Mobile-Shared/
cd ~/Projects/Quantix-Mobile-Shared

# Make your change, then:
git add .
git commit -m "fix: typo in BrandLoader fallback"
git push origin main

# Update the version in CHANGELOG.md (best practice)
```

Then update the master pointer so new clones get the latest:

```bash
cd ~/Projects/quantix_customer_app   # master repo

git submodule update --remote shared
git add shared
git commit -m "Update shared to latest"
git push
```

---

## 2. Business Repo Update (as a business owner)

### Automatic (recommended)

```bash
cd Arbaz-Mobile/
./scripts/update_shared.sh
```

The script:
1. Pulls the latest `shared/` from `Quantix-Mobile-Shared`
2. Runs `flutter pub get` in all packages
3. Runs `flutter analyze` and reports any breaking changes
4. Commits the updated submodule pointer

### Manual (step by step)

```bash
cd Arbaz-Mobile/

# 1. Pull latest shared
git submodule update --remote shared

# 2. Check what changed
git -C shared log --oneline ORIG_HEAD..HEAD

# 3. Re-resolve dependencies
cd shared       && flutter pub get; cd ..
cd customer_app && flutter pub get; cd ..
cd delivery_app && flutter pub get; cd ..
cd admin_app    && flutter pub get; cd ..

# 4. Verify no breaking changes
cd customer_app && flutter analyze --no-pub
cd delivery_app && flutter analyze --no-pub
cd admin_app    && flutter analyze --no-pub

# 5. Commit
git add shared
git commit -m "Update shared to $(git -C shared rev-parse --short HEAD)"
```

---

## 3. Emergency Rollback

If a shared update breaks your app, roll back to the previous pinned commit:

```bash
cd Arbaz-Mobile/

# Option A — revert the update commit
git revert HEAD

# Option B — pin shared/ to a specific commit
git -C shared checkout <SAFE_COMMIT_SHA>
git add shared
git commit -m "Pin shared to <SAFE_COMMIT_SHA> (rollback)"
```

To find the safe commit:
```bash
git log --oneline -- shared    # shows when shared pointer changed
git show <COMMIT>:shared       # shows the submodule SHA at that commit
```

---

## 4. Custom Module Updates (business-specific code)

Code in `*/custom/` is yours. It is never touched by shared updates.

```
customer_app/custom/    ← your overrides, never overwritten
delivery_app/custom/    ← your rider UI overrides
admin_app/custom/       ← your admin extensions
```

To extend a shared component:

```dart
// customer_app/custom/widgets/branded_scaffold.dart
import 'package:quantix_shared/quantix_shared.dart';
import 'package:flutter/material.dart';

class BrandedScaffold extends AppScaffold {
  // Your business-specific customization
}
```

Then import from `custom/` in your screens:

```dart
import '../custom/widgets/branded_scaffold.dart';
```

---

## 5. Protected Paths

The following paths are structurally isolated from shared updates.
A `git submodule update` can ONLY modify files inside `shared/` — it
cannot touch any of these:

| Path | Protected from |
|---|---|
| `*/branding/` | Brand colors, config, images |
| `*/custom/` | Business-specific overrides |
| `**/google-services.json` | Firebase credentials |
| `**/.env` | Environment variables |
| `**/*.jks`, `**/*.keystore` | Signing keys |
| `*/pubspec.yaml` (app-level) | Business dependency choices |
| `README.md` | Business documentation |

See `.protectedpaths` for the full list.

---

## 6. Initial Setup for a New Machine

Clone a business repo with its submodule in one command:

```bash
git clone --recurse-submodules https://github.com/quantixtechnology/Arbaz-Mobile.git
```

Or if already cloned without submodules:

```bash
cd Arbaz-Mobile/
git submodule init
git submodule update
```

---

## 7. Connecting Quantix-Mobile-Shared to GitHub

After the Quantix-Mobile-Shared repo is on GitHub, update the submodule URL:

**In each business repo:**
```bash
git config submodule.shared.url https://github.com/quantixtechnology/Quantix-Mobile-Shared.git
git submodule sync
```

**In the master repo:**
```bash
# Edit .gitmodules:
[submodule "shared"]
    path = shared
    url = https://github.com/quantixtechnology/Quantix-Mobile-Shared.git

git add .gitmodules
git submodule sync
git commit -m "Update shared submodule URL to GitHub"
```

---

## 8. Version Pinning Strategy

Each business repo pins `shared/` to a specific commit SHA. This means:
- A shared update never auto-applies — business owners control when they pull
- Breaking changes in shared do not reach businesses until they explicitly run `update_shared.sh`
- Each business can be on a different version of shared

**Recommended cadence:** Run `update_shared.sh` after:
- Each Quantix platform release
- Security patches in the shared package
- New features your business wants to adopt

---

## Quick Reference

| Task | Command |
|---|---|
| Pull shared update | `./scripts/update_shared.sh` |
| Dry run (preview update) | `./scripts/update_shared.sh --dry-run` |
| Rollback shared | `git revert HEAD` |
| Create new business | `./scripts/create_business.sh <slug> --shared-repo <url>` |
| Check shared version | `git -C shared rev-parse --short HEAD` |
| See shared changelog | `cat shared/CHANGELOG.md` |
