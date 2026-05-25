'use strict';

/**
 * GitHub automation hooks for Quantix tenant provisioning.
 *
 * ACTIVATION: Set GITHUB_TOKEN and GITHUB_ORG in .env, then call
 * createRepo() and pushCode() from provision.js after create_business.sh
 * completes. Set PROVISION_WEBHOOK_URL to auto-register a webhook so
 * CI build results are reported back to this service.
 *
 * All functions are no-ops when GITHUB_TOKEN is absent (safe for local dev).
 */

const { Octokit } = require('@octokit/rest');
const { execFileSync } = require('child_process');
const path = require('path');

const ORG = process.env.GITHUB_ORG || 'quantixtechnology';
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

  const { data } = await kit.repos.createInOrg({
    org: ORG,
    name: repoName,
    description: `${appName} — Quantix mobile apps (customer, delivery, admin)`,
    private: true,
    auto_init: false,
  });

  console.log(`[github] Repo created: ${data.html_url}`);
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
async function registerWebhook(repoName) {
  const kit = _octokit();
  if (!kit || !WEBHOOK_URL) {
    console.warn('[github] Skipping webhook registration (no token or URL)');
    return;
  }

  await kit.repos.createWebhook({
    owner: ORG,
    repo: repoName,
    config: {
      url: `${WEBHOOK_URL}/mobile/webhook/github`,
      content_type: 'json',
      secret: WEBHOOK_SECRET,
    },
    events: ['workflow_run'],
    active: true,
  });

  console.log(`[github] Webhook registered on ${ORG}/${repoName}`);
}

/**
 * Enable GitHub Actions on the repo (on by default for new repos,
 * included here for repos that may have inherited a disabled state).
 */
async function enableActions(repoName) {
  const kit = _octokit();
  if (!kit) return;

  await kit.actions.setGithubActionsPermissionsRepository({
    owner: ORG,
    repo: repoName,
    enabled: true,
    allowed_actions: 'all',
  });

  console.log(`[github] Actions enabled on ${ORG}/${repoName}`);
}

module.exports = { createRepo, pushCode, registerWebhook, enableActions };
