'use strict';

const { spawn } = require('child_process');
const path = require('path');
const store = require('./store');
const github = require('./github');

const MASTER_DIR = process.env.MASTER_REPO_DIR ||
  path.resolve(__dirname, '..', '..', '..');  // falls back to repo root in dev

const SHARED_REPO_URL = process.env.SHARED_REPO_URL ||
  'https://github.com/quantixtechnology/Quantix-Mobile-Shared.git';

/**
 * Run create_business.sh for the given tenant and return the generated
 * directory path. Resolves on exit code 0, rejects otherwise.
 */
function runCreateBusiness(slug, params) {
  return new Promise((resolve, reject) => {
    const args = [
      path.join(MASTER_DIR, 'scripts', 'create_business.sh'),
      slug,
      '--app-name',      params.name,
      '--package-base',  params.packageId || `com.${slug}`,
      '--type',          params.businessType || 'generic',
      '--primary-color', params.theme?.primaryColor || '#00B14F',
      '--accent-color',  params.theme?.accentColor  || '#FF6B00',
      '--business-id',   params.businessId,
      '--shared-repo',   SHARED_REPO_URL,
      '-y',
    ];

    if (params.features) {
      args.push('--features', params.features.join(','));
    }

    const proc = spawn('bash', args, {
      env: { ...process.env },
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    let stdout = '';
    let stderr = '';
    proc.stdout.on('data', (d) => { stdout += d; process.stdout.write(d); });
    proc.stderr.on('data', (d) => { stderr += d; process.stderr.write(d); });

    proc.on('close', (code) => {
      if (code === 0) {
        const folderName = slug.charAt(0).toUpperCase() + slug.slice(1) + '-Mobile';
        const tenantDir = path.join(path.dirname(MASTER_DIR), folderName);
        resolve(tenantDir);
      } else {
        reject(new Error(`create_business.sh exited ${code}\n${stderr}`));
      }
    });
  });
}

/**
 * Orchestrate the full provisioning pipeline for one tenant.
 * Runs asynchronously — callers should not await this.
 */
async function run(slug, params) {
  try {
    // ── 1. PROVISIONING — run create_business.sh ──────────────────────────
    store.update(slug, { status: store.BuildStatus.PROVISIONING });
    const tenantDir = await runCreateBusiness(slug, params);
    store.update(slug, { brandingStatus: 'DONE' });

    // ── 2. GitHub — create repo + push code ───────────────────────────────
    const repo = await github.createRepo(slug, params.name);
    if (repo) {
      await github.pushCode(tenantDir, repo.cloneUrl);
      await github.enableActions(repo.repoName);
      await github.registerWebhook(repo.repoName);
      store.update(slug, {
        status: store.BuildStatus.BUILDING,
        repoUrl: repo.repoUrl,
      });
    } else {
      // No GitHub token — tenant dir created locally, mark as BUILDING
      // (operator must push manually to trigger CI)
      store.update(slug, {
        status: store.BuildStatus.BUILDING,
        repoUrl: null,
      });
      console.warn(`[provision] ${slug}: no GitHub token — push ${tenantDir} manually to trigger CI`);
    }
  } catch (err) {
    console.error(`[provision] ${slug} FAILED:`, err.message);
    store.update(slug, {
      status: store.BuildStatus.FAILED,
      error: err.message,
    });
  }
}

module.exports = { run };
