'use strict';

require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const express = require('express');
const { v4: uuidv4 } = require('uuid');
const store = require('./store');
const provision = require('./provision');
const webhook = require('./webhook');

const PORT = parseInt(process.env.PORT || '3400', 10);
const API_KEY = process.env.API_KEY || '';

const app = express();
app.use(express.json());

// ── Auth middleware ──────────────────────────────────────────────────────────
function requireAuth(req, res, next) {
  if (!API_KEY) return next(); // dev mode: no key configured
  const key = req.headers['x-api-key'] || req.query.apiKey;
  if (key !== API_KEY) return res.status(401).json({ error: 'Unauthorized' });
  next();
}

// ── Health ───────────────────────────────────────────────────────────────────
app.get('/health', (_, res) => res.json({ ok: true, service: 'mobile-provision' }));

// ── POST /mobile/provision-tenant ────────────────────────────────────────────
app.post('/mobile/provision-tenant', requireAuth, (req, res) => {
  const { businessId, slug, name, theme, logo, businessType, packageId, features } = req.body;

  if (!slug || !name || !businessId) {
    return res.status(400).json({ error: 'slug, name, and businessId are required' });
  }

  const normalized = slug.toLowerCase().replace(/[^a-z0-9-]/g, '');
  if (!normalized) {
    return res.status(400).json({ error: 'slug must contain alphanumeric characters' });
  }

  if (store.get(normalized)) {
    return res.status(409).json({ error: `Tenant '${normalized}' already exists` });
  }

  const record = store.create(normalized, { businessId, name, packageId, theme, features });

  // Kick off pipeline asynchronously — respond immediately with 202
  provision.run(normalized, { businessId, name, theme, logo, businessType, packageId, features });

  res.status(202).json({
    tenantId: normalized,
    status: record.status,
    message: 'Provisioning started',
  });
});

// ── GET /mobile/tenants ───────────────────────────────────────────────────────
app.get('/mobile/tenants', requireAuth, (_, res) => {
  res.json({ tenants: store.list() });
});

// ── GET /mobile/tenants/:slug ─────────────────────────────────────────────────
app.get('/mobile/tenants/:slug', requireAuth, (req, res) => {
  const record = store.get(req.params.slug);
  if (!record) return res.status(404).json({ error: 'Tenant not found' });
  res.json(record);
});

// ── POST /mobile/tenants/:slug/push-to-github ────────────────────────────────
// Resume GitHub steps for a BUILDING tenant whose local directory already exists
// (i.e. create_business.sh ran but GITHUB_TOKEN was absent at provision time).
// Responds immediately; repo creation + push run fire-and-forget in background.
app.post('/mobile/tenants/:slug/push-to-github', requireAuth, (req, res) => {
  const fs = require('fs');
  const path = require('path');
  const github = require('./github');

  const slug = req.params.slug;
  const record = store.get(slug);
  if (!record) return res.status(404).json({ error: 'Tenant not found' });

  // Retriable states:
  //   BUILDING + no repoUrl  — token absent at provision time, nothing pushed yet
  //   FAILED + branding DONE — previous push attempt failed (wrong scope, network, etc.)
  const retriable = record.status === store.BuildStatus.BUILDING ||
    (record.status === store.BuildStatus.FAILED && record.brandingStatus === 'DONE');
  if (!retriable) {
    return res.status(409).json({
      error: `Cannot resume: status=${record.status} brandingStatus=${record.brandingStatus}`,
      hint: 'Valid when status=BUILDING or status=FAILED with brandingStatus=DONE.',
    });
  }

  if (!process.env.GITHUB_TOKEN) {
    return res.status(503).json({ error: 'GITHUB_TOKEN not configured — set it in .env and restart the service' });
  }

  const MASTER_DIR = process.env.MASTER_REPO_DIR || path.resolve(__dirname, '..', '..', '..');
  const folderName = slug.charAt(0).toUpperCase() + slug.slice(1) + '-Mobile';
  const tenantDir = path.join(path.dirname(MASTER_DIR), folderName);

  if (!fs.existsSync(tenantDir)) {
    return res.status(422).json({
      error: `Tenant directory not found: ${tenantDir}`,
      hint: 'Run POST /mobile/provision-tenant to regenerate it first.',
    });
  }

  res.json({ ok: true, message: `GitHub push started for ${slug}`, tenantDir });

  // Fire-and-forget — push to GitHub, trigger CI
  (async () => {
    try {
      const repo = await github.createRepo(slug, record.name);
      if (!repo) return; // no token, already guarded above
      // Persist repoUrl immediately so a subsequent push failure is retriable
      store.update(slug, { repoUrl: repo.repoUrl });
      await github.pushCode(tenantDir, repo.cloneUrl);
      await github.enableActions(repo.repoName);
      await github.registerWebhook(repo.repoName);
      // Reset to BUILDING + clear any stale error — CI will advance to READY/FAILED
      store.update(slug, { status: store.BuildStatus.BUILDING, error: null });
      console.log(`[push-to-github] ${slug} → ${repo.repoUrl}`);
    } catch (err) {
      console.error(`[push-to-github] ${slug} FAILED:`, err.message);
      store.update(slug, { status: store.BuildStatus.FAILED, error: err.message });
    }
  })();
});

// ── POST /mobile/webhook/github ───────────────────────────────────────────────
app.post('/mobile/webhook/github', webhook.handleGitHub);

// ── POST /mobile/webhook/ci-artifact ─────────────────────────────────────────
// Called by GitHub Actions after each build job to report status + artifact URLs.
// Authenticated with X-Api-Key (same key as other authenticated endpoints).
app.post('/mobile/webhook/ci-artifact', requireAuth, webhook.handleCiArtifact);

// ── Start ─────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`[mobile-provision] Listening on :${PORT}`);
  if (!process.env.GITHUB_TOKEN) {
    console.warn('[mobile-provision] GITHUB_TOKEN not set — GitHub automation disabled');
  }
});
