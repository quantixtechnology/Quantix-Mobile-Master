'use strict';

const crypto = require('crypto');
const store = require('./store');

const WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET || '';

/**
 * Verify the GitHub HMAC-SHA256 webhook signature.
 * Returns true if valid or if no secret is configured (dev mode).
 */
function verifySignature(req) {
  if (!WEBHOOK_SECRET) return true;
  const sig = req.headers['x-hub-signature-256'] || '';
  const digest = 'sha256=' + crypto
    .createHmac('sha256', WEBHOOK_SECRET)
    .update(JSON.stringify(req.body))
    .digest('hex');
  return crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(digest));
}

/**
 * Handle POST /mobile/webhook/github
 *
 * GitHub sends a workflow_run event when a CI job completes.
 * We also accept a simpler custom payload from the build job step:
 *   { slug, status, apkUrl, aabUrl }
 */
function handleGitHub(req, res) {
  if (!verifySignature(req)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  const body = req.body;

  // ── Custom payload from CI step ──────────────────────────────────────────
  if (body.slug && body.status) {
    const tenant = store.get(body.slug);
    if (!tenant) return res.status(404).json({ error: 'Tenant not found' });

    const patch = { status: body.status === 'success'
      ? store.BuildStatus.READY
      : store.BuildStatus.FAILED };

    if (body.apkUrl) patch.apkUrl = body.apkUrl;
    if (body.aabUrl) patch.aabUrl = body.aabUrl;
    if (body.status !== 'success') patch.error = `CI build ${body.status}`;

    store.update(body.slug, patch);
    console.log(`[webhook] ${body.slug} → ${patch.status}`);
    return res.json({ ok: true });
  }

  // ── Native GitHub workflow_run event ─────────────────────────────────────
  if (body.action === 'completed' && body.workflow_run) {
    const repoName = body.repository?.name || '';
    // Derive slug from repo name: "Freshmart-Mobile" → "freshmart"
    const slug = repoName.replace(/-Mobile$/i, '').toLowerCase();
    const conclusion = body.workflow_run.conclusion; // success | failure | cancelled

    const tenant = store.get(slug);
    if (!tenant) return res.status(404).json({ error: 'Tenant not found' });

    const patch = {
      status: conclusion === 'success'
        ? store.BuildStatus.READY
        : store.BuildStatus.FAILED,
    };
    if (conclusion !== 'success') {
      patch.error = `GitHub Actions workflow ${conclusion}`;
    }

    store.update(slug, patch);
    console.log(`[webhook] workflow_run ${slug} → ${patch.status} (${conclusion})`);
    return res.json({ ok: true });
  }

  // Unknown event — acknowledge without processing
  res.json({ ok: true, note: 'unhandled event' });
}

module.exports = { handleGitHub };
