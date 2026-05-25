'use strict';

const fs = require('fs');
const path = require('path');

const STATE_FILE = process.env.STATE_FILE || path.join(__dirname, '..', 'provision-state.json');

// Build state machine
const BuildStatus = {
  PENDING: 'PENDING',
  PROVISIONING: 'PROVISIONING',
  BUILDING: 'BUILDING',
  READY: 'READY',
  FAILED: 'FAILED',
};

// In-memory store; flushed to disk on every write
let _records = {};

function _load() {
  try {
    if (fs.existsSync(STATE_FILE)) {
      _records = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    }
  } catch {
    _records = {};
  }
}

function _flush() {
  fs.writeFileSync(STATE_FILE, JSON.stringify(_records, null, 2), 'utf8');
}

_load();

function create(slug, data) {
  const record = {
    slug,
    businessId: data.businessId,
    name: data.name,
    packageId: data.packageId || `com.${slug}`,
    status: BuildStatus.PENDING,
    brandingStatus: 'PENDING',   // PENDING | DONE | FAILED
    firebaseStatus: 'STUB',      // STUB | CONFIGURED
    repoUrl: null,
    apkUrl: null,
    aabUrl: null,
    error: null,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  _records[slug] = record;
  _flush();
  return record;
}

function update(slug, patch) {
  if (!_records[slug]) throw new Error(`Tenant not found: ${slug}`);
  _records[slug] = { ..._records[slug], ...patch, updatedAt: new Date().toISOString() };
  _flush();
  return _records[slug];
}

function get(slug) {
  return _records[slug] || null;
}

function list() {
  return Object.values(_records).sort(
    (a, b) => new Date(b.createdAt) - new Date(a.createdAt),
  );
}

module.exports = { BuildStatus, create, update, get, list };
