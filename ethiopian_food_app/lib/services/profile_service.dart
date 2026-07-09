import 'package:hive_flutter/hive_flutter.dart';
import '../core/models/user_profile.dart';
import '../core/hive_setup.dart';

class ProfileService {
  static const String _boxPrefix = 'userProfile';
  static const String _profileKey = 'currentProfile';

  Box<UserProfile>? _box;
  String? _currentUserId;

  Future<void> init(String userId) async {
    if (_currentUserId == userId && _box != null && _box!.isOpen) {
      return; // Already initialized for this user
    }
    
    // Close previous box if open
    await close();
    
    _currentUserId = userId;
    _box = await HiveSetup.openUserBox<UserProfile>(_boxPrefix, userId);
  }

  Future<void> saveProfile(UserProfile profile) async {
    if (_box == null) {
      throw StateError('ProfileService not initialized. Call init() first.');
    }
    await _box!.put(_profileKey, profile);
  }

  UserProfile? getProfile() {
    if (_box == null) {
      throw StateError('ProfileService not initialized. Call init() first.');
    }
    return _box!.get(_profileKey);
  }

  Future<void> updateProfile(UserProfile profile) async {
    final updated = profile.copyWith(updatedAt: DateTime.now());
    await saveProfile(updated);
  }

  bool hasProfile() {
    if (_box == null) return false;
    return _box!.containsKey(_profileKey);
  }

  Future<void> deleteProfile() async {
    if (_box == null) return;
    await _box!.delete(_profileKey);
  }

  Future<void> clearAllData() async {
    if (_box == null) return;
    await _box!.clear();
  }

  Stream<BoxEvent> watchProfile() {
    if (_box == null) return const Stream.empty();
    return _box!.watch(key: _profileKey);
  }

  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
      _currentUserId = null;
    }
  }
}