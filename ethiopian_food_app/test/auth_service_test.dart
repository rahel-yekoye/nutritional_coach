import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ethiopian_food_app/core/api/api_client.dart';
import 'package:ethiopian_food_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('login stores token and user session', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockClient = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/auth/login');

      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'user': {
              'id': 'user-123',
              'fullName': 'Test User',
              'email': 'demo@example.com',
              'profileCompleted': false,
            },
            'token': 'sample-token',
          },
        }),
        200,
      );
    });

    final service = AuthService(
      apiClient: ApiClient(client: mockClient),
      sharedPreferences: prefs,
    );

    final session = await service.login('demo@example.com', 'Password123!');

    expect(session.token, 'sample-token');
    expect(session.user.email, 'demo@example.com');
    expect(service.isAuthenticated, isTrue);
    expect(service.currentUser?.email, 'demo@example.com');
  });
}
