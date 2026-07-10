# Ethiopian Food Database - Mobile App

A production-ready Flutter mobile application for searching and exploring the Ethiopian Food Composition Table with intelligent search, autocomplete, and nutritional comparison features.

## Features

### 🔍 Smart Search
- **Google-like search bar** with clean, minimal design
- **Real-time autocomplete** suggestions (debounced 200ms)
- **Intelligent ranking** with match type badges
  - EXACT (green) - Exact name match
  - NAME (blue) - Name contains query
  - KEYWORD (orange) - Keyword match
  - CATEGORY (grey) - Category match
- **LRU caching** - Last 20 searches cached locally
- **Debounced search** - 300ms debounce for smooth UX

### 🍽️ Food Details
- **Complete nutritional information** per 100g
  - Energy (kcal)
  - Protein (g)
  - Fat (g)
  - Carbohydrates (g)
  - Fiber (g)
  - Water (g)
- **Bilingual display** - English and Amharic names
- **Category information**
- **Keywords as chips**
- **Beautiful gradient cards**

### 📊 Categories Browser
- **17 food categories** with counts
- **Color-coded cards** with icons
- **Quick category filtering**

### ⚖️ Compare Foods (Bonus)
- **Side-by-side comparison** of two foods
- **Visual indicators** for better values
- **Winner highlights** for each nutrient
- **Smart comparison** (higher protein is better, lower calories is better)

### 🎲 Random Food (Bonus)
- **"What can I eat?"** button
- Returns random food from search results
- Great for meal inspiration

## Architecture

```
lib/
├── main.dart                      # App entry point
├── app.dart                       # Main app widget
├── core/
│   ├── api/
│   │   ├── api_client.dart        # HTTP client with error handling
│   │   └── food_service.dart      # API service layer
│   ├── cache/
│   │   └── search_cache.dart      # LRU cache implementation
│   ├── models/
│   │   └── food_model.dart        # Data models
│   ├── providers/
│   │   └── providers.dart         # Riverpod providers
│   └── router/
│       └── app_router.dart        # GoRouter configuration
├── features/
│   ├── search/
│   │   ├── search_screen.dart     # Main search UI
│   │   └── search_controller.dart # Search state management
│   ├── food_detail/
│   │   └── food_detail_screen.dart# Food details UI
│   ├── categories/
│   │   └── categories_screen.dart # Categories browser
│   └── compare/
│       └── compare_screen.dart    # Food comparison
└── widgets/
    ├── food_card.dart             # Search result card
    ├── nutrition_card.dart        # Nutrition display card
    ├── match_badge.dart           # Match type badge
    └── loading_skeleton.dart      # Loading animations
```

## Tech Stack

- **Flutter 3.27.4** - UI framework
- **Dart 3.6.2** - Programming language
- **flutter_riverpod 2.6.1** - State management
- **go_router 14.6.2** - Navigation
- **http 1.2.2** - API calls
- **shared_preferences 2.3.3** - Local caching
- **equatable 2.0.7** - Value equality

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / Xcode (for device testing)
- Running Ethiopian Food API (see API setup below)

### Installation

1. **Clone the repository**
   ```bash
   cd ethiopian_food_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API URL**
   
   Edit `lib/core/api/api_client.dart`:
   ```dart
   static const String baseUrl = 'http://your-api-url.com';
   ```

   For local testing:
   ```dart
   static const String baseUrl = 'http://10.0.2.2:3000'; // Android emulator
   // OR
   static const String baseUrl = 'https://nutritional-coach.onrender.com'; // iOS simulator
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## API Configuration

The app connects to the Ethiopian Food Database API. You need to:

1. **Start the API server** (from parent directory):
   ```bash
   cd ../
   npm start
   ```

2. **Update API URL** based on your setup:
   - **Local Development**:
     - Android Emulator: `http://10.0.2.2:3000`
     - iOS Simulator: `https://nutritional-coach.onrender.com`
     - Physical Device: `http://your-computer-ip:3000`
   
   - **Production**:
     - Use your deployed API URL: `https://your-domain.com`

## Features in Detail

### Search Flow
1. User types in search bar
2. Autocomplete suggestions appear (200ms debounce)
3. Search executes (300ms debounce)
4. Check local cache first
5. If not cached, fetch from API
6. Display results with match badges
7. Cache results for future searches

### Cache Strategy
- **LRU (Least Recently Used)** eviction
- **20 query capacity** - configurable
- **Stored in SharedPreferences**
- **Instant cache hits** - no API call needed
- **Stats available** via cache.getStats()

### Performance Optimizations
- ✅ **Debounced input** - Reduces API calls
- ✅ **LRU caching** - Instant results for repeated queries
- ✅ **ListView.builder** - Efficient list rendering
- ✅ **Const widgets** - Reduced rebuilds
- ✅ **FutureProvider** - Automatic caching with Riverpod
- ✅ **Shimmer loading** - Smooth loading states

### Error Handling
- **Network errors** - Retry button with clear message
- **Timeout handling** - 10 second timeout
- **404 errors** - "Resource not found" message
- **429 errors** - "Too many requests" message
- **500 errors** - "Server error" message

## Usage Examples

### Search for Food
```dart
// Navigate to search (default screen)
context.go('/');

// Programmatic search
ref.read(searchControllerProvider.notifier).search('barley');
```

### View Food Details
```dart
// Navigate to food details
context.push('/food/010007');
```

### Compare Two Foods
```dart
// Navigate to comparison
context.push('/compare/010007/010010');
```

### Get Categories
```dart
// Navigate to categories
context.push('/categories');
```

## Customization

### Change Theme
Edit `lib/app.dart`:
```dart
theme: ThemeData(
  primarySwatch: Colors.blue, // Change primary color
  useMaterial3: true,
),
```

### Adjust Cache Size
Edit `lib/core/cache/search_cache.dart`:
```dart
static const int _maxCacheSize = 50; // Increase cache size
```

### Change Debounce Duration
Edit `lib/features/search/search_controller.dart`:
```dart
_debounceTimer = Timer(const Duration(milliseconds: 500), () {
  // Increase to 500ms
});
```

## Testing

### Run on Emulator
```bash
# Android
flutter run

# iOS
flutter run -d ios
```

### Run on Physical Device
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

### Debug Mode
- Hot reload: Press `r`
- Hot restart: Press `R`
- Open DevTools: Press `w`

## Building for Production

### Android APK
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS IPA
```bash
flutter build ios --release
```

Then archive in Xcode.

## Troubleshooting

### API Connection Issues

**Problem**: "Network error" or timeout
```
Solution: Check API is running and URL is correct
- For Android emulator: Use 10.0.2.2 instead of localhost
- For physical device: Use computer's IP address
- Check firewall settings
```

### Cache Not Working

**Problem**: Cached searches not loading
```
Solution: Clear app data and restart
- Android: Settings → Apps → Ethiopian Food → Clear Data
- iOS: Delete app and reinstall
```

### Slow Performance

**Problem**: App feels sluggish
```
Solution:
- Run in release mode: flutter run --release
- Check network connection
- Increase debounce duration
- Reduce cache size
```

## Project Structure

### Core Layer
- **api/** - API client and service
- **cache/** - Local caching logic
- **models/** - Data models
- **providers/** - Riverpod providers
- **router/** - Navigation configuration

### Features Layer
- **search/** - Search functionality
- **food_detail/** - Food details view
- **categories/** - Category browser
- **compare/** - Food comparison

### Widgets Layer
- Reusable UI components
- Loading states
- Custom cards and badges

## API Endpoints Used

- `GET /search?q={query}` - Search foods
- `GET /suggest?q={query}` - Get autocomplete
- `GET /food/{code}` - Get food details
- `GET /suggest/categories` - Get all categories

## Performance Metrics

- **Cold start**: ~1-2 seconds
- **Search (uncached)**: ~100-500ms
- **Search (cached)**: <10ms
- **Food details**: ~50-200ms
- **Memory usage**: ~50-100MB

## Future Enhancements

- [ ] Offline mode with full database
- [ ] Favorites / bookmarks
- [ ] Meal planning feature
- [ ] Barcode scanner
- [ ] Recipe suggestions
- [ ] Share food information
- [ ] Dark mode
- [ ] Multi-language support
- [ ] Voice search
- [ ] Filter by nutrients

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

This project is part of the Ethiopian Food Composition Table initiative.

## Support

For issues or questions:
- Check API is running: `https://nutritional-coach.onrender.com/health`
- Review API logs
- Check network connectivity
- Verify API URL configuration

---

**Built with ❤️ using Flutter**
