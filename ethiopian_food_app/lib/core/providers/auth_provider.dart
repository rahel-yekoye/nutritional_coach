import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/nutrition_service.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/nutrition_provider.dart';
import '../../core/models/user_profile.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(profileServiceProvider),
    ref.watch(nutritionServiceProvider),
    ref,
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  final AuthService _authService;
  final ProfileService _profileService;
  final NutritionService _nutritionService;
  final Ref _ref;

  AuthNotifier(
    this._authService,
    this._profileService,
    this._nutritionService,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    _init();
  }

  void _refreshUserScopedProviders() {
    _ref.invalidate(profileProvider);
    _ref.invalidate(nutritionLogsProvider);
  }

  Future<void> _init() async {
    try {
      if (_authService.isAuthenticated) {
        final user = await _authService.fetchCurrentUser();
        if (user != null) {
          await _initUserServices(user.id);

          if (!user.needsSetup && user.age != null) {
            await _createLocalProfileFromUser(user);
          }

          _refreshUserScopedProviders();
        }
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _createLocalProfileFromUser(AuthUser user) async {
    try {
      debugPrint('[bloodType] _createLocalProfileFromUser input: ${user.bloodType}');
      if (!_profileService.hasProfile()) {
        final profile = UserProfile(
          age: user.age ?? 25,
          gender: _parseGender(user.sex ?? 'male'),
          height: user.height ?? 170,
          weight: user.weight ?? 70,
          activityLevel: _parseActivityLevel(user.activityLevel ?? 'moderate'),
          goal: _parseGoal(user.goal ?? 'maintain'),
          bloodGroup: _parseBloodGroup(user.bloodType),
          fastingMode: user.fastingMode ?? false,
          createdAt: user.createdAt ?? DateTime.now(),
          updatedAt: user.updatedAt ?? DateTime.now(),
        );

        await _profileService.saveProfile(profile);
        debugPrint('[bloodType] Hive save: ${profile.bloodGroup.displayName}');
      }
    } catch (e) {
      print('❌ Error creating local profile: $e');
    }
  }

  BloodGroup _parseBloodGroup(String? bloodType) {
    if (bloodType == null) return BloodGroup.oPositive; // Keep existing default
    
    switch (bloodType.toUpperCase()) {
      case 'A+':
        return BloodGroup.aPositive;
      case 'A-':
        return BloodGroup.aNegative;
      case 'B+':
        return BloodGroup.bPositive;
      case 'B-':
        return BloodGroup.bNegative;
      case 'AB+':
        return BloodGroup.abPositive;
      case 'AB-':
        return BloodGroup.abNegative;
      case 'O+':
        return BloodGroup.oPositive;
      case 'O-':
        return BloodGroup.oNegative;
      default:
        return BloodGroup.oPositive; // Default fallback
    }
  }

  Gender _parseGender(String sex) {
    switch (sex.toLowerCase()) {
      case 'female':
        return Gender.female;
      case 'other':
        return Gender.other;
      default:
        return Gender.male;
    }
  }

  ActivityLevel _parseActivityLevel(String level) {
    switch (level.toLowerCase().replaceAll('-', '')) {
      case 'sedentary':
        return ActivityLevel.sedentary;
      case 'light':
        return ActivityLevel.light;
      case 'veryactive':
        return ActivityLevel.veryActive;
      default:
        return ActivityLevel.moderate;
    }
  }

  NutritionGoal _parseGoal(String goal) {
    switch (goal.toLowerCase().replaceAll('-', '')) {
      case 'loseweight':
        return NutritionGoal.loseWeight;
      case 'gainweight':
        return NutritionGoal.gainWeight;
      case 'buildmuscle':
        return NutritionGoal.buildMuscle;
      case 'healthyeating':
        return NutritionGoal.healthyEating;
      default:
        return NutritionGoal.maintain;
    }
  }

  Future<void> _initUserServices(String userId) async {
    await _profileService.init(userId);
    await _nutritionService.init(userId);
  }

  Future<void> login(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final session = await _authService.login(email, password);
      await _initUserServices(session.user.id);

      if (!session.user.needsSetup && session.user.age != null) {
        await _createLocalProfileFromUser(session.user);
      }

      state = AsyncValue.data(session.user);
      _refreshUserScopedProviders();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> register(String fullName, String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final session = await _authService.register(fullName, email, password);
      await _initUserServices(session.user.id);
      state = AsyncValue.data(session.user);
      _refreshUserScopedProviders();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> logout() async {
    try {
      await _profileService.clearAllData();
      await _nutritionService.clearAllLogs();

      await _profileService.close();
      await _nutritionService.close();

      await _authService.logout();

      state = const AsyncValue.data(null);
      _refreshUserScopedProviders();
    } catch (e, stack) {
      await _authService.logout();
      state = AsyncValue.error(e, stack);
      _refreshUserScopedProviders();
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await _authService.fetchCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> completeSetup({
    required int age,
    required String sex,
    required double height,
    required double weight,
    required String activityLevel,
    required String goal,
    bool fastingMode = false,
    String? bloodType,
  }) async {
    try {
      state = const AsyncValue.loading();
      final session = await _authService.completeSetup(
        age: age,
        sex: sex,
        height: height,
        weight: weight,
        activityLevel: activityLevel,
        goal: goal,
        fastingMode: fastingMode,
        bloodType: bloodType,
      );
      await _initUserServices(session.user.id);
      state = AsyncValue.data(session.user);
      _refreshUserScopedProviders();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
