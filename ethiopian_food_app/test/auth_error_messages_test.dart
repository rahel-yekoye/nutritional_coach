import 'package:flutter_test/flutter_test.dart';
import 'package:ethiopian_food_app/core/api/api_client.dart';
import 'package:ethiopian_food_app/core/auth/auth_error_messages.dart';

void main() {
  test('maps duplicate email registration to friendly message', () {
    const error = ApiException('An account with this email already exists', 409);
    expect(
      mapAuthErrorMessage(error, isLogin: false),
      'An account with this email already exists. Please sign in or use a different email.',
    );
  });

  test('maps wrong password login to incorrect credentials message', () {
    const error = ApiException('Invalid email or password', 401);
    expect(
      mapAuthErrorMessage(error, isLogin: true),
      'Incorrect email or password.',
    );
  });

  test('does not treat 401 login as server unavailable', () {
    const error = ApiException('Invalid email or password', 401);
    expect(
      mapAuthErrorMessage(error, isLogin: true),
      isNot(contains('server')),
    );
  });

  test('maps network timeout to timeout message', () {
    const error = ApiException('Request timed out.');
    expect(
      mapAuthErrorMessage(error, isLogin: false),
      'The request timed out. Please try again.',
    );
  });

  test('maps server error on login', () {
    const error = ApiException('Server error. Please try again later.', 500);
    expect(
      mapAuthErrorMessage(error, isLogin: true),
      'The server is currently unavailable. Please try again later.',
    );
  });

  test('maps expired token to session message', () {
    const error = ApiException('Invalid or expired token', 401);
    expect(
      mapAuthErrorMessage(error, isLogin: true),
      'Your session has expired. Please sign in again.',
    );
  });
}
