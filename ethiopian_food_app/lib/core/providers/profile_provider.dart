import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiopian_food_app/core/models/user_profile.dart';
import 'package:ethiopian_food_app/core/models/nutrition_targets.dart';
import 'package:ethiopian_food_app/services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return ProfileNotifier(ref.watch(profileServiceProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileService _service;

  ProfileNotifier(this._service) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      await _service.init();
      final profile = _service.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    try {
      await _service.saveProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
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
