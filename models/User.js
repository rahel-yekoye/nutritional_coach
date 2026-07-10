const mongoose = require('mongoose');

const bloodTypeValues = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const sexValues = ['male', 'female', 'other', 'prefer-not-to-say'];
const activityLevelValues = ['sedentary', 'light', 'moderate', 'active', 'very-active'];
const goalValues = ['lose-weight', 'maintain', 'gain-weight', 'build-muscle', 'improve-health'];

const userSchema = new mongoose.Schema({
  // Basic Auth Info
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

  // Setup Completion Tracking
  hasCompletedSetup: {
    type: Boolean,
    default: false,
    index: true, // Index for quick queries
  },
  setupCompletedAt: {
    type: Date,
  },

  // Profile Data (only set during setup)
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
  fastingMode: {
    type: Boolean,
    default: false,
  },
  
  // Optional Profile Data
  bloodType: {
    type: String,
    enum: bloodTypeValues,
  },
  profilePicture: {
    type: String,
    trim: true,
  },

  // System Fields
  emailVerified: {
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
  deviceInfo: [{
    deviceId: String,
    platform: String, // 'ios', 'android', 'web'
    lastUsed: Date,
  }],

  // User Preferences (stored server-side)
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

// Indexes for performance
userSchema.index({ email: 1 });
userSchema.index({ hasCompletedSetup: 1 });
userSchema.index({ lastLogin: -1 });

// Instance method to check if setup is required
userSchema.methods.needsSetup = function() {
  return !this.hasCompletedSetup;
};

// Instance method to mark setup as complete
userSchema.methods.completeSetup = function() {
  this.hasCompletedSetup = true;
  this.setupCompletedAt = new Date();
  return this.save();
};

// Instance method to get public profile (safe to send to frontend)
userSchema.methods.getPublicProfile = function() {
  return {
    id: this._id,
    fullName: this.fullName,
    email: this.email,
    hasCompletedSetup: this.hasCompletedSetup,
    age: this.age,
    sex: this.sex,
    height: this.height,
    weight: this.weight,
    activityLevel: this.activityLevel,
    goal: this.goal,
    fastingMode: this.fastingMode,
    bloodType: this.bloodType,
    profilePicture: this.profilePicture,
    settings: this.settings,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('User', userSchema);
