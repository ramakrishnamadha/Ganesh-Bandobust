import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'auth_service.dart';

class GpidCacheStatus {
  final String version;
  final int totalCount;

  const GpidCacheStatus({
    required this.version,
    required this.totalCount,
  });
}

enum GpidVerificationStatus {
  authorized,
  unauthorized,
  notFound,
  invalidFormat,
  unauthenticated,
  networkError,
  serverError,
}

class GpidVerificationResult {
  final GpidVerificationStatus status;
  final String gpid;
  final bool isAuthorized;
  final String? errorMessage;
  final Map<String, dynamic>? record;
  final Map<String, dynamic>? stages;
  final bool isOfflineFallback;

  const GpidVerificationResult({
    required this.status,
    required this.gpid,
    required this.isAuthorized,
    this.errorMessage,
    this.record,
    this.stages,
    this.isOfflineFallback = false,
  });
}

class GpidApiService {
  static const String _baseUrl =
      'http://3.7.18.151';

  static const String _gpidUrl =
      '$_baseUrl/api/gpid';

  static const String _statusUrl =
      '$_baseUrl/api/gpid/status';

  static String _safeCacheKey(
    String value,
  ) {
    final String trimmed =
        value.trim();

    if (trimmed.isEmpty) {
      return 'unknown-user';
    }

    return trimmed.replaceAll(
      RegExp(
        r'[^a-zA-Z0-9_-]',
      ),
      '_',
    );
  }

  static Future<File> _cacheFile(
    String userId,
  ) async {
    final Directory directory =
        await getApplicationDocumentsDirectory();

    final String safeUserId =
        _safeCacheKey(
      userId,
    );

    return File(
      '${directory.path}/gpid-cache-$safeUserId.json',
    );
  }

  static Future<File> _versionFile(
    String userId,
  ) async {
    final Directory directory =
        await getApplicationDocumentsDirectory();

    final String safeUserId =
        _safeCacheKey(
      userId,
    );

    return File(
      '${directory.path}/gpid-version-$safeUserId.txt',
    );
  }

  static Future<List<Map<String, dynamic>>>
      loadCachedRecords({
    required String userId,
  }) async {
    try {
      final File file =
          await _cacheFile(
        userId,
      );

      if (!await file.exists()) {
        return <Map<String, dynamic>>[];
      }

      final String raw =
          await file.readAsString();

      if (raw.trim().isEmpty) {
        return <Map<String, dynamic>>[];
      }

      final dynamic decoded =
          jsonDecode(
        raw,
      );

      if (decoded is! List) {
        return <Map<String, dynamic>>[];
      }

      return decoded
          .whereType<
              Map<String, dynamic>>()
          .where(
        (
          Map<String, dynamic>
              record,
        ) {
          final String gpid =
              (record['unique_id'] ?? '')
                  .toString()
                  .trim();

          return gpid.isNotEmpty;
        },
      ).map(
        (
          Map<String, dynamic>
              record,
        ) {
          return Map<String, dynamic>.from(
            record,
          );
        },
      ).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<String>
      loadCachedVersion({
    required String userId,
  }) async {
    try {
      final File file =
          await _versionFile(
        userId,
      );

      if (!await file.exists()) {
        return '';
      }

      return (
        await file.readAsString()
      ).trim();
    } catch (_) {
      return '';
    }
  }

  static Future<void>
      _saveCachedRecords({
    required String userId,
    required List<
        Map<String, dynamic>>
        records,
  }) async {
    final File file =
        await _cacheFile(
      userId,
    );

    await file.writeAsString(
      jsonEncode(
        records,
      ),
      flush: true,
    );
  }

  static Future<void>
      _saveCachedVersion({
    required String userId,
    required String version,
  }) async {
    final File file =
        await _versionFile(
      userId,
    );

    await file.writeAsString(
      version,
      flush: true,
    );
  }

  static Future<GpidCacheStatus>
      fetchStatus() async {
    final String? sessionCookie =
        AuthService.sessionCookie;

    if (sessionCookie == null ||
        sessionCookie.isEmpty) {
      throw Exception(
        'Authenticated session is not available. Please login again.',
      );
    }

    try {
      final http.Response response =
          await http
              .get(
                Uri.parse(
                  _statusUrl,
                ),
                headers:
                    <String, String>{
                  'Accept':
                      'application/json',
                  'Cookie':
                      sessionCookie,
                },
              )
              .timeout(
                const Duration(
                  seconds: 20,
                ),
              );

      if (response.statusCode ==
          401) {
        throw Exception(
          'Your login session is invalid or expired. Please login again.',
        );
      }

      if (response.statusCode ==
          403) {
        throw Exception(
          'You do not have permission to access GPID records.',
        );
      }

      if (response.statusCode !=
          200) {
        throw Exception(
          'Unable to check GPID updates.',
        );
      }

      final dynamic decoded =
          jsonDecode(
        response.body,
      );

      if (decoded
          is! Map<String, dynamic>) {
        throw Exception(
          'Unexpected GPID status response.',
        );
      }

      final String version =
          (decoded['version'] ?? '')
              .toString()
              .trim();

      final int totalCount =
          int.tryParse(
            (decoded['totalCount'] ??
                    0)
                .toString(),
          ) ??
          0;

      return GpidCacheStatus(
        version: version,
        totalCount: totalCount,
      );
    } on TimeoutException {
      throw Exception(
        'GPID update check timed out.',
      );
    } on FormatException {
      throw Exception(
        'Invalid GPID status data received.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error while checking GPID updates: $e',
      );
    }
  }

  static Future<List<Map<String, dynamic>>>
      fetchGaneshRecords({
    required String userId,
    bool forceNetwork = false,
  }) async {
    final List<Map<String, dynamic>>
        cachedRecords =
        await loadCachedRecords(
      userId: userId,
    );

    final String cachedVersion =
        await loadCachedVersion(
      userId: userId,
    );

    if (!forceNetwork &&
        cachedRecords.isNotEmpty) {
      try {
        final GpidCacheStatus status =
            await fetchStatus();

        if (status.version.isNotEmpty &&
            cachedVersion.isNotEmpty &&
            status.version ==
                cachedVersion) {
          return cachedRecords;
        }
      } catch (_) {
        return cachedRecords;
      }
    }

    final String? sessionCookie =
        AuthService.sessionCookie;

    if (sessionCookie == null ||
        sessionCookie.isEmpty) {
      if (cachedRecords.isNotEmpty) {
        return cachedRecords;
      }

      throw Exception(
        'Authenticated session is not available. Please login again.',
      );
    }

    try {
      final http.Response response =
          await http
              .get(
                Uri.parse(
                  _gpidUrl,
                ),
                headers:
                    <String, String>{
                  'Accept':
                      'application/json',
                  'Cookie':
                      sessionCookie,
                },
              )
              .timeout(
                const Duration(
                  seconds: 90,
                ),
              );

      if (response.statusCode ==
          401) {
        if (cachedRecords.isNotEmpty) {
          return cachedRecords;
        }

        throw Exception(
          'Your login session is invalid or expired. Please login again.',
        );
      }

      if (response.statusCode ==
          403) {
        if (cachedRecords.isNotEmpty) {
          return cachedRecords;
        }

        throw Exception(
          'You do not have permission to access GPID records.',
        );
      }

      if (response.statusCode !=
          200) {
        if (cachedRecords.isNotEmpty) {
          return cachedRecords;
        }

        String message =
            'Failed to load Ganesh records. '
            'Status code: ${response.statusCode}';

        if (response.body.isNotEmpty) {
          try {
            final dynamic
                decodedError =
                jsonDecode(
              response.body,
            );

            if (decodedError
                is Map<String,
                    dynamic>) {
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
            // Keep default message.
          }
        }

        throw Exception(
          message,
        );
      }

      final dynamic decoded =
          jsonDecode(
        response.body,
      );

      if (decoded is! List) {
        if (cachedRecords.isNotEmpty) {
          return cachedRecords;
        }

        throw Exception(
          'Unexpected API response format.',
        );
      }

      final List<Map<String, dynamic>>
          records =
          decoded
              .whereType<
                  Map<String,
                      dynamic>>()
              .where(
        (
          Map<String, dynamic>
              record,
        ) {
          final String gpid =
              (record['unique_id'] ?? '')
                  .toString()
                  .trim();

          return gpid.isNotEmpty;
        },
      ).map(
        (
          Map<String, dynamic>
              record,
        ) {
          return Map<String, dynamic>.from(
            record,
          );
        },
      ).toList();

      await _saveCachedRecords(
        userId: userId,
        records: records,
      );

      try {
        final GpidCacheStatus status =
            await fetchStatus();

        if (status.version.isNotEmpty) {
          await _saveCachedVersion(
            userId: userId,
            version:
                status.version,
          );
        }
      } catch (_) {
        // Records remain usable even if
        // version lookup temporarily fails.
      }

      return records;
    } on TimeoutException {
      if (cachedRecords.isNotEmpty) {
        return cachedRecords;
      }

      throw Exception(
        'GPID API request timed out. Please check network connectivity and try again.',
      );
    } on FormatException {
      if (cachedRecords.isNotEmpty) {
        return cachedRecords;
      }

      throw Exception(
        'Invalid data received from GPID API.',
      );
    } on http.ClientException catch (e) {
      if (cachedRecords.isNotEmpty) {
        return cachedRecords;
      }

      throw Exception(
        'Network error while loading GPID records: $e',
      );
    } catch (e) {
      if (cachedRecords.isNotEmpty) {
        return cachedRecords;
      }

      throw Exception(
        'Unable to load GPID records: $e',
      );
    }
  }

  static Future<GpidVerificationResult> verifyGpidJurisdiction({
    required String gpid,
    AuthenticatedUser? user,
  }) async {
    final String cleanGpid = gpid.trim().toUpperCase();
    if (cleanGpid.isEmpty) {
      return const GpidVerificationResult(
        status: GpidVerificationStatus.invalidFormat,
        gpid: '',
        isAuthorized: false,
        errorMessage: 'GPID cannot be empty.',
      );
    }

    final String? sessionCookie = AuthService.sessionCookie;
    final Uri targetUri =
        Uri.parse('$_statusUrl?gpid=${Uri.encodeComponent(cleanGpid)}');

    // 1. Attempt server-side verification first
    if (sessionCookie != null && sessionCookie.isNotEmpty) {
      try {
        final http.Response response = await http.get(
          targetUri,
          headers: <String, String>{
            'Accept': 'application/json',
            'Cookie': sessionCookie,
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final dynamic decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded['success'] == true) {
            final Map<String, dynamic>? recordData =
                decoded['record'] is Map<String, dynamic>
                    ? Map<String, dynamic>.from(decoded['record'])
                    : null;
            final Map<String, dynamic>? stagesData =
                decoded['stages'] is Map<String, dynamic>
                    ? Map<String, dynamic>.from(decoded['stages'])
                    : null;

            return GpidVerificationResult(
              status: GpidVerificationStatus.authorized,
              gpid: cleanGpid,
              isAuthorized: true,
              record: recordData,
              stages: stagesData,
            );
          }
        }

        if (response.statusCode == 403) {
          String msg =
              'Access Denied: You do not have jurisdiction to inspect this GPID.';
          try {
            final dynamic decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic> && decoded['error'] != null) {
              msg = decoded['error'].toString();
            }
          } catch (_) {}

          return GpidVerificationResult(
            status: GpidVerificationStatus.unauthorized,
            gpid: cleanGpid,
            isAuthorized: false,
            errorMessage: msg,
          );
        }

        if (response.statusCode == 404) {
          String msg = 'GPID not found in master records.';
          try {
            final dynamic decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic> && decoded['error'] != null) {
              msg = decoded['error'].toString();
            }
          } catch (_) {}

          return GpidVerificationResult(
            status: GpidVerificationStatus.notFound,
            gpid: cleanGpid,
            isAuthorized: false,
            errorMessage: msg,
          );
        }

        if (response.statusCode == 400) {
          return GpidVerificationResult(
            status: GpidVerificationStatus.invalidFormat,
            gpid: cleanGpid,
            isAuthorized: false,
            errorMessage: 'Invalid GPID format: $cleanGpid',
          );
        }

        if (response.statusCode == 401) {
          return GpidVerificationResult(
            status: GpidVerificationStatus.unauthenticated,
            gpid: cleanGpid,
            isAuthorized: false,
            errorMessage: 'Your session has expired. Please log in again.',
          );
        }
      } catch (_) {
        // Network error / timeout: proceed to local cache check below
      }
    }

    // 2. Offline Fallback: Check local cache with local jurisdiction evaluation
    if (user != null) {
      try {
        final cachedRecords = await loadCachedRecords(userId: user.employeeId);
        final matchingRecord = cachedRecords.firstWhere(
          (r) {
            final uId =
                (r['unique_id'] ?? '').toString().trim().toUpperCase();
            final ref = (r['ref_no'] ?? '').toString().trim().toUpperCase();
            return uId == cleanGpid || ref == cleanGpid;
          },
          orElse: () => <String, dynamic>{},
        );

        if (matchingRecord.isNotEmpty) {
          final bool locallyPermitted =
              _isPermittedLocally(matchingRecord, user);
          if (!locallyPermitted) {
            final psName =
                matchingRecord['ps_name'] ?? 'another police station';
            return GpidVerificationResult(
              status: GpidVerificationStatus.unauthorized,
              gpid: cleanGpid,
              isAuthorized: false,
              errorMessage:
                  'Access Denied: GPID belongs to $psName PS (offline verification).',
              isOfflineFallback: true,
            );
          }

          return GpidVerificationResult(
            status: GpidVerificationStatus.authorized,
            gpid: cleanGpid,
            isAuthorized: true,
            record: matchingRecord,
            isOfflineFallback: true,
          );
        }
      } catch (_) {}
    }

    // 3. Fallback when network failed and not in local cache
    return GpidVerificationResult(
      status: GpidVerificationStatus.networkError,
      gpid: cleanGpid,
      isAuthorized: false,
      errorMessage:
          'Network connection failed and GPID is not stored in offline cache.',
    );
  }

  static bool _isPermittedLocally(
    Map<String, dynamic> record,
    AuthenticatedUser user,
  ) {
    if (user.isAdmin || user.allZones) return true;

    String norm(dynamic v) {
      return (v ?? '')
          .toString()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'\s+ps$'), '')
          .trim();
    }

    final ps = norm(record['ps_name']);
    final userPs = norm(user.policeStationName);

    if (user.allPoliceStations) {
      final userZone = norm(user.zoneName);
      final userDiv = norm(user.divisionName);
      if (userZone.isNotEmpty) return norm(record['zone_name']) == userZone;
      if (userDiv.isNotEmpty) return norm(record['division_name']) == userDiv;
      if (userPs.isNotEmpty) return ps == userPs;
      return false;
    }

    if (userPs.isNotEmpty && ps == userPs) return true;

    final allowed = user.allowedPoliceStations
        .where((a) => a.canView)
        .map((a) => norm(a.policeStationName))
        .where((n) => n.isNotEmpty)
        .toSet();

    return allowed.contains(ps);
  }
}