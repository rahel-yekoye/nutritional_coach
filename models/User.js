const mongoose = require('mongoose');

const bloodTypeValues = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const sexValues = ['male', 'female', 'other', 'prefer-not-to-say'];
const activityLevelValues = ['sedentary', 'light', 'moderate', 'active', 'very-active'];
const goalValues = ['lose-weight', 'maintain', 'gain-weight', 'build-muscle', 'improve-health'];

const userSchema = new mongoose.Schema({
  fullName: {
    type: String,
    trim: true,
    required: [true, 'fullName is required'],
    minlength: [2, 'fullName must be at least 2 characters'],
    maxlength: [100, 'fullName must not exceed 100 characters'],
  },
  email: {
    type: String,
    trim: true,
    lowercase: true,
    required: [true, 'email is required'],
    unique: true,
    match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, 'Please provide a valid email address'],
  },
  password: {
    type: String,
    required: [true, 'password is required'],
    minlength: [8, 'password must be at least 8 characters'],
  },
  age: {
    type: Number,
    min: [1, 'age must be at least 1'],
    max: [120, 'age must not exceed 120'],
  },
  sex: {
    type: String,
    enum: sexValues,
  },
  height: {
    type: Number,
    min: [50, 'height must be at least 50 cm'],
    max: [250, 'height must not exceed 250 cm'],
  },
  weight: {
    type: Number,
    min: [20, 'weight must be at least 20 kg'],
    max: [500, 'weight must not exceed 500 kg'],
  },
  activityLevel: {
    type: String,
    enum: activityLevelValues,
  },
  goal: {
    type: String,
    enum: goalValues,
  },
  bloodType: {
    type: String,
    enum: bloodTypeValues,
  },
  dailyCalories: {
    type: Number,
    min: [0, 'dailyCalories must be non-negative'],
  },
  dailyProtein: {
    type: Number,
    min: [0, 'dailyProtein must be non-negative'],
  },
  dailyFat: {
    type: Number,
    min: [0, 'dailyFat must be non-negative'],
  },
  dailyCarbs: {
    type: Number,
    min: [0, 'dailyCarbs must be non-negative'],
  },
  profilePicture: {
    type: String,
    trim: true,
  },
  emailVerified: {
    type: Boolean,
    default: false,
  },
  profileCompleted: {
    type: Boolean,
    default: false,
  },
  lastLogin: {
    type: Date,
  },
  appVersion: {
    type: String,
    trim: true,
  },
  device: {
    type: String,
    trim: true,
  },
  settings: {
    theme: {
      type: String,
      enum: ['light', 'dark', 'system'],
      default: 'system',
    },
    language: {
      type: String,
      default: 'en',
    },
    notifications: {
      type: Boolean,
      default: true,
    },
    measurementUnits: {
      type: String,
      enum: ['metric', 'imperial'],
      default: 'metric',
    },
  },
}, {
  timestamps: true,
});

userSchema.index({ fullName: 'text', email: 'text' });
userSchema.index({ profileCompleted: 1, bloodType: 1 });

module.exports = mongoose.model('User', userSchema);
