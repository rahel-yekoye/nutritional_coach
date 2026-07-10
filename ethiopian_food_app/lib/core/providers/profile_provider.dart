import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiopian_food_app/core/models/user_profile.dart';
import 'package:ethiopian_food_app/core/models/nutrition_targets.dart';
import 'package:ethiopian_food_app/services/profile_service.dart';
import 'package:ethiopian_food_app/services/auth_service.dart';
import 'package:ethiopian_food_app/core/providers/providers.dart';

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return ProfileNotifier(ref.watch(profileServiceProvider), ref.watch(authServiceProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileService _service;
  final AuthService _authService;

  ProfileNotifier(this._service, this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }
      
      await _service.init(user.id);
      final profile = _service.getProfile();
      debugPrint('[bloodType] profileProvider Hive load: ${profile?.bloodGroup.displayName}');
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw StateError('No authenticated user');
      }
      
      await _service.init(user.id);
      await _service.saveProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw StateError('No authenticated user');
      }
      
      await _service.init(user.id);
      await _service.updateProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleFastingMode() async {
    final currentProfile = state.value;
    if (currentProfile != null) {
      final updated = currentProfile.copyWith(
        fastingMode: !currentProfile.fastingMode,
        updatedAt: DateTime.now(),
      );
      await updateProfile(updated);
    }
  }

  bool hasProfile() {
    return _service.hasProfile();
  }

  Future<void> clearAllData() async {
    await _service.clearAllData();
    state = const AsyncValue.data(null);
  }
}

final nutritionTargetsProvider = Provider<NutritionTargets>((ref) {
  final profileAsync = ref.watch(profileProvider);

  return profileAsync.when(
    data: (profile) {
      if (profile == null) {
        // Return default targets
        return const NutritionTargets(
          calories: 2000,
          protein: 80,
          carbs: 250,
          fat: 65,
          fiber: 28,
        );
      }

      return NutritionTargets.fromProfile(
        profile.tdee,
        profile.weight,
        profile.goal.getCalorieAdjustment(profile.tdee),
        profile.goal.getProteinMultiplier(),
      );
    },
    loading: () => const NutritionTargets(
      calories: 2000,
      protein: 80,
      carbs: 250,
      fat: 65,
      fiber: 28,
    ),
    error: (_, __) => const NutritionTargets(
      calories: 2000,
      protein: 80,
      carbs: 250,
      fat: 65,
      fiber: 28,
    ),
  );
});
