import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ethiopian_food_app/core/api/api_client.dart';

class AuthUser {
  final String id;
  final String fullName;
  final String email;
  final bool profileCompleted;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.profileCompleted,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileCompleted: json['profileCompleted'] == true,
    );
  }
}

class AuthSession {
  final AuthUser user;
  final String token;

  const AuthSession({required this.user, required this.token});
}

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _avatarKey = 'auth_avatar';

  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;

  AuthService({required this.apiClient, required this.sharedPreferences});

  bool get isAuthenticated => sharedPreferences.getString(_tokenKey) != null;

  AuthUser? get currentUser {
    final raw = sharedPreferences.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  String get avatar => sharedPreferences.getString(_avatarKey) ?? '🙂';

  Future<AuthSession> login(String email, String password) async {
    final response = await apiClient.post(
      '/api/v1/auth/login',
      body: {'email': email, 'password': password},
    );

    final data = response['data'] as Map<String, dynamic>;
    final userMap = data['user'] as Map<String, dynamic>;
    final token = data['token']?.toString() ?? '';

    final user = AuthUser.fromJson(userMap);

    await sharedPreferences.setString(_tokenKey, token);
    await sharedPreferences.setString(_userKey, jsonEncode(userMap));

    return AuthSession(user: user, token: token);
  }

  Future<AuthSession> register(String fullName, String email, String password) async {
    final response = await apiClient.post(
      '/api/v1/auth/register',
      body: {'fullName': fullName, 'email': email, 'password': password},
    );

    final data = response['data'] as Map<String, dynamic>;
    final userMap = data['user'] as Map<String, dynamic>;
    final token = data['token']?.toString() ?? '';
    final user = AuthUser.fromJson(userMap);

    await sharedPreferences.setString(_tokenKey, token);
    await sharedPreferences.setString(_userKey, jsonEncode(userMap));

    return AuthSession(user: user, token: token);
  }

  Future<void> logout() async {
    await sharedPreferences.remove(_tokenKey);
    await sharedPreferences.remove(_userKey);
    await sharedPreferences.remove(_avatarKey);
  }

  Future<void> updateCurrentUserProfile({String? fullName, String? avatar}) async {
    final current = currentUser;
    if (current == null) return;

    final userMap = {
      'id': current.id,
      'fullName': fullName ?? current.fullName,
      'email': current.email,
      'profileCompleted': current.profileCompleted,
    };

    await sharedPreferences.setString(_userKey, jsonEncode(userMap));
    if (avatar != null) {
      await sharedPreferences.setString(_avatarKey, avatar);
    }
  }

  Future<void> setAvatar(String avatar) async {
    await sharedPreferences.setString(_avatarKey, avatar);
  }

  Future<AuthUser?> fetchCurrentUser() async {
    final token = sharedPreferences.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;

    try {
      final response = await apiClient.get(
        '/api/v1/auth/me',
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = response['data'] as Map<String, dynamic>;
      final userMap = data['user'] as Map<String, dynamic>;
      final user = AuthUser.fromJson(userMap);
      await sharedPreferences.setString(_userKey, jsonEncode(userMap));
      return user;
    } catch (e) {
      debugPrint('Failed to refresh auth user: $e');
      return null;
    }
  }
}
