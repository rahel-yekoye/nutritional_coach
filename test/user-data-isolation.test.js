const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const app = require('../server');
const User = require('../models/User');
const MealLog = require('../models/MealLog');

function request(server, method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const payload = body ? JSON.stringify(body) : null;
    const options = {
      hostname: 'localhost',
      port: server.address().port,
      path,
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          resolve({
            statusCode: res.statusCode,
            body: JSON.parse(data || '{}'),
          });
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

test('CRITICAL: User data isolation - users cannot see each other\'s data', async () => {
  console.log('🔒 Testing user data isolation...');

  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));

  try {
    const timestamp = Date.now();
    
    // User A registration
    const userAEmail = `usera-${timestamp}@example.com`;
    const userARes = await request(server, 'POST', '/api/v1/auth/register', {
      fullName: 'User A Test',
      email: userAEmail,
      password: 'Password123!',
    });

    assert.equal(userARes.statusCode, 201, 'User A registration should succeed');
    const userAId = userARes.body.data.user.id;
    const userAToken = userARes.body.data.token;
    console.log(`✅ User A registered: ${userAId}`);

    // User B registration
    const userBEmail = `userb-${timestamp}@example.com`;
    const userBRes = await request(server, 'POST', '/api/v1/auth/register', {
      fullName: 'User B Test',
      email: userBEmail,
      password: 'Password123!',
    });

    assert.equal(userBRes.statusCode, 201, 'User B registration should succeed');
    const userBId = userBRes.body.data.user.id;
    const userBToken = userBRes.body.data.token;
    console.log(`✅ User B registered: ${userBId}`);

    // Ensure users have different IDs
    assert.notEqual(userAId, userBId, 'Users should have different IDs');

    // User A updates profile
    const userAProfileUpdate = await request(server, 'PUT', '/api/v1/profile', {
      fullName: 'User A Updated',
      age: 30,
      weight: 70,
    }, userAToken);

    assert.equal(userAProfileUpdate.statusCode, 200, 'User A profile update should succeed');
    console.log(`✅ User A profile updated`);

    // User B updates profile with different data
    const userBProfileUpdate = await request(server, 'PUT', '/api/v1/profile', {
      fullName: 'User B Updated',
      age: 25,
      weight: 65,
    }, userBToken);

    assert.equal(userBProfileUpdate.statusCode, 200, 'User B profile update should succeed');
    console.log(`✅ User B profile updated`);

    // User A creates meal logs
    const userAMeal1 = await request(server, 'POST', '/api/v1/meals', {
      foodCode: 'F001001',
      foodName: 'User A Food 1',
      calories: 200,
      protein: 10,
    }, userAToken);

    const userAMeal2 = await request(server, 'POST', '/api/v1/meals', {
      foodCode: 'F001002',
      foodName: 'User A Food 2',
      calories: 150,
      protein: 8,
    }, userAToken);

    assert.equal(userAMeal1.statusCode, 201, 'User A meal 1 should be created');
    assert.equal(userAMeal2.statusCode, 201, 'User A meal 2 should be created');
    console.log(`✅ User A created 2 meal logs`);

    // User B creates meal logs
    const userBMeal1 = await request(server, 'POST', '/api/v1/meals', {
      foodCode: 'F002001',
      foodName: 'User B Food 1',
      calories: 300,
      protein: 15,
    }, userBToken);

    assert.equal(userBMeal1.statusCode, 201, 'User B meal 1 should be created');
    console.log(`✅ User B created 1 meal log`);

    // CRITICAL TEST 1: User A should only see their own profile
    const userAProfileGet = await request(server, 'GET', '/api/v1/profile', null, userAToken);
    assert.equal(userAProfileGet.statusCode, 200, 'User A should get their profile');
    assert.equal(userAProfileGet.body.data.user.fullName, 'User A Updated');
    assert.equal(userAProfileGet.body.data.user.age, 30);
    assert.equal(userAProfileGet.body.data.user.weight, 70);
    console.log(`✅ User A sees correct profile data`);

    // CRITICAL TEST 2: User B should only see their own profile
    const userBProfileGet = await request(server, 'GET', '/api/v1/profile', null, userBToken);
    assert.equal(userBProfileGet.statusCode, 200, 'User B should get their profile');
    assert.equal(userBProfileGet.body.data.user.fullName, 'User B Updated');
    assert.equal(userBProfileGet.body.data.user.age, 25);
    assert.equal(userBProfileGet.body.data.user.weight, 65);
    console.log(`✅ User B sees correct profile data`);

    // CRITICAL TEST 3: User A should only see their own meal logs
    const userAMeals = await request(server, 'GET', '/api/v1/meals', null, userAToken);
    assert.equal(userAMeals.statusCode, 200, 'User A should get their meals');
    assert.equal(userAMeals.body.data.count, 2, 'User A should have 2 meals');
    
    const userAFoodNames = userAMeals.body.data.meals.map(m => m.foodName);
    assert.ok(userAFoodNames.includes('User A Food 1'), 'User A should see their food 1');
    assert.ok(userAFoodNames.includes('User A Food 2'), 'User A should see their food 2');
    assert.ok(!userAFoodNames.includes('User B Food 1'), 'User A should NOT see User B food');
    console.log(`✅ User A sees only their meal logs (2 items)`);

    // CRITICAL TEST 4: User B should only see their own meal logs
    const userBMeals = await request(server, 'GET', '/api/v1/meals', null, userBToken);
    assert.equal(userBMeals.statusCode, 200, 'User B should get their meals');
    assert.equal(userBMeals.body.data.count, 1, 'User B should have 1 meal');
    
    const userBFoodNames = userBMeals.body.data.meals.map(m => m.foodName);
    assert.ok(userBFoodNames.includes('User B Food 1'), 'User B should see their food');
    assert.ok(!userBFoodNames.includes('User A Food 1'), 'User B should NOT see User A food 1');
    assert.ok(!userBFoodNames.includes('User A Food 2'), 'User B should NOT see User A food 2');
    console.log(`✅ User B sees only their meal logs (1 item)`);

    // CRITICAL TEST 5: User A meal summary should only include their data
    const userASummary = await request(server, 'GET', '/api/v1/meals/summary', null, userAToken);
    assert.equal(userASummary.statusCode, 200, 'User A should get their summary');
    assert.equal(userASummary.body.data.summary.totalCalories, 350, 'User A total calories should be 350');
    assert.equal(userASummary.body.data.summary.totalProtein, 18, 'User A total protein should be 18');
    assert.equal(userASummary.body.data.summary.totalMeals, 2, 'User A should have 2 meals');
    console.log(`✅ User A summary: ${userASummary.body.data.summary.totalCalories} cal, ${userASummary.body.data.summary.totalMeals} meals`);

    // CRITICAL TEST 6: User B meal summary should only include their data
    const userBSummary = await request(server, 'GET', '/api/v1/meals/summary', null, userBToken);
    assert.equal(userBSummary.statusCode, 200, 'User B should get their summary');
    assert.equal(userBSummary.body.data.summary.totalCalories, 300, 'User B total calories should be 300');
    assert.equal(userBSummary.body.data.summary.totalProtein, 15, 'User B total protein should be 15');
    assert.equal(userBSummary.body.data.summary.totalMeals, 1, 'User B should have 1 meal');
    console.log(`✅ User B summary: ${userBSummary.body.data.summary.totalCalories} cal, ${userBSummary.body.data.summary.totalMeals} meals`);

    // CRITICAL TEST 7: Invalid token should be rejected
    const invalidTokenRes = await request(server, 'GET', '/api/v1/profile', null, 'invalid-token');
    assert.equal(invalidTokenRes.statusCode, 401, 'Invalid token should be rejected');
    console.log(`✅ Invalid token properly rejected`);

    // CRITICAL TEST 8: User A token should return User A's data
    const crossUserAttempt = await request(server, 'GET', '/api/v1/me', null, userAToken);
    assert.equal(crossUserAttempt.statusCode, 200, 'User A token should work for their own data');
    
    // Debug: Log the response structure
    console.log('API Response:', JSON.stringify(crossUserAttempt.body, null, 2));
    
    const returnedUserId = crossUserAttempt.body.data?.user?.id || crossUserAttempt.body.data?.user?._id;
    assert.ok(returnedUserId, 'Should return user data with ID');
    assert.equal(returnedUserId.toString(), userAId.toString(), 'Should return User A data');
    assert.notEqual(returnedUserId.toString(), userBId.toString(), 'Should NOT return User B data');
    console.log(`✅ User A token returns correct user data: ${returnedUserId}`);

    // DATABASE VERIFICATION: Check that data is correctly isolated in the database
    const userAFromDB = await User.findById(userAId);
    const userBFromDB = await User.findById(userBId);
    
    assert.equal(userAFromDB.fullName, 'User A Updated', 'User A data should be correct in DB');
    assert.equal(userBFromDB.fullName, 'User B Updated', 'User B data should be correct in DB');
    
    const userAMealsFromDB = await MealLog.find({ userId: userAId });
    const userBMealsFromDB = await MealLog.find({ userId: userBId });
    
    assert.equal(userAMealsFromDB.length, 2, 'User A should have 2 meals in DB');
    assert.equal(userBMealsFromDB.length, 1, 'User B should have 1 meal in DB');
    console.log(`✅ Database isolation verified`);

    // Cleanup
    await User.findByIdAndDelete(userAId);
    await User.findByIdAndDelete(userBId);
    await MealLog.deleteMany({ userId: userAId });
    await MealLog.deleteMany({ userId: userBId });

    console.log('🎉 ALL USER DATA ISOLATION TESTS PASSED!');

  } finally {
    await new Promise((resolve, reject) => server.close((err) => (err ? reject(err) : resolve())));
  }
});

test('CRITICAL: User re-login should restore their own data, not others', async () => {
  console.log('🔄 Testing user re-login data isolation...');

  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));

  try {
    const timestamp = Date.now();
    
    // Register and create data for User A
    const userAEmail = `relogin-usera-${timestamp}@example.com`;
    const userARes = await request(server, 'POST', '/api/v1/auth/register', {
      fullName: 'Relogin User A',
      email: userAEmail,
      password: 'Password123!',
    });

    const userAId = userARes.body.data.user.id;
    const userAToken = userARes.body.data.token;

    // Create meal for User A
    await request(server, 'POST', '/api/v1/meals', {
      foodCode: 'F003001',
      foodName: 'User A Unique Food',
      calories: 400,
      protein: 20,
    }, userAToken);

    // Register User B and create different data
    const userBEmail = `relogin-userb-${timestamp}@example.com`;
    const userBRes = await request(server, 'POST', '/api/v1/auth/register', {
      fullName: 'Relogin User B',
      email: userBEmail,
      password: 'Password123!',
    });

    const userBId = userBRes.body.data.user.id;
    const userBToken = userBRes.body.data.token;

    // Create meal for User B
    await request(server, 'POST', '/api/v1/meals', {
      foodCode: 'F003002',
      foodName: 'User B Unique Food',
      calories: 250,
      protein: 12,
    }, userBToken);

    // Simulate User A re-login
    const userARelogin = await request(server, 'POST', '/api/v1/auth/login', {
      email: userAEmail,
      password: 'Password123!',
    });

    assert.equal(userARelogin.statusCode, 200, 'User A should be able to re-login');
    const userANewToken = userARelogin.body.data.token;
    
    // Verify User A gets their own data after re-login
    const userADataAfterRelogin = await request(server, 'GET', '/api/v1/meals', null, userANewToken);
    assert.equal(userADataAfterRelogin.statusCode, 200, 'User A should get their data after re-login');
    assert.equal(userADataAfterRelogin.body.data.count, 1, 'User A should have their 1 meal');
    
    const foodName = userADataAfterRelogin.body.data.meals[0].foodName;
    assert.equal(foodName, 'User A Unique Food', 'User A should see their own food');
    assert.notEqual(foodName, 'User B Unique Food', 'User A should NOT see User B food');

    console.log(`✅ User A re-login works correctly, sees only their data`);

    // Cleanup
    await User.findByIdAndDelete(userAId);
    await User.findByIdAndDelete(userBId);
    await MealLog.deleteMany({ userId: userAId });
    await MealLog.deleteMany({ userId: userBId });

    console.log('🎉 RE-LOGIN DATA ISOLATION TEST PASSED!');

  } finally {
    await new Promise((resolve, reject) => server.close((err) => (err ? reject(err) : resolve())));
  }
});