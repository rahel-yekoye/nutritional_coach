const mongoose = require('mongoose');

const mealLogSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  foodCode: {
    type: String,
    trim: true,
    required: true,
  },
  foodName: {
    type: String,
    trim: true,
    required: true,
  },
  mealType: {
    type: String,
    enum: ['breakfast', 'lunch', 'dinner', 'snack', 'drink'],
    default: 'breakfast',
  },
  portionGrams: {
    type: Number,
    min: [1, 'portionGrams must be at least 1'],
  },
  calories: {
    type: Number,
    min: [0, 'calories must be non-negative'],
  },
  protein: {
    type: Number,
    min: [0, 'protein must be non-negative'],
  },
  fat: {
    type: Number,
    min: [0, 'fat must be non-negative'],
  },
  carbs: {
    type: Number,
    min: [0, 'carbs must be non-negative'],
  },
  notes: {
    type: String,
    trim: true,
    maxlength: [500, 'notes must not exceed 500 characters'],
  },
  consumedAt: {
    type: Date,
    default: Date.now,
  },
}, {
  timestamps: true,
});

mealLogSchema.index({ userId: 1, consumedAt: -1 });

module.exports = mongoose.model('MealLog', mealLogSchema);
