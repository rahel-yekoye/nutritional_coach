const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const app = require('../server');
const MealLog = require('../models/MealLog');

function request(app, method, path, body, token) {
  return new Promise((resolve, reject) => {
    const payload = body ? JSON.stringify(body) : undefined;
    const req = http.request(
      {
        hostname: '127.0.0.1',
        port: app.address().port,
        path,
        method,
        headers: {
          'Content-Type': 'application/json',
          ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
      },
      (res) => {
        let data = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => {
          data += chunk;
        });
        res.on('end', () => {
          resolve({ statusCode: res.statusCode, body: data ? JSON.parse(data) : null });
        });
      }
    );

    req.on('error', reject);
    if (payload) {
      req.write(payload);
    }
    req.end();
  });
}

test('authenticated users can create and list meal logs', async () => {
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));

  try {
    const email = `mealtest-${Date.now()}@example.com`;
    const registerRes = await request(server, 'POST', '/api/v1/auth/register', {
      fullName: 'Meal Test User',
      email,
      password: 'Password123!',
    });

    assert.equal(registerRes.statusCode, 201);
    const token = registerRes.body.data.token;

    const createRes = await request(server, 'POST', '/api/v1/meals', {
      foodCode: '010007',
      foodName: 'Teff Injera',
      mealType: 'breakfast',
      portionGrams: 180,
      calories: 220,
      protein: 7,
      fat: 2,
      carbs: 45,
      consumedAt: new Date().toISOString(),
    }, token);

    assert.equal(createRes.statusCode, 201);
    assert.equal(createRes.body.success, true);
    assert.equal(createRes.body.data.meal.foodName, 'Teff Injera');

    const listRes = await request(server, 'GET', '/api/v1/meals?limit=10', undefined, token);
    assert.equal(listRes.statusCode, 200);
    assert.equal(listRes.body.success, true);
    assert.ok(listRes.body.data.meals.length >= 1);

    const summaryRes = await request(server, 'GET', '/api/v1/meals/summary', undefined, token);
    assert.equal(summaryRes.statusCode, 200);
    assert.equal(summaryRes.body.success, true);
    assert.ok(summaryRes.body.data.summary.totalCalories >= 220);

    const userId = registerRes.body.data.user.id;
    await MealLog.deleteMany({ userId });
  } finally {
    await new Promise((resolve, reject) => server.close((err) => (err ? reject(err) : resolve())));
  }
});
