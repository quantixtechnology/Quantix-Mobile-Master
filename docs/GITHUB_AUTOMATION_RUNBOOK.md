# GitHub Automation Runbook

Complete the live GitHub chain for any tenant whose local directory is already
generated but whose GitHub repo has not been created yet.

---

## Prerequisites

| Item | Required |
|---|---|
| GitHub PAT | `repo` + `workflow` scopes |
| Provision service | Running on `:3400` |
| Tenant state | `BUILDING` (create_business.sh completed, push skipped) |
| Tenant directory | Exists locally as `{Slug}-Mobile/` |

### Create the PAT

1. github.com → **Settings → Developer settings → Personal access tokens → Tokens (classic)**
2. **Generate new token (classic)**
3. Scopes required:
   - `repo` (full control — needed to create private repos)
   - `workflow` (needed to enable Actions and push `.github/workflows/`)
4. Copy the token immediately (shown only once)

---

## Step 1 — Set GITHUB_TOKEN in .env

```bash
# Edit services/mobile-provision/.env
# Replace the empty value with your token:
GITHUB_TOKEN=<paste-your-token-here>
GITHUB_ORG=quantixtechnology
PROVISION_WEBHOOK_URL=https://mobile.quantixtechnology.in   # public URL for webhook registration
GITHUB_WEBHOOK_SECRET=dev-webhook-secret-2025          # must match GitHub webhook config
```

> `.env` is gitignored — the token will never be committed.

---

## Step 2 — Restart the provision service

```bash
# Kill the running instance
pkill -f "node src/index.js"

# Restart
cd /path/to/quantix_customer_app/services/mobile-provision
node src/index.js &

# Verify token is loaded
curl http://localhost:3400/health
# Expected: {"ok":true,"service":"mobile-provision"}
# Service should NOT print the "GITHUB_TOKEN not set" warning
```

---

## Step 3 — Resume GitHub push for the existing tenant

The tenant directory (`Arbazfreshmeat-Mobile/`) already exists from the
previous provisioning run. Use the resume endpoint instead of re-running
the full provision pipeline (which would fail with 409 Conflict anyway).

```bash
curl -s -X POST http://localhost:3400/mobile/tenants/arbazfreshmeat/push-to-github \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: quantix-dev-key-2025" | python3 -m json.tool
```

Expected response:
```json
{
  "ok": true,
  "message": "GitHub push started for arbazfreshmeat",
  "tenantDir": "/Users/mukhtarkhan/Projects/Arbazfreshmeat-Mobile"
}
```

---

## Step 4 — Monitor provision service logs

Watch the service terminal for:

```
[github] Repo created: https://github.com/quantixtechnology/Arbazfreshmeat-Mobile
[github] Code pushed to origin/main
[github] Actions enabled on quantixtechnology/Arbazfreshmeat-Mobile
[github] Webhook registered on quantixtechnology/Arbazfreshmeat-Mobile
[push-to-github] arbazfreshmeat → https://github.com/quantixtechnology/Arbazfreshmeat-Mobile
```

---

## Step 5 — Verify tenant status (repo URL set)

```bash
curl -s http://localhost:3400/mobile/tenants/arbazfreshmeat \
  -H "X-Api-Key: quantix-dev-key-2025" | python3 -m json.tool
```

Expected:
```json
{
  "slug": "arbazfreshmeat",
  "status": "BUILDING",
  "brandingStatus": "DONE",
  "repoUrl": "https://github.com/quantixtechnology/Arbazfreshmeat-Mobile",
  ...
}
```

`status` stays `BUILDING` — it transitions to `READY` only when CI completes
and the `notify-provision` job fires the artifact webhook.

---

## Step 6 — Add GitHub Secrets to the tenant repo

Before CI can build successfully, add these secrets to the new repo:

**GitHub → Arbazfreshmeat-Mobile repo → Settings → Secrets and variables → Actions**

| Secret | Value |
|---|---|
| `CUSTOMER_FIREBASE_OPTIONS` | Contents of `customer_app/lib/firebase_options.dart` (with real Firebase values, or leave absent for placeholder) |
| `DELIVERY_FIREBASE_OPTIONS` | Contents of `delivery_app/lib/firebase_options.dart` |
| `ADMIN_FIREBASE_OPTIONS` | Contents of `admin_app/lib/firebase_options.dart` |
| `CUSTOMER_GOOGLE_SERVICES` | Contents of customer `google-services.json` |
| `DELIVERY_GOOGLE_SERVICES` | Contents of delivery `google-services.json` |
| `ADMIN_GOOGLE_SERVICES` | Contents of admin `google-services.json` |
| `KEYSTORE_BASE64` | `base64 -i quantix-release.jks` |
| `KEY_ALIAS` | Keystore key alias |
| `KEY_PASSWORD` | Key password |
| `STORE_PASSWORD` | Store password |
| `PROVISION_WEBHOOK_URL` | `https://mobile.quantixtechnology.in` |
| `PROVISION_API_KEY` | `quantix-dev-key-2025` (matches `API_KEY` in `.env`) |

> Without Firebase / keystore secrets, CI still builds using placeholder stubs
> (no signing, placeholder Firebase config). The APK will install but won't
> receive push notifications or crash reports.

---

## Step 7 — Monitor CI

```
https://github.com/quantixtechnology/Arbazfreshmeat-Mobile/actions
```

Jobs expected:
- `analyze` — Flutter analyze + tests (~2 min)
- `build-customer-apk` — release APK (~8 min)
- `build-customer-aab` — release AAB (~8 min)
- `build-delivery-aab` — release AAB (~8 min)
- `build-admin-aab` — release AAB (~8 min)
- `notify-provision` — posts artifact webhook to provision service (~10 sec)

---

## Step 8 — Verify dashboard update

After `notify-provision` fires:

```bash
curl -s http://localhost:3400/mobile/tenants/arbazfreshmeat \
  -H "X-Api-Key: quantix-dev-key-2025" | python3 -m json.tool
```

Expected:
```json
{
  "status": "READY",
  "apkUrl": "https://github.com/quantixtechnology/Arbazfreshmeat-Mobile/actions/runs/...",
  "aabUrl": "https://github.com/quantixtechnology/Arbazfreshmeat-Mobile/actions/runs/...",
  "error": null
}
```

---

## Evidence to capture

| Item | Where |
|---|---|
| Repo URL | `https://github.com/quantixtechnology/Arbazfreshmeat-Mobile` |
| Workflow URL | Repo → Actions tab → most recent run |
| APK download | Workflow run → Artifacts → `arbazfreshmeat-customer-release-apk` |
| AAB download | Workflow run → Artifacts → `arbazfreshmeat-customer-release-aab` |
| Dashboard state | `GET /mobile/tenants/arbazfreshmeat` → `status: READY` |

---

## Troubleshooting

**`403` on repo creation** — token missing `repo` scope. Regenerate with full `repo` scope.

**`403` on push** — token missing `workflow` scope (the `.github/workflows/` directory
contains workflow files, which requires the `workflow` scope to push).

**`push-to-github` returns `409`** — tenant status is not `BUILDING`. Check:
```bash
curl http://localhost:3400/mobile/tenants/arbazfreshmeat -H "X-Api-Key: quantix-dev-key-2025"
```
If `FAILED`, check `error` field. If `READY`, the repo was already pushed.

**Repo already exists on GitHub** — delete it first:
```bash
# Via gh CLI:
gh repo delete quantixtechnology/Arbazfreshmeat-Mobile --yes
# Or manually: github.com/quantixtechnology/Arbazfreshmeat-Mobile → Settings → Delete repository
```
Then re-call `push-to-github`.

**`notify-provision` webhook unreachable** — `PROVISION_WEBHOOK_URL` must be
publicly reachable. In dev, use `ngrok`:
```bash
ngrok http 3400
# Update PROVISION_WEBHOOK_URL in .env to the ngrok HTTPS URL
# Restart provision service
# Re-register webhook: re-call push-to-github (will fail on repo already exists — delete first)
```
