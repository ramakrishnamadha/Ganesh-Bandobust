import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class FestivityCheckApiService {
  static const String _baseUrl =
      'http://3.7.18.151/api/festivity-checks';

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

  static Future<Map<String, dynamic>> submitFestivityCheck(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _authenticatedHeaders(includeJsonContentType: true),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 401) {
        throw Exception(
          'Your login session is invalid or expired. Please login again.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'You do not have permission to submit a Festivity check for this GPID.',
        );
      }

      if (response.statusCode == 404) {
        throw Exception('GPID was not found in the current GPID master.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message =
            'Failed to submit Festivity check. Status code: ${response.statusCode}';

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

      throw Exception('Unexpected Festivity API response format.');
    } on TimeoutException {
      throw Exception(
        'Festivity check submission timed out. Please check the network and try again.',
      );
    } on FormatException {
      throw Exception('Invalid response received from Festivity API.');
    } on http.ClientException catch (e) {
      throw Exception('Network error while submitting Festivity check: $e');
    } catch (e) {
      throw Exception('Unable to submit Festivity check: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchFestivityContext({
    required String gpid,
    int? festivalDay,
  }) async {
    final String cleanGpid = gpid.trim();

    if (cleanGpid.isEmpty) {
      throw Exception('GPID is required to load Festivity context.');
    }

    try {
      final queryParameters = <String, String>{
        'gpid': cleanGpid,
        'includeContext': 'true',
        'limit': '200',
      };

      if (festivalDay != null) {
        queryParameters['festivalDay'] = festivalDay.toString();
      }

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: queryParameters,
      );

      final response = await http
          .get(
            uri,
            headers: _authenticatedHeaders(),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 401) {
        throw Exception(
          'Your login session is invalid or expired. Please login again.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'You do not have permission to view Festivity information for this GPID.',
        );
      }

      if (response.statusCode == 404) {
        throw Exception('GPID was not found in the current GPID master.');
      }

      if (response.statusCode != 200) {
        String message =
            'Failed to load Festivity context. Status code: ${response.statusCode}';

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

      throw Exception('Unexpected Festivity context response format.');
    } on TimeoutException {
      throw Exception('Festivity context request timed out.');
    } on FormatException {
      throw Exception('Invalid Festivity context data received.');
    } on http.ClientException catch (e) {
      throw Exception('Network error while loading Festivity context: $e');
    } catch (e) {
      throw Exception('Unable to load Festivity context: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchFestivityChecks({
    String? gpid,
    int? festivalDay,
    int limit = 200,
  }) async {
    try {
      final queryParameters = <String, String>{
        'limit': limit.clamp(1, 500).toString(),
      };

      final String cleanGpid = gpid?.trim() ?? '';

      if (cleanGpid.isNotEmpty) {
        queryParameters['gpid'] = cleanGpid;
      }

      if (festivalDay != null) {
        queryParameters['festivalDay'] = festivalDay.toString();
      }

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: queryParameters,
      );

      final response = await http
          .get(
            uri,
            headers: _authenticatedHeaders(),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 401) {
        throw Exception(
          'Your login session is invalid or expired. Please login again.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'You do not have permission to view Festivity check records.',
        );
      }

      if (response.statusCode != 200) {
        String message =
            'Failed to load Festivity check records. Status code: ${response.statusCode}';

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

      if (decoded is! List) {
        throw Exception('Unexpected Festivity API response format.');
      }

      return decoded.whereType<Map<String, dynamic>>().toList();
    } on TimeoutException {
      throw Exception('Festivity API request timed out.');
    } on FormatException {
      throw Exception('Invalid Festivity check data received.');
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error while loading Festivity check records: $e',
      );
    } catch (e) {
      throw Exception('Unable to load Festivity check records: $e');
    }
  }
}
