import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ethiopian_food_app/core/models/user_profile.dart';

class ProfileService {
  static const String _boxName = 'userProfile';
  static const String _profileKey = 'currentProfile';

  Box<UserProfile>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<UserProfile>(_boxName);
    } else {
      _box = Hive.box<UserProfile>(_boxName);
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _box?.put(_profileKey, profile);
  }

  UserProfile? getProfile() {
    try {
      final data = _box?.get(_profileKey);
      if (data == null) return null;
      return data;
    } catch (e) {
      debugPrint('Error reading profile from Hive: $e');
      return null;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    final updated = profile.copyWith(updatedAt: DateTime.now());
    await saveProfile(updated);
  }

  bool hasProfile() {
    return _box?.containsKey(_profileKey) ?? false;
  }

  Future<void> deleteProfile() async {
    await _box?.delete(_profileKey);
  }

  Stream<BoxEvent> watchProfile() {
    return _box?.watch(key: _profileKey) ?? const Stream.empty();
  }
}
