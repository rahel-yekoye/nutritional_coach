import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiopian_food_app/core/providers/providers.dart';
import 'package:ethiopian_food_app/core/router/app_router.dart';

class EthiopianFoodApp extends ConsumerWidget {
  const EthiopianFoodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Ethiopian Food Database',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
          surfaceDim: const Color(0xFF1a1a1a),
          surfaceContainer: const Color(0xFF2d2d2d),
          surfaceContainerHigh: const Color(0xFF3a3a3a),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1e1e1e),
        cardTheme: CardTheme(
          elevation: 0,
          color: const Color(0xFF1e1e1e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: const Color(0xFF121212),
          foregroundColor: Colors.white,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
