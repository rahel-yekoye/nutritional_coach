import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ethiopian_food_app/core/api/api_client.dart';
import 'package:ethiopian_food_app/core/hive_setup.dart';

class AuthUser {
  final String id;
  final String fullName;
  final String email;
  final bool hasCompletedSetup;
  final int? age;
  final String? sex;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final String? goal;
  final bool? fastingMode;
  final Map<String, dynamic>? settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.hasCompletedSetup,
    this.age,
    this.sex,
    this.height,
    this.weight,
    this.activityLevel,
    this.goal,
    this.fastingMode,
    this.settings,
    this.createdAt,
    this.updatedAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      hasCompletedSetup: json['hasCompletedSetup'] == true,
      age: json['age']?.toInt(),
      sex: json['sex']?.toString(),
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      activityLevel: json['activityLevel']?.toString(),
      goal: json['goal']?.toString(),
      fastingMode: json['fastingMode'] == true,
      settings: json['settings'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  bool get needsSetup => !hasCompletedSetup;
}

class AuthSession {
  final AuthUser user;
  final String token;
  final bool needsSetup;

  const AuthSession({
    required this.user,
    required this.token,
    required this.needsSetup,
  });
}

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;

  AuthService({required this.apiClient, required this.sharedPreferences});

  bool get isAuthenticated => sharedPreferences.getString(_tokenKey) != null;

  AuthUser? get currentUser {
    final raw = sharedPreferences.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error parsing stored user: $e');
      return null;
    }
  }

  String? get currentToken => sharedPreferences.getString(_tokenKey);

  Future<AuthSession> register(String fullName, String email, String password) async {
    debugPrint('🔐 Registering new user: $email');
    
    final response = await apiClient.post(
      '/api/v1/auth/register',
      body: {'fullName': fullName, 'email': email, 'password': password},
    );

    return _handleAuthResponse(response, 'Registration');
  }

  Future<AuthSession> login(String email, String password) async {
    debugPrint('🔐 Logging in user: $email');
    
    final response = await apiClient.post(
      '/api/v1/auth/login',
      body: {'email': email, 'password': password},
    );

    return _handleAuthResponse(response, 'Login');
  }

  Future<AuthSession> completeSetup({
    required int age,
    required String sex,
    required double height,
    required double weight,
    required String activityLevel,
    required String goal,
    bool fastingMode = false,
  }) async {
    final token = currentToken;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    debugPrint('🔧 Completing user setup');

    final response = await apiClient.post(
      '/api/v1/auth/complete-setup',
      headers: {'Authorization': 'Bearer $token'},
      body: {
        'age': age,
        'sex': sex,
        'height': height,
        'weight': weight,
        'activityLevel': activityLevel,
        'goal': goal,
        'fastingMode': fastingMode,
      },
    );

    return _handleAuthResponse(response, 'Setup completion');
  }

  Future<AuthUser?> fetchCurrentUser() async {
    final token = currentToken;
    if (token == null) return null;

    try {
      debugPrint('🔄 Fetching current user data from server');
      
      final response = await apiClient.get(
        '/api/v1/auth/me',
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = response['data'] as Map<String, dynamic>;
      final userMap = data['user'] as Map<String, dynamic>;
      final user = AuthUser.fromJson(userMap);
      
      // Update local cache
      await sharedPreferences.setString(_userKey, jsonEncode(userMap));
      
      debugPrint('✅ User data fetched: Setup=${user.hasCompletedSetup}');
      return user;
      
    } catch (e) {
      debugPrint('❌ Failed to fetch user data: $e');
      return null;
    }
  }

  Future<AuthUser?> refreshUserData() async {
    return fetchCurrentUser();
  }

  Future<void> logout() async {
    final user = currentUser;
    debugPrint('👋 Logging out user: ${user?.email}');

    // Clear authentication data
    await sharedPreferences.remove(_tokenKey);
    await sharedPreferences.remove(_userKey);
    
    // Clear ALL user-specific cached data
    final keys = sharedPreferences.getKeys();
    final userDataKeys = keys.where((key) => 
      key.startsWith('user_') || 
      key.startsWith('profile_') || 
      key.startsWith('nutrition_') ||
      key.startsWith('meal_') ||
      key.startsWith('cache_') ||
      key.startsWith('search_')
    );
    
    for (final key in userDataKeys) {
      await sharedPreferences.remove(key);
    }
    
    // Clear user's Hive data if we know the user ID
    if (user != null) {
      await HiveSetup.clearUserData(user.id);
    }
    
    debugPrint('🗑️ All user data cleared on logout');
  }

  AuthSession _handleAuthResponse(Map<String, dynamic> response, String operation) {
    final data = response['data'] as Map<String, dynamic>;
    final userMap = data['user'] as Map<String, dynamic>;
    final token = data['token']?.toString() ?? '';
    final needsSetup = data['needsSetup'] == true;

    final user = AuthUser.fromJson(userMap);

    // Store auth data
    _storeAuthData(token, userMap);

    debugPrint('✅ $operation successful: ${user.email} (Setup: ${user.hasCompletedSetup})');

    return AuthSession(user: user, token: token, needsSetup: needsSetup);
  }

  Future<void> _storeAuthData(String token, Map<String, dynamic> userMap) async {
    await sharedPreferences.setString(_tokenKey, token);
    await sharedPreferences.setString(_userKey, jsonEncode(userMap));
  }
}
