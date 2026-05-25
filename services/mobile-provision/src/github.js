'use strict';

/**
 * GitHub automation hooks for Quantix tenant provisioning.
 *
 * ACTIVATION: Set GITHUB_TOKEN, GITHUB_OWNER, and GITHUB_OWNER_TYPE in .env,
 * then call createRepo() and pushCode() from provision.js after
 * create_business.sh completes. Set PROVISION_WEBHOOK_URL to auto-register a
 * webhook so CI build results are reported back to this service.
 *
 * GITHUB_OWNER_TYPE: "personal" (default) → POST /user/repos
 *                    "org"               → POST /orgs/{owner}/repos
 *
 * All functions are no-ops when GITHUB_TOKEN is absent (safe for local dev).
 */

const { Octokit } = require('@octokit/rest');
const { execFileSync } = require('child_process');
const path = require('path');

// GITHUB_OWNER replaces the old GITHUB_ORG — works for both personal accounts and orgs.
const OWNER = process.env.GITHUB_OWNER || process.env.GITHUB_ORG || 'quantixtechnology';
const OWNER_TYPE = (process.env.GITHUB_OWNER_TYPE || 'personal').toLowerCase(); // personal | org
const WEBHOOK_URL = process.env.PROVISION_WEBHOOK_URL || '';
const WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET || '';

function _octokit() {
  if (!process.env.GITHUB_TOKEN) return null;
  return new Octokit({ auth: process.env.GITHUB_TOKEN });
}

/**
 * Create a private GitHub repository for the tenant.
 * Returns the clone URL, or null when GITHUB_TOKEN is not set.
 */
async function createRepo(slug, appName) {
  const kit = _octokit();
  if (!kit) {
    console.warn('[github] GITHUB_TOKEN not set — skipping repo creation');
    return null;
  }

  const repoName = `${slug.charAt(0).toUpperCase() + slug.slice(1)}-Mobile`;
  const repoPayload = {
    name: repoName,
    description: `${appName} — Quantix mobile apps (customer, delivery, admin)`,
    private: true,
    auto_init: false,
  };

  let data;
  try {
    if (OWNER_TYPE === 'org') {
      ({ data } = await kit.repos.createInOrg({ org: OWNER, ...repoPayload }));
    } else {
      ({ data } = await kit.repos.createForAuthenticatedUser(repoPayload));
    }
    console.log(`[github] Repo created: ${data.html_url}`);
  } catch (err) {
    // 422 = repo already exists (retry after a failed push) — fetch it instead
    if (err.status === 422) {
      console.warn(`[github] Repo already exists — fetching ${OWNER}/${repoName}`);
      ({ data } = await kit.repos.get({ owner: OWNER, repo: repoName }));
    } else {
      throw err;
    }
  }
  return { repoUrl: data.html_url, cloneUrl: data.clone_url, repoName };
}

/**
 * Push the generated tenant directory to the GitHub repo.
 * repoDir   — absolute path to the generated tenant monorepo
 * cloneUrl  — HTTPS clone URL (token embedded for push auth)
 */
async function pushCode(repoDir, cloneUrl) {
  const kit = _octokit();
  if (!kit) {
    console.warn('[github] GITHUB_TOKEN not set — skipping code push');
    return;
  }

  // Embed token in URL for credential-free push
  const authedUrl = cloneUrl.replace(
    'https://',
    `https://x-access-token:${process.env.GITHUB_TOKEN}@`,
  );

  // Re-add remote (remove stale one from a previous failed attempt if present)
  try {
    execFileSync('git', ['remote', 'remove', 'origin'], { cwd: repoDir });
  } catch (_) { /* no remote yet — fine */ }
  execFileSync('git', ['remote', 'add', 'origin', authedUrl], { cwd: repoDir });
  execFileSync('git', ['push', '-u', 'origin', 'main'], { cwd: repoDir });
  console.log(`[github] Code pushed to origin/main`);
}

/**
 * Register a webhook on the repo so GitHub Actions status reports back
 * to this service at POST /mobile/webhook/github.
 *
 * Skipped when PROVISION_WEBHOOK_URL is empty.
 */
function _isLocalUrl(url) {
  return /localhost|127\.0\.0\.1/.test(url);
}

async function registerWebhook(repoName) {
  const kit = _octokit();
  if (!kit || !WEBHOOK_URL) {
    console.warn('[github] Skipping webhook registration (no token or URL)');
    return;
  }

  if (_isLocalUrl(WEBHOOK_URL)) {
    console.log('[github] Skipping webhook registration (local dev mode)');
    return;
  }

  await kit.repos.createWebhook({
    owner: OWNER,
    repo: repoName,
    config: {
      url: `${WEBHOOK_URL}/mobile/webhook/github`,
      content_type: 'json',
      secret: WEBHOOK_SECRET,
    },
    events: ['workflow_run'],
    active: true,
  });

  console.log(`[github] Webhook registered on ${OWNER}/${repoName}`);
}

/**
 * Enable GitHub Actions on the repo (on by default for new repos,
 * included here for repos that may have inherited a disabled state).
 */
async function enableActions(repoName) {
  const kit = _octokit();
  if (!kit) return;

  await kit.actions.setGithubActionsPermissionsRepository({
    owner: OWNER,
    repo: repoName,
    enabled: true,
    allowed_actions: 'all',
  });

  console.log(`[github] Actions enabled on ${OWNER}/${repoName}`);
}

module.exports = { createRepo, pushCode, registerWebhook, enableActions };
