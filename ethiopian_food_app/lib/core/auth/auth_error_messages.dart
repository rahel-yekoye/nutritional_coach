import 'package:ethiopian_food_app/core/api/api_client.dart';

const String kPasswordRequirementsMessage =
    'Password must be at least 8 characters long.';

/// Maps API and network failures to user-friendly authentication messages.
String mapAuthErrorMessage(Object error, {required bool isLogin}) {
  if (error is ApiException) {
    return _mapApiException(error, isLogin: isLogin);
  }

  return isLogin
      ? 'Unable to sign in. Please try again.'
      : 'Unable to create your account. Please try again.';
}

String _mapApiException(ApiException error, {required bool isLogin}) {
  final statusCode = error.statusCode;
  final message = error.message.toLowerCase();

  // Status-code mapping takes priority over generic network detection.
  if (_isSessionError(message, statusCode)) {
    return 'Your session has expired. Please sign in again.';
  }

  if (isLogin) {
    final loginMessage = _mapLoginError(message, statusCode);
    if (loginMessage != null) return loginMessage;
  } else {
    final registrationMessage = _mapRegistrationError(message, statusCode);
    if (registrationMessage != null) return registrationMessage;
  }

  if (_isNetworkError(error)) {
    return _mapNetworkError(error);
  }

  return isLogin
      ? 'Unable to sign in. Please try again.'
      : 'Unable to create your account. Please try again.';
}

String _mapNetworkError(ApiException error) {
  final message = error.message.toLowerCase();

  if (message.contains('timeout') || message.contains('timed out')) {
    return 'The request timed out. Please try again.';
  }

  if (message.contains('network error') ||
      message.contains('no internet') ||
      message.contains('failed host lookup') ||
      message.contains('connection refused')) {
    return 'No internet connection. Please check your network.';
  }

  if (error.statusCode != null && error.statusCode! >= 500) {
    return 'The server is currently unavailable. Please try again later.';
  }

  return 'The server is currently unavailable. Please try again later.';
}

bool _isNetworkError(ApiException error) {
  final message = error.message.toLowerCase();
  return message.contains('timeout') ||
      message.contains('timed out') ||
      message.contains('network error') ||
      message.contains('no internet') ||
      message.contains('failed host lookup') ||
      message.contains('connection refused') ||
      (error.statusCode != null && error.statusCode! >= 500);
}

bool _isSessionError(String message, int? statusCode) {
  if (statusCode == 403) {
    return message.contains('token') ||
        message.contains('expired') ||
        message.contains('not authorized') ||
        message.contains('unauthorized');
  }

  return statusCode == 401 &&
      (message.contains('token') ||
          message.contains('expired') ||
          message.contains('not authorized') ||
          message.contains('unauthorized') ||
          message.contains('invalid or expired'));
}

/// Returns a user message, or null to fall through to network/generic handling.
String? _mapLoginError(String message, int? statusCode) {
  if (statusCode == 401) {
    return 'Incorrect email or password.';
  }

  if (statusCode == 404 ||
      message.contains('no account') ||
      message.contains('user not found') ||
      message.contains('not found with this email')) {
    return 'No account found with this email.';
  }

  if (statusCode == 400) {
    if (message.contains('email') && message.contains('required')) {
      return 'Please enter your email address.';
    }
    if (message.contains('password') && message.contains('required')) {
      return 'Please enter your password.';
    }
  }

  if (statusCode == 429) {
    return 'Too many attempts. Please wait a moment and try again.';
  }

  if (statusCode != null && statusCode >= 500) {
    return 'The server is currently unavailable. Please try again later.';
  }

  if (message.contains('invalid email or password') ||
      message.contains('incorrect email or password')) {
    return 'Incorrect email or password.';
  }

  return null;
}

/// Returns a user message, or null to fall through to network/generic handling.
String? _mapRegistrationError(String message, int? statusCode) {
  if (statusCode == 409 ||
      message.contains('already exists') ||
      message.contains('email already')) {
    return 'An account with this email already exists. Please sign in or use a different email.';
  }

  if (message.contains('valid email')) {
    return 'Please enter a valid email address.';
  }

  if (message.contains('password') &&
      (message.contains('at least') ||
          message.contains('minlength') ||
          message.contains('8'))) {
    return kPasswordRequirementsMessage;
  }

  if (statusCode == 400 || statusCode == 422) {
    if (message.contains('fullname') && message.contains('required')) {
      return 'Please enter your full name.';
    }
    if (message.contains('full name') && message.contains('required')) {
      return 'Please enter your full name.';
    }
    if (message.contains('email') && message.contains('required')) {
      return 'Please enter your email address.';
    }
    if (message.contains('password') && message.contains('required')) {
      return 'Please enter your password.';
    }
    if (message.contains('required')) {
      return 'Please fill in all required fields.';
    }
  }

  if (statusCode == 429) {
    return 'Too many attempts. Please wait a moment and try again.';
  }

  if (statusCode != null && statusCode >= 500) {
    return 'The server is currently unavailable. Please try again later.';
  }

  return null;
}
