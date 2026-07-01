import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ethiopian_food_app/app.dart';
import 'package:ethiopian_food_app/core/providers/providers.dart';
import 'package:ethiopian_food_app/core/hive_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  // await HiveSetup.clearAllData(); // Uncomment to reset data once if schema issues persist
  await HiveSetup.init();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const EthiopianFoodApp(),
    ),
  );
}
