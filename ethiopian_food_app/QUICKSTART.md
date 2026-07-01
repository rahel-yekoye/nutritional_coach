# Quick Start Guide

Get the Ethiopian Food Database mobile app running in 5 minutes!

## Prerequisites

- ✅ Flutter SDK installed
- ✅ Android Studio or Xcode (for testing)
- ✅ Ethiopian Food API running (from parent directory)

## Step 1: Start the API

```bash
# Navigate to API directory
cd ../

# Start the server
npm start
```

Verify API is running at `http://localhost:3000/health`

## Step 2: Install Dependencies

```bash
# Navigate back to app directory
cd ethiopian_food_app

# Install packages
flutter pub get
```

## Step 3: Configure API URL

For **local testing**, the default is already set to localhost.

For **Android emulator**, edit `lib/core/api/api_client.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:3000';
```

For **physical device**, use your computer's IP:
```dart
static const String baseUrl = 'http://192.168.1.xxx:3000';
```

## Step 4: Run the App

```bash
# Run on connected device/emulator
flutter run
```

That's it! 🎉

## Quick Test

1. **Search** for "barley" - Should show multiple results
2. **Tap a result** - Should show nutrition details
3. **Try autocomplete** - Type "wh" and see suggestions
4. **Browse categories** - Tap categories icon in app bar

## Troubleshooting

### Cannot connect to API

**Android Emulator**: Use `10.0.2.2` instead of `localhost`
```dart
static const String baseUrl = 'http://10.0.2.2:3000';
```

**Physical Device**: Use your computer's IP address
```bash
# Find your IP
ipconfig  # Windows
ifconfig  # Mac/Linux
```

### Dependencies not installing

```bash
# Clean and reinstall
flutter clean
flutter pub get
```

### Build errors

```bash
# Update Flutter
flutter upgrade

# Rebuild
flutter clean
flutter pub get
flutter run
```

## Next Steps

- Read the full [README.md](README.md) for detailed features
- Check [API_DOCUMENTATION.md](../API_DOCUMENTATION.md) for API details
- Explore the compare feature
- Try the random food button

---

Need help? Check the API health endpoint: `http://localhost:3000/health`
