const test = require('node:test');
const assert = require('node:assert/strict');
const config = require('../config');

test('config exposes database settings with safe defaults', () => {
  assert.ok(config.db, 'db config should exist');
  assert.equal(typeof config.db.uri, 'string');
  assert.equal(config.db.uri, process.env.MONGODB_URI || '');
  assert.equal(typeof config.db.options, 'object');
});
