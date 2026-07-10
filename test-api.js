/**
 * Quick API Test Suite
 * Tests all endpoints to verify production readiness
 */

const http = require('http');

const BASE_URL = 'https://nutritional-coach.onrender.com';

// Color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
};

// Make HTTP request helper
function makeRequest(path) {
  return new Promise((resolve, reject) => {
    const url = `${BASE_URL}${path}`;
    http.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve({
            status: res.statusCode,
            data: JSON.parse(data),
            headers: res.headers,
          });
        } catch (error) {
          reject(error);
        }
      });
    }).on('error', reject);
  });
}

// Test runner
async function runTest(name, path, validator) {
  try {
    const start = Date.now();
    const response = await makeRequest(path);
    const duration = Date.now() - start;

    if (validator(response)) {
      console.log(`${colors.green}✓${colors.reset} ${name} (${duration}ms)`);
      return true;
    } else {
      console.log(`${colors.red}✗${colors.reset} ${name} - Validation failed`);
      return false;
    }
  } catch (error) {
    console.log(`${colors.red}✗${colors.reset} ${name} - Error: ${error.message}`);
    return false;
  }
}

// Main test suite
async function runTests() {
  console.log(`\n${colors.cyan}==========================================================`);
  console.log('Ethiopian Food Database API - Test Suite');
  console.log(`==========================================================${colors.reset}\n`);

  const tests = [];

  // Test 1: Root endpoint
  tests.push(
    runTest('Root endpoint', '/', (res) => {
      return res.status === 200 && res.data.name && res.data.endpoints;
    })
  );

  // Test 2: Health check
  tests.push(
    runTest('Health check', '/health', (res) => {
      return res.status === 200 && res.data.status === 'healthy';
    })
  );

  // Test 3: Search endpoint
  tests.push(
    runTest('Search endpoint', '/search?q=barley&limit=5', (res) => {
      return res.status === 200 && res.data.results && res.data.results.length > 0;
    })
  );

  // Test 4: Search caching
  tests.push(
    runTest('Search caching', '/search?q=barley&limit=5', (res) => {
      return res.status === 200 && res.data.cached === true;
    })
  );

  // Test 5: Food details
  tests.push(
    runTest('Food details', '/food/010007', (res) => {
      return res.status === 200 && res.data.food_code === '010007' && res.data.nutrition;
    })
  );

  // Test 6: Suggest endpoint
  tests.push(
    runTest('Suggest endpoint', '/suggest?q=wh', (res) => {
      return res.status === 200 && res.data.suggestions && res.data.suggestions.length > 0;
    })
  );

  // Test 7: Keyword suggestions
  tests.push(
    runTest('Keyword suggestions', '/suggest/keywords?q=ce', (res) => {
      return res.status === 200 && res.data.keywords && res.data.keywords.length > 0;
    })
  );

  // Test 8: Categories list
  tests.push(
    runTest('Categories list', '/suggest/categories', (res) => {
      return res.status === 200 && res.data.categories && res.data.categories.length > 0;
    })
  );

  // Test 9: 404 handling
  tests.push(
    runTest('404 handling', '/nonexistent', (res) => {
      return res.status === 404 && res.data.error;
    })
  );

  // Test 10: Invalid query handling
  tests.push(
    runTest('Invalid query handling', '/search', (res) => {
      return res.status === 400 && res.data.error;
    })
  );

  // Wait for all tests to complete
  const results = await Promise.all(tests);
  const passed = results.filter(r => r).length;
  const total = results.length;

  console.log(`\n${colors.cyan}==========================================================`);
  console.log(`Test Results: ${passed}/${total} passed`);
  console.log(`==========================================================${colors.reset}\n`);

  if (passed === total) {
    console.log(`${colors.green}✓ All tests passed! API is production-ready!${colors.reset}\n`);
    process.exit(0);
  } else {
    console.log(`${colors.red}✗ Some tests failed. Please review the errors above.${colors.reset}\n`);
    process.exit(1);
  }
}

// Check if server is running
async function checkServer() {
  try {
    await makeRequest('/health');
    return true;
  } catch (error) {
    return false;
  }
}

// Main execution
(async () => {
  console.log(`${colors.yellow}Checking if server is running...${colors.reset}`);
  
  const isRunning = await checkServer();
  
  if (!isRunning) {
    console.log(`${colors.red}✗ Server is not running at ${BASE_URL}${colors.reset}`);
    console.log(`${colors.yellow}Please start the server first: npm start${colors.reset}\n`);
    process.exit(1);
  }

  console.log(`${colors.green}✓ Server is running${colors.reset}`);
  
  await runTests();
})();
