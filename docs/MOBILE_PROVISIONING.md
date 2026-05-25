# Quantix Mobile Provisioning

Automated pipeline that turns a **Quantix Core business record** into a
fully-built, store-ready Flutter monorepo — without any manual steps from
the platform team.

---

## Architecture

```
Quantix Core (backend)
        │
        │  POST /mobile/provision-tenant
        ▼
┌─────────────────────────────────┐
│  mobile-provision service       │  services/mobile-provision/
│  Express · Node 18+             │
│                                 │
│  1. Validate + store PENDING    │
│  2. Run create_business.sh  ────┼──▶ generates tenant monorepo on disk
│  3. Create GitHub repo      ────┼──▶ GitHub API (Octokit)
│  4. Push code + enable Actions  │
│  5. Register webhook        ────┼──▶ CI reports back on completion
│  6. State → BUILDING            │
└─────────────┬───────────────────┘
              │  GitHub Actions CI
              ▼
   flutter build apk / appbundle
              │
              │  POST /mobile/webhook/github
              ▼
   State → READY  (APK / AAB URLs attached)
```

### Component map

| File | Responsibility |
|---|---|
| `src/index.js` | Express server, auth middleware, route definitions |
| `src/store.js` | JSON-file-backed state store; in-memory read, disk write |
| `src/provision.js` | Orchestrator — calls `create_business.sh`, drives state transitions |
| `src/github.js` | GitHub API hooks — repo creation, code push, webhook registration |
| `src/webhook.js` | Inbound webhook — translates CI outcomes to build states |

---

## Build States

```
PENDING ──▶ PROVISIONING ──▶ BUILDING ──▶ READY
                  │                │
                  └────────────────┴──▶ FAILED
```

| State | Meaning |
|---|---|
| `PENDING` | Request accepted, pipeline not yet started |
| `PROVISIONING` | `create_business.sh` running; branding being generated |
| `BUILDING` | Code pushed to GitHub; Actions workflow in progress |
| `READY` | APK + AAB built and available via artifact URLs |
| `FAILED` | Any stage failed; `error` field contains detail |

---

## API Reference

### POST /mobile/provision-tenant

Trigger provisioning for a new business.

**Headers:** `X-Api-Key: <API_KEY>`

**Request body:**
```json
{
  "businessId": "BIZ001",
  "slug": "freshmart",
  "name": "Freshmart",
  "theme": {
    "primaryColor": "#00B14F",
    "accentColor": "#FF6B00"
  },
  "logo": "https://cdn.quantix.app/logos/freshmart.png",
  "businessType": "grocery",
  "packageId": "com.freshmart",
  "features": ["catalog", "cart", "orders", "tracking", "loyalty", "delivery"]
}
```

**Response 202:**
```json
{
  "tenantId": "freshmart",
  "status": "PENDING",
  "message": "Provisioning started"
}
```

**Errors:**
- `400` — missing `slug`, `name`, or `businessId`
- `409` — tenant `slug` already exists

---

### GET /mobile/tenants

List all provisioned tenants with current status.

**Response 200:**
```json
{
  "tenants": [
    {
      "slug": "freshmart",
      "businessId": "BIZ001",
      "name": "Freshmart",
      "packageId": "com.freshmart",
      "status": "READY",
      "brandingStatus": "DONE",
      "firebaseStatus": "STUB",
      "repoUrl": "https://github.com/quantixtechnology/Freshmart-Mobile",
      "apkUrl": null,
      "aabUrl": null,
      "error": null,
      "createdAt": "2026-05-25T10:00:00.000Z",
      "updatedAt": "2026-05-25T10:08:43.000Z"
    }
  ]
}
```

---

### GET /mobile/tenants/:slug

Get a single tenant's current state.

---

### POST /mobile/webhook/github

Receives GitHub Actions workflow outcomes. Accepts two payload shapes:

**Custom CI step payload** (added to the tenant's `.github/workflows/dart.yml`):
```json
{ "slug": "freshmart", "status": "success", "apkUrl": "...", "aabUrl": "..." }
```

**Native GitHub `workflow_run` event** (registered automatically when
`PROVISION_WEBHOOK_URL` is set).

---

## Events from Quantix Core

Add this call to the Core `Business.onCreate` hook:

```js
// Quantix Core — business creation handler
async function onBusinessCreated(business) {
  await fetch(`${PROVISION_SERVICE_URL}/mobile/provision-tenant`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Api-Key': process.env.MOBILE_PROVISION_API_KEY,
    },
    body: JSON.stringify({
      businessId: business.id,
      slug:       business.slug,
      name:       business.name,
      theme: {
        primaryColor: business.theme?.primaryColor ?? '#00B14F',
        accentColor:  business.theme?.accentColor  ?? '#FF6B00',
      },
      logo:         business.logo,
      businessType: business.type,
      packageId:    business.packageId,
      features:     business.features,
    }),
  });
}
```

---

## GitHub Automation

Activation requires two environment variables:

```
GITHUB_TOKEN=ghp_...        # PAT with repo + workflow scopes
GITHUB_ORG=quantixtechnology  # org or user to create repos under
```

When both are set, `src/github.js` will:

1. **Create repo** — private, under `GITHUB_ORG`, named `<Slug>-Mobile`
2. **Push code** — `git push -u origin main` with token-embedded auth URL
3. **Enable Actions** — explicit API call (safe no-op if already enabled)
4. **Register webhook** — `workflow_run` events → `POST /mobile/webhook/github`

When `GITHUB_TOKEN` is absent, steps 1–4 are skipped with a console warning.
The tenant directory is still generated on disk and can be pushed manually.

### Workflow notification step

Add this step to the tenant's `dart.yml` build jobs so the provision service
receives build outcomes:

```yaml
- name: Notify provision service
  if: always()
  env:
    PROVISION_WEBHOOK_URL: ${{ secrets.PROVISION_WEBHOOK_URL }}
    PROVISION_API_KEY: ${{ secrets.PROVISION_API_KEY }}
    SLUG: ${{ github.event.repository.name }}
  run: |
    SLUG_LOWER=$(echo "$SLUG" | sed 's/-Mobile$//' | tr '[:upper:]' '[:lower:]')
    curl -s -X POST "${PROVISION_WEBHOOK_URL}/mobile/webhook/github" \
      -H "Content-Type: application/json" \
      -H "X-Api-Key: ${PROVISION_API_KEY}" \
      -d "{\"slug\":\"${SLUG_LOWER}\",\"status\":\"${{ job.status }}\"}"
```

---

## Admin Dashboard — Mobile Tab

The admin app includes a **Mobile Provisioning** screen at `/mobile`
(reachable from the Dashboard quick actions).

| Panel | What it shows |
|---|---|
| Tenant status | PENDING / PROVISIONING / BUILDING / READY / FAILED |
| Branding status | PENDING / DONE — branding assets generated |
| Firebase status | STUB / CONFIGURED — placeholder vs real credentials |
| Build status | Same as tenant status; APK / AAB links when READY |
| Error detail | Expandable card showing raw error on FAILED |

The screen polls `GET /mobile/tenants` on load and on pull-to-refresh.
It shows a graceful "service unreachable" state when the provision service
is not running (connection refused / DNS failure).

---

## Deployment

### Running the service

```bash
cd services/mobile-provision
cp .env.example .env
# Fill in MASTER_REPO_DIR, GITHUB_TOKEN, GITHUB_ORG, API_KEY
npm install
npm start
```

The service listens on `PORT` (default `3400`).

### Environment variables

| Variable | Required | Description |
|---|---|---|
| `API_KEY` | Yes (prod) | Bearer key checked on all routes |
| `MASTER_REPO_DIR` | Yes | Path to `Quantix-Mobile-Master` checkout |
| `GITHUB_TOKEN` | No* | Enables repo creation + push |
| `GITHUB_ORG` | No* | GitHub org for new repos |
| `SHARED_REPO_URL` | No | Submodule URL passed to `create_business.sh` |
| `PROVISION_WEBHOOK_URL` | No | Public URL for CI → service callbacks |
| `GITHUB_WEBHOOK_SECRET` | No | HMAC secret for webhook signature verification |
| `STATE_FILE` | No | Path to JSON state file (default: `provision-state.json`) |
| `PORT` | No | HTTP port (default: `3400`) |

\* GitHub automation is disabled (graceful no-op) when `GITHUB_TOKEN` is absent.

---

## Failure Handling

### FAILED state — manual recovery

1. Check `error` field: `GET /mobile/tenants/<slug>`
2. Fix the root cause (bad slug, missing script, network error)
3. Delete the partially-created tenant directory if present:
   ```bash
   rm -rf /opt/quantix/tenants/<Slug>-Mobile
   ```
4. Delete the state record from `STATE_FILE` (edit JSON, remove slug key)
5. Re-call `POST /mobile/provision-tenant` with corrected payload

### BUILDING — CI never completed

1. Check the GitHub Actions run on the tenant repo
2. If it failed, fix the root cause (missing secrets, Gradle error)
3. Re-run the workflow manually on GitHub, or push a fix commit
4. The webhook will update state to READY or FAILED automatically

### Provision service down — webhook missed

State stays at BUILDING. Manual recovery:
```bash
curl -X POST http://localhost:3400/mobile/webhook/github \
  -H "Content-Type: application/json" \
  -d '{"slug":"freshmart","status":"success"}'
```

---

## Firebase per-tenant setup

The generated tenant repo contains placeholder `firebase_options.dart` stubs.
Full Firebase requires:

1. Create a Firebase project for the business
2. Run `flutterfire configure` in each sub-app directory
3. Add the resulting `firebase_options.dart` contents as GitHub Secrets:
   - `CUSTOMER_FIREBASE_OPTIONS`
   - `DELIVERY_FIREBASE_OPTIONS`
   - `ADMIN_FIREBASE_OPTIONS`
4. Add `google-services.json` as `CUSTOMER_GOOGLE_SERVICES` etc.
5. Update `firebaseStatus` in the state store to `CONFIGURED`

Until step 3–4 are done the apps build and run but FCM / Crashlytics are inactive.

---

## Remaining Blockers

| # | Blocker | Resolution |
|---|---|---|
| 1 | `GITHUB_TOKEN` not provisioned | Create PAT with `repo` + `workflow` scopes; add to `.env` |
| 2 | `PROVISION_WEBHOOK_URL` not public | Deploy service behind reverse proxy with TLS; set env var |
| 3 | Firebase per-tenant not automated | Manual `flutterfire configure` step per business |
| 4 | APK artifact URLs not returned | CI step must upload artifact and POST URL to webhook |
| 5 | Core event hook not wired | Add `onBusinessCreated` call in Quantix Core backend |
