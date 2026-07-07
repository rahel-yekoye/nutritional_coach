const test = require('node:test');
const assert = require('node:assert/strict');
const User = require('../models/User');

test('user schema validates core required fields', () => {
  const user = new User({
    fullName: 'Ada Lovelace',
    email: 'ada@example.com',
    password: 'mypassword123',
  });

  const error = user.validateSync();
  assert.equal(error, undefined);
  assert.equal(user.email, 'ada@example.com');
});

test('user schema rejects invalid blood type values', () => {
  const user = new User({
    fullName: 'Grace Hopper',
    email: 'grace@example.com',
    password: 'mypassword123',
    bloodType: 'X+',
  });

  const error = user.validateSync();
  assert.ok(error);
  assert.match(error.errors.bloodType.message, /enum/i);
});
