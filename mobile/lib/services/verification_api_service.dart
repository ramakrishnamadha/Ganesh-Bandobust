import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class VerificationApiService {
  static const String _baseUrl =
      'http://3.7.18.151/api/verification';

  static String _requireSessionCookie() {
    final String? cookie =
        AuthService.sessionCookie;

    if (cookie == null ||
        cookie.trim().isEmpty) {
      throw Exception(
        'Authenticated session is not available. Please login again.',
      );
    }

    return cookie;
  }

  static Map<String, String>
      _authenticatedHeaders({
    bool includeJsonContentType = false,
  }) {
    final String cookie =
        _requireSessionCookie();

    return <String, String>{
      'Accept': 'application/json',
      'Cookie': cookie,
      if (includeJsonContentType)
        'Content-Type': 'application/json',
    };
  }

  static Future<Map<String, dynamic>>
      _postVerification(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers:
                _authenticatedHeaders(
              includeJsonContentType: true,
            ),
            body: jsonEncode(data),
          )
          .timeout(
            const Duration(
              seconds: 90,
            ),
          );

      if (response.statusCode == 401) {
        throw Exception(
          'Your login session is invalid or expired. Please login again.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'You do not have permission to save verification data for this GPID.',
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String message =
            'Failed to submit verification. '
            'Status code: ${response.statusCode}';

        if (response.body.isNotEmpty) {
          try {
            final dynamic decodedError =
                jsonDecode(
              response.body,
            );

            if (decodedError
                is Map<String, dynamic>) {
              final dynamic apiError =
                  decodedError['error'];

              if (apiError != null &&
                  apiError
                      .toString()
                      .trim()
                      .isNotEmpty) {
                message =
                    apiError.toString();
              }
            }
          } catch (_) {
            // Keep default status-code message.
          }
        }

        throw Exception(message);
      }

      final dynamic decoded =
          jsonDecode(
        response.body,
      );

      if (decoded
          is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }

      throw Exception(
        'Unexpected verification API response format.',
      );
    } on TimeoutException {
      throw Exception(
        'Verification submission timed out. Please check the network and try again.',
      );
    } on FormatException {
      throw Exception(
        'Invalid response received from verification API.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error while submitting verification: $e',
      );
    } catch (e) {
      throw Exception(
        'Unable to submit verification: $e',
      );
    }
  }

  static Future<Map<String, dynamic>>
      submitVerification(
    Map<String, dynamic> data,
  ) async {
    return _postVerification(
      data,
    );
  }

  static Future<Map<String, dynamic>>
      saveModuleResult({
    required String applicationId,
    required String gpid,
    required String moduleKey,
    required Map<String, dynamic> result,
  }) async {
    const allowedModuleKeys = {
      'locationResult',
      'mandapResult',
      'idolResult',
      'routeResult',
      'securityResult',
      'organizerResult',
      'interDepartmentalResult',
      'permissionShoReviewResult',
    };

    if (
      !allowedModuleKeys.contains(
        moduleKey,
      )
    ) {
      throw ArgumentError(
        'Invalid verification module key: $moduleKey',
      );
    }

    final cleanApplicationId =
        applicationId.trim();

    final cleanGpid =
        gpid.trim();

    if (cleanGpid.isEmpty) {
      throw ArgumentError(
        'GPID is required to save a verification module.',
      );
    }

    return _postVerification(
      {
        'applicationId':
            cleanApplicationId.isEmpty
                ? null
                : cleanApplicationId,
        'gpid': cleanGpid,
        moduleKey: result,
      },
    );
  }

  static Future<
      List<Map<String, dynamic>>>
      fetchVerifications() async {
    try {
      final response = await http
          .get(
            Uri.parse(_baseUrl),
            headers:
                _authenticatedHeaders(),
          )
          .timeout(
            const Duration(
              seconds: 90,
            ),
          );

      if (response.statusCode == 401) {
        throw Exception(
          'Your login session is invalid or expired. Please login again.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'You do not have permission to view verification records.',
        );
      }

      if (response.statusCode != 200) {
        String message =
            'Failed to load verification records. '
            'Status code: ${response.statusCode}';

        if (response.body.isNotEmpty) {
          try {
            final dynamic decodedError =
                jsonDecode(
              response.body,
            );

            if (decodedError
                is Map<String, dynamic>) {
              final dynamic apiError =
                  decodedError['error'];

              if (apiError != null &&
                  apiError
                      .toString()
                      .trim()
                      .isNotEmpty) {
                message =
                    apiError.toString();
              }
            }
          } catch (_) {
            // Keep default status-code message.
          }
        }

        throw Exception(message);
      }

      final dynamic decoded =
          jsonDecode(
        response.body,
      );

      if (decoded is! List) {
        throw Exception(
          'Unexpected verification API response format.',
        );
      }

      return decoded
          .whereType<
              Map<String, dynamic>>()
          .toList();
    } on TimeoutException {
      throw Exception(
        'Verification API request timed out.',
      );
    } on FormatException {
      throw Exception(
        'Invalid verification data received.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error while loading verification records: $e',
      );
    } catch (e) {
      throw Exception(
        'Unable to load verification records: $e',
      );
    }
  }
}