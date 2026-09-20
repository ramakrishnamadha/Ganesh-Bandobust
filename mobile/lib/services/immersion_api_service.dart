import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ImmersionApiService {
  static const String _baseUrl = 'http://3.7.18.151/api/immersion';

  static String _requireSessionCookie() {
    final String? cookie = AuthService.sessionCookie;

    if (cookie == null || cookie.trim().isEmpty) {
      throw Exception(
        'Authenticated session is not available. Please login again.',
      );
    }

    return cookie;
  }

  static Map<String, String> _authenticatedHeaders({
    bool includeJsonContentType = false,
  }) {
    final String cookie = _requireSessionCookie();

    return <String, String>{
      'Accept': 'application/json',
      'Cookie': cookie,
      if (includeJsonContentType) 'Content-Type': 'application/json',
    };
  }

  static Future<Map<String, dynamic>> submitImmersionStep(
    String gpid,
    int step,
    Map<String, dynamic> data,
  ) async {
    try {
      final payload = {
        'gpid': gpid,
        'step': step,
        'data': data,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/step'),
            headers: _authenticatedHeaders(includeJsonContentType: true),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 401) {
        throw Exception(
          'Your login session is invalid or expired. Please login again.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'You do not have permission to submit Immersion data for this GPID.',
        );
      }

      if (response.statusCode == 404) {
        throw Exception('GPID was not found in the current GPID master.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message =
            'Failed to submit Immersion step. Status code: ${response.statusCode}';

        if (response.body.isNotEmpty) {
          try {
            final dynamic decodedError = jsonDecode(response.body);

            if (decodedError is Map<String, dynamic>) {
              final dynamic apiError = decodedError['error'];

              if (apiError != null && apiError.toString().trim().isNotEmpty) {
                message = apiError.toString();
              }
            }
          } catch (_) {}
        }

        throw Exception(message);
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw Exception('Unexpected Immersion API response format.');
    } on TimeoutException {
      throw Exception(
        'Immersion submission timed out. Please check the network and try again.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred during submission.');
    }
  }

  static Future<Map<String, dynamic>> submitFinalImmersion(
    String gpid,
    Map<String, dynamic> data,
  ) async {
    try {
      final payload = {
        'gpid': gpid,
        ...data,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/complete'),
            headers: _authenticatedHeaders(includeJsonContentType: true),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 401) {
        throw Exception(
          'Your login session is invalid or expired. Please login again.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to submit final immersion step. Status code: ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return Map<String, dynamic>.from(decoded as Map);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred during final completion.');
    }
  }
}
