import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service for reading the already-validated 2025 → 2026 Pre-Geo linkage.
///
/// IMPORTANT:
/// - No 2025 API key is stored in the mobile app.
/// - No Basic Auth credentials are stored in the mobile app.
/// - Mobile talks only to our own Next.js API.
/// - The full linked-record list is downloaded once and cached in memory.
/// - Individual GPID lookups are then performed locally from the cache.
class PreGeoApiService {
  PreGeoApiService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// Development:
  ///   flutter run --dart-define=PRE_GEO_BASE_URL=http://127.0.0.1:3000
  ///
  /// When using a physical Android device, we will use:
  ///   adb reverse tcp:3000 tcp:3000
  ///
  /// Later, when the backend is deployed, only the dart-define value changes.
  /// No source-code change will be required.
  static const String _baseUrl = String.fromEnvironment(
    'PRE_GEO_BASE_URL',
    defaultValue: 'http://3.7.18.151',
  );

  static const Duration _requestTimeout = Duration(
    seconds: 60,
  );

  /// Cached safe linked records:
  ///
  /// key   = normalized GPID
  /// value = linked 2025/2026 record
  Map<String, Map<String, dynamic>>? _linkedRecordsByGpid;

  /// Prevents two screens from triggering two simultaneous 30-second
  /// /api/pre-geo requests.
  Future<Map<String, Map<String, dynamic>>>? _loadingFuture;

  String _normalizeGpid(String value) {
    return value.trim().toUpperCase();
  }

  Uri get _preGeoUri {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(
            0,
            _baseUrl.length - 1,
          )
        : _baseUrl;

    return Uri.parse(
      '$base/api/pre-geo',
    );
  }

  /// Loads all SAFE final linked records.
  ///
  /// The backend has already excluded:
  /// - ambiguous duplicate-mobile matches
  /// - unresolved duplicate-mobile matches
  /// - mobile-only matches
  /// - name-only matches
  /// - PS-only matches
  ///
  /// Therefore the mobile app does NOT redo matching logic.
  Future<Map<String, Map<String, dynamic>>>
      _loadLinkedRecords({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _linkedRecordsByGpid != null) {
      return _linkedRecordsByGpid!;
    }

    if (!forceRefresh &&
        _loadingFuture != null) {
      return _loadingFuture!;
    }

    final future = _fetchLinkedRecords();

    _loadingFuture = future;

    try {
      final records = await future;

      _linkedRecordsByGpid = records;

      return records;
    } finally {
      _loadingFuture = null;
    }
  }

  Future<Map<String, Map<String, dynamic>>>
      _fetchLinkedRecords() async {
    http.Response response;

    try {
      response = await _client
          .get(
            _preGeoUri,
            headers: const {
              'Accept': 'application/json',
            },
          )
          .timeout(
            _requestTimeout,
          );
    } on TimeoutException {
      throw PreGeoApiException(
        'Pre-Geo server did not respond within '
        '${_requestTimeout.inSeconds} seconds.',
      );
    } on http.ClientException catch (error) {
      throw PreGeoApiException(
        'Unable to connect to the Pre-Geo server: '
        '${error.message}',
      );
    } catch (error) {
      throw PreGeoApiException(
        'Unable to connect to the Pre-Geo server: '
        '$error',
      );
    }

    if (response.statusCode != 200) {
      throw PreGeoApiException(
        'Pre-Geo server returned HTTP '
        '${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(
        utf8.decode(
          response.bodyBytes,
        ),
      );
    } catch (_) {
      throw const PreGeoApiException(
        'Pre-Geo server returned invalid JSON.',
      );
    }

    if (decoded is! Map) {
      throw const PreGeoApiException(
        'Unexpected Pre-Geo response format.',
      );
    }

    final root =
        Map<String, dynamic>.from(decoded);

    final rawRecords =
        root['finalLinkedRecords'];

    if (rawRecords == null) {
      throw const PreGeoApiException(
        'Pre-Geo response does not contain '
        'finalLinkedRecords.',
      );
    }

    if (rawRecords is! List) {
      throw const PreGeoApiException(
        'finalLinkedRecords is not a valid list.',
      );
    }

    final result =
        <String, Map<String, dynamic>>{};

    for (final rawItem in rawRecords) {
      if (rawItem is! Map) {
        continue;
      }

      final record =
          Map<String, dynamic>.from(rawItem);

      final gpid = _normalizeGpid(
        record['gpid']?.toString() ?? '',
      );

      if (gpid.isEmpty) {
        continue;
      }

      /// If the same GPID somehow appears twice,
      /// do NOT silently overwrite it.
      ///
      /// The backend should normally guarantee uniqueness,
      /// but this protects the mobile layer.
      if (result.containsKey(gpid)) {
        throw PreGeoApiException(
          'Duplicate GPID received from Pre-Geo API: '
          '$gpid',
        );
      }

      result[gpid] = record;
    }

    return result;
  }

  /// Returns the complete safe linked record for a GPID.
  ///
  /// Returns null when the GPID has no safe 2025 linkage.
  Future<Map<String, dynamic>?> getLinkedRecord(
    String gpid, {
    bool forceRefresh = false,
  }) async {
    final normalizedGpid =
        _normalizeGpid(gpid);

    if (normalizedGpid.isEmpty) {
      return null;
    }

    final records =
        await _loadLinkedRecords(
      forceRefresh: forceRefresh,
    );

    return records[normalizedGpid];
  }

  /// Returns only the previous geotag information needed by
  /// Location Verification.
  ///
  /// Returns null if:
  /// - GPID has no safe match, or
  /// - latitude/longitude are unavailable or invalid.
  Future<PreGeoLocation?> getPreviousLocation(
    String gpid, {
    bool forceRefresh = false,
  }) async {
    final record =
        await getLinkedRecord(
      gpid,
      forceRefresh: forceRefresh,
    );

    if (record == null) {
      return null;
    }

    final latitude = _parseCoordinate(
      record['preGeo2025Latitude'],
    );

    final longitude = _parseCoordinate(
      record['preGeo2025Longitude'],
    );

    if (latitude == null ||
        longitude == null) {
      return null;
    }

    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    return PreGeoLocation(
      gpid: record['gpid']
              ?.toString()
              .trim() ??
          '',
      refNo: record['refNo']
              ?.toString()
              .trim() ??
          '',
      currentName:
          record['currentName']
                  ?.toString()
                  .trim() ??
              '',
      currentMobile:
          record['currentMobile']
                  ?.toString()
                  .trim() ??
              '',
      currentPoliceStation:
          record['currentPoliceStation']
                  ?.toString()
                  .trim() ??
              '',
      matchType:
          record['matchType']
                  ?.toString()
                  .trim() ??
              '',
      preGeo2025RegNo:
          record['preGeo2025RegNo']
                  ?.toString()
                  .trim() ??
              '',
      latitude: latitude,
      longitude: longitude,
      preGeo2025Name:
          record['preGeo2025Name']
                  ?.toString()
                  .trim() ??
              '',
      preGeo2025Mobile:
          record['preGeo2025Mobile']
                  ?.toString()
                  .trim() ??
              '',
      preGeo2025PoliceStation:
          record['preGeo2025PoliceStation']
                  ?.toString()
                  .trim() ??
              '',
    );
  }

  double? _parseCoordinate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
  }

  /// Clears the local in-memory cache.
  ///
  /// We can call this when we intentionally want to fetch the
  /// latest 2026 registrations again.
  void clearCache() {
    _linkedRecordsByGpid = null;
  }

  /// Number of safe linked GPIDs currently cached in the app.
  int get cachedRecordCount =>
      _linkedRecordsByGpid?.length ?? 0;

  void dispose() {
    _client.close();
  }
}

class PreGeoLocation {
  const PreGeoLocation({
    required this.gpid,
    required this.refNo,
    required this.currentName,
    required this.currentMobile,
    required this.currentPoliceStation,
    required this.matchType,
    required this.preGeo2025RegNo,
    required this.latitude,
    required this.longitude,
    required this.preGeo2025Name,
    required this.preGeo2025Mobile,
    required this.preGeo2025PoliceStation,
  });

  final String gpid;
  final String refNo;

  final String currentName;
  final String currentMobile;
  final String currentPoliceStation;

  final String matchType;

  final String preGeo2025RegNo;

  final double latitude;
  final double longitude;

  final String preGeo2025Name;
  final String preGeo2025Mobile;
  final String preGeo2025PoliceStation;

  bool get isDuplicateMobileResolved =>
      matchType ==
      'DUPLICATE_MOBILE_RESOLVED_UNIQUE_NAME_AND_PS';
}

class PreGeoApiException
    implements Exception {
  const PreGeoApiException(
    this.message, {
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode != null) {
      return 'PreGeoApiException '
          '(HTTP $statusCode): $message';
    }

    return 'PreGeoApiException: $message';
  }
}