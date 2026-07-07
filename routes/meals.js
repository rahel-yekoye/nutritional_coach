const express = require('express');
const { createMealLog, listMealLogs, getMealSummary } = require('../controllers/mealController');
const protect = require('../middleware/auth');

const router = express.Router();

router.post('/', protect, createMealLog);
router.get('/', protect, listMealLogs);
router.get('/summary', protect, getMealSummary);

module.exports = router;
