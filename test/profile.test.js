const test = require('node:test');
const assert = require('node:assert/strict');
const profileController = require('../controllers/profileController');

test('profile controller exposes get and update handlers', () => {
  assert.equal(typeof profileController.getProfile, 'function');
  assert.equal(typeof profileController.updateProfile, 'function');
});
