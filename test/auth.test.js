const test = require('node:test');
const assert = require('node:assert/strict');
const { signToken } = require('../utils/jwt');

test('jwt helper creates a signed token', () => {
  const token = signToken({ id: '123', email: 'test@example.com' });
  assert.equal(typeof token, 'string');
  assert.ok(token.length > 20);
});
