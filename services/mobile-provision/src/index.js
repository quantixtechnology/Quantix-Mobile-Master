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

// ── POST /mobile/webhook/github ───────────────────────────────────────────────
app.post('/mobile/webhook/github', webhook.handleGitHub);

// ── Start ─────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`[mobile-provision] Listening on :${PORT}`);
  if (!process.env.GITHUB_TOKEN) {
    console.warn('[mobile-provision] GITHUB_TOKEN not set — GitHub automation disabled');
  }
});
