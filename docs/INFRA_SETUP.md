# Quantix Infrastructure Setup

End-to-end environment variable reference for running the Quantix SaaS platform on a VPS.

---

## Architecture overview

```
                ┌──────────────────────────┐
  Browser ──▶   │  Nginx (TLS termination)  │
                └─────────┬────────────────┘
                          │
           ┌──────────────┴──────────────┐
           ▼                             ▼
  Quantix Core (Next.js)     mobile-provision (Node.js)
  :3000  /api/…              :3400  /mobile/…
           │                             │
           └──────────── DB ─────────────┘
                     (SQLite / Postgres)
```

GitHub Actions (on tenant repos) → POST `/mobile/webhook/ci-artifact` → mobile-provision → POST `/api/core/mobile/webhook` → Core DB

---

## 1. Quantix Core — `~/Downloads/Quantix Core 1.0/.env`

| Variable | Description |
|---|---|
| `DATABASE_URL` | Prisma connection string. SQLite: `file:./dev.db`; Postgres: `postgresql://user:pass@host/db` |
| `NEXTAUTH_SECRET` | Random 32-byte hex string. Generate: `openssl rand -hex 32` |
| `NEXT_PUBLIC_STOREFRONT_DOMAIN` | Storefront public domain, e.g. `quantixtechnology.in` |
| `VPS_HOST` | VPS hostname for SSH deployments |
| `CREDENTIAL_ENCRYPT_KEY` | AES key for encrypting stored credentials. Generate: `openssl rand -hex 32` |
| `RAZORPAY_KEY_ID` | Razorpay live key ID |
| `RAZORPAY_KEY_SECRET` | Razorpay live key secret |
| `SMTP_HOST` | SMTP host (default `smtp.gmail.com`) |
| `SMTP_PORT` | SMTP port (default `587`) |
| `SMTP_SECURE` | `true` for port 465, `false` for 587 |
| `SMTP_USER` | Gmail sender address |
| `SMTP_PASS` | Gmail app password (16 chars, no spaces) |
| `MAIL_FROM` | Display name + address: `"Quantix OTP <otp@example.com>"` |
| `MOBILE_PROVISION_URL` | URL of the mobile-provision service, e.g. `http://localhost:3400` |
| `MOBILE_PROVISION_API_KEY` | Must match `API_KEY` in mobile-provision `.env` |
| `MOBILE_WEBHOOK_SECRET` | Shared secret for inbound CI webhooks (`POST /api/core/mobile/webhook`) |

---

## 2. Mobile Provision Service — `services/mobile-provision/.env`

Copy `.env.example` → `.env` and fill in values.

| Variable | Description |
|---|---|
| `PORT` | HTTP port (default `3400`) |
| `API_KEY` | API key required on all authenticated endpoints (`X-Api-Key` header). Must match Core `MOBILE_PROVISION_API_KEY` |
| `MASTER_REPO_DIR` | Absolute path to the checked-out `Quantix-Mobile-Master` template repo, e.g. `/opt/quantix/Quantix-Mobile-Master` |
| `TENANTS_DIR` | Directory where tenant repos are created, e.g. `/opt/quantix/tenants` |
| `STATE_FILE` | JSON file that persists provisioning records across restarts, e.g. `/opt/quantix/provision-state.json` |
| `GITHUB_TOKEN` | GitHub Personal Access Token with `repo` + `workflow` scopes. Create at: GitHub → Settings → Developer settings → PAT |
| `GITHUB_ORG` | GitHub org or user to create tenant repos under, e.g. `quantixtechnology` |
| `SHARED_REPO_URL` | URL of the shared Dart package submodule, e.g. `https://github.com/quantixtechnology/Quantix-Mobile-Shared.git` |
| `PROVISION_WEBHOOK_URL` | Public URL of this service (without trailing slash), e.g. `https://mobile.quantixtechnology.in`. Registered as the webhook receiver on new tenant repos |
| `GITHUB_WEBHOOK_SECRET` | HMAC secret for verifying GitHub `workflow_run` webhook payloads |
| `QUANTIX_CORE_URL` | URL of Quantix Core, e.g. `https://api.quantixtechnology.in`. Build outcomes are forwarded here |
| `QUANTIX_CORE_WEBHOOK_SECRET` | Must match Core `MOBILE_WEBHOOK_SECRET` |

---

## 3. GitHub Actions Secrets (on the master / tenant repos)

Set these at: **GitHub repo → Settings → Secrets and variables → Actions**

| Secret | Description |
|---|---|
| `CUSTOMER_FIREBASE_OPTIONS` | Contents of `customer_app/lib/firebase_options.dart` with real Firebase project values |
| `DELIVERY_FIREBASE_OPTIONS` | Contents of `delivery_app/lib/firebase_options.dart` |
| `ADMIN_FIREBASE_OPTIONS` | Contents of `admin_app/lib/firebase_options.dart` |
| `CUSTOMER_GOOGLE_SERVICES` | Contents of `customer_app/android/app/google-services.json` |
| `DELIVERY_GOOGLE_SERVICES` | Contents of `delivery_app/android/app/google-services.json` |
| `ADMIN_GOOGLE_SERVICES` | Contents of `admin_app/android/app/google-services.json` |
| `KEYSTORE_BASE64` | Base64-encoded release keystore: `base64 -i quantix-release.jks` |
| `KEY_ALIAS` | Keystore key alias |
| `KEY_PASSWORD` | Key password |
| `STORE_PASSWORD` | Keystore password |
| `PROVISION_WEBHOOK_URL` | Public URL of the mobile-provision service (same as `.env` value) |
| `PROVISION_API_KEY` | API key for the mobile-provision service (same as `API_KEY` in `.env`) |

> **Note:** `PROVISION_WEBHOOK_URL` and `PROVISION_API_KEY` are only needed on tenant repos. The `notify-provision` CI job skips repos whose name does not end in `-Mobile`.

---

## 4. Nginx Reverse Proxy

Install Nginx and Certbot, then create `/etc/nginx/sites-available/quantix`:

```nginx
# Quantix Core (Next.js)
server {
    listen 443 ssl http2;
    server_name api.quantixtechnology.in;

    ssl_certificate     /etc/letsencrypt/live/api.quantixtechnology.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.quantixtechnology.in/privkey.pem;

    location / {
        proxy_pass         http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection 'upgrade';
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# Mobile Provision Service
server {
    listen 443 ssl http2;
    server_name mobile.quantixtechnology.in;

    ssl_certificate     /etc/letsencrypt/live/mobile.quantixtechnology.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mobile.quantixtechnology.in/privkey.pem;

    # Webhook payloads from GitHub Actions can be up to 1 MB
    client_max_body_size 1m;

    location / {
        proxy_pass         http://127.0.0.1:3400;
        proxy_http_version 1.1;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}

# HTTP → HTTPS redirect
server {
    listen 80;
    server_name api.quantixtechnology.in mobile.quantixtechnology.in;
    return 301 https://$host$request_uri;
}
```

```bash
# Enable site and obtain certificates
ln -s /etc/nginx/sites-available/quantix /etc/nginx/sites-enabled/
certbot --nginx -d api.quantixtechnology.in -d mobile.quantixtechnology.in
nginx -t && systemctl reload nginx
```

---

## 5. Deploy mobile-provision with Docker

```bash
# On the VPS, clone the repo and enter the service directory
cd /opt/quantix
git clone https://github.com/quantixtechnology/Quantix-Mobile-Master.git

cd /path/to/quantix_customer_app/services/mobile-provision
cp .env.example .env
# Fill in .env values

# Start the service
docker compose up -d

# Verify health
curl http://localhost:3400/health
# → {"ok":true,"service":"mobile-provision"}

# Tail logs
docker compose logs -f mobile-provision
```

---

## 6. Quick-start checklist

- [ ] Core `.env` filled, `npm run build && npm start` succeeds
- [ ] Provision `.env` filled, `GITHUB_TOKEN` has `repo` + `workflow` scopes
- [ ] `MASTER_REPO_DIR` points to a valid `Quantix-Mobile-Master` checkout
- [ ] Docker container healthy: `GET /health` → `{"ok":true}`
- [ ] Nginx TLS certs issued for `api.quantixtechnology.in` and `mobile.quantixtechnology.in`
- [ ] GitHub Secrets set on the master repo (Firebase, keystore, provision URL + key)
- [ ] CI run on master repo completes green (all 5 jobs + notify-provision)
- [ ] Create a test business in Core → confirm repo appears in GitHub org
