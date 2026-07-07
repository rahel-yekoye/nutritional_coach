import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ApiClient {
  static const String baseUrl = 'http://localhost:3000'; // Change to your deployed API
  static const Duration timeout = Duration(seconds: 10);

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParameters,
      );

      final response = await _client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timeout. Please check your connection.');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timeout. Please check your connection.');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw ApiException('Invalid response format');
      }
    } else if (response.statusCode == 404) {
      throw ApiException('Resource not found', 404);
    } else if (response.statusCode == 429) {
      throw ApiException('Too many requests. Please try again later.', 429);
    } else if (response.statusCode >= 500) {
      throw ApiException('Server error. Please try again later.', response.statusCode);
    } else {
      try {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        final message = errorData['message'] ?? errorData['error'] ?? 'Request failed';
        throw ApiException(message, response.statusCode);
      } catch (e) {
        throw ApiException('Request failed', response.statusCode);
      }
    }
  }

  void dispose() {
    _client.close();
  }
}
