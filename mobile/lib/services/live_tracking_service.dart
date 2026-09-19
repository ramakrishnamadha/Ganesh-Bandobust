import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'tracking_session_store.dart';

class LiveTrackingService {
  LiveTrackingService._()
      : _client = http.Client();

  static final LiveTrackingService instance =
      LiveTrackingService._();

  final http.Client _client;

  static const String _baseUrl =
      String.fromEnvironment(
    'TRACKING_BASE_URL',
    defaultValue: 'http://3.7.18.151',
  );

  static const Duration _requestTimeout =
      Duration(seconds: 20);

  Timer? _heartbeatTimer;

  bool _trackingStarted = false;
  bool _sending = false;

  String? _activeGpid;
  String _activityStatus = 'ONLINE';

  bool get isTrackingStarted =>
      _trackingStarted;

  String? get activeGpid =>
      _activeGpid;

  String get activityStatus =>
      _activityStatus;

  Uri get _sessionUri {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(
            0,
            _baseUrl.length - 1,
          )
        : _baseUrl;

    return Uri.parse(
      '$base/api/tracking/session',
    );
  }

  Uri get _locationUri {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(
            0,
            _baseUrl.length - 1,
          )
        : _baseUrl;

    return Uri.parse(
      '$base/api/tracking/location',
    );
  }

  Future<bool> createTrackingSession({
    required String userId,
    required String userName,
    required String role,
    required String rank,
    required String policeStation,
    required String sector,
    String commissionerateCode = 'HYD',
    String? rangeCode,
    String? zoneCode,
    String? divisionCode,
    String? deviceId,
    String deviceName = 'Android Device',
    String manufacturer = 'Unknown',
    String model = 'Unknown',
    String platform = 'ANDROID',
    String osVersion = 'Unknown',
    String appVersion = '1.0.0',
  }) async {
    try {
      final body = <String, dynamic>{
        'userId': userId,
        'userName': userName,
        'rank': rank,
        'role': role,
        'source': 'MOBILE',
        'deviceType': 'MOBILE',
        'deviceId': deviceId,
        'deviceName': deviceName,
        'manufacturer': manufacturer,
        'model': model,
        'platform': platform,
        'osVersion': osVersion,
        'appVersion': appVersion,
        'commissionerateCode':
            commissionerateCode,
        'rangeCode': rangeCode,
        'zoneCode': zoneCode,
        'divisionCode': divisionCode,
        'policeStationCode':
            policeStation,
        'sectorCode': sector,
        'trackingEnabled': true,
      };

      final response = await _client
          .post(
            _sessionUri,
            headers: const {
              'Accept':
                  'application/json',
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(
            _requestTimeout,
          );

      if (response.statusCode != 201) {
        return false;
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is! Map) {
        return false;
      }

      if (decoded['success'] != true) {
        return false;
      }

      final userSessionId =
          decoded['userSessionId']
              ?.toString()
              .trim();

      final deviceSessionId =
          decoded['deviceSessionId']
              ?.toString()
              .trim();

      if (userSessionId == null ||
          userSessionId.isEmpty ||
          deviceSessionId == null ||
          deviceSessionId.isEmpty) {
        return false;
      }

      TrackingSessionStore.instance
          .setSession(
        userSessionId: userSessionId,
        deviceSessionId:
            deviceSessionId,
        userId: userId,
        userName: userName,
        role: role,
        policeStation:
            policeStation,
        sector: sector,
      );

      return true;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTrackingState({
    required String trackingStatus,
    required bool trackingEnabled,
  }) async {
    final store =
        TrackingSessionStore.instance;

    if (!store.hasActiveSession) {
      return false;
    }

    try {
      final response = await _client
          .patch(
            _sessionUri,
            headers: const {
              'Accept':
                  'application/json',
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode({
              'userSessionId':
                  store.userSessionId,
              'deviceSessionId':
                  store.deviceSessionId,
              'trackingStatus':
                  trackingStatus,
              'trackingEnabled':
                  trackingEnabled,
            }),
          )
          .timeout(
            _requestTimeout,
          );

      if (response.statusCode != 200) {
        return false;
      }

      final decoded =
          jsonDecode(response.body);

      return decoded is Map &&
          decoded['success'] == true;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> closeTrackingSession() async {
    final store =
        TrackingSessionStore.instance;

    if (!store.hasActiveSession) {
      return true;
    }

    try {
      final response = await _client
          .delete(
            _sessionUri,
            headers: const {
              'Accept':
                  'application/json',
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode({
              'userSessionId':
                  store.userSessionId,
              'deviceSessionId':
                  store.deviceSessionId,
            }),
          )
          .timeout(
            _requestTimeout,
          );

      final success =
          response.statusCode == 200;

      if (success) {
        store.clear();
      }

      return success;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> ensureLocationPermission() async {
    final serviceEnabled =
        await Geolocator
            .isLocationServiceEnabled();

    if (!serviceEnabled) {
      await updateTrackingState(
        trackingStatus:
            'GPS_DISABLED',
        trackingEnabled: false,
      );

      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission ==
        LocationPermission.denied) {
      permission =
          await Geolocator
              .requestPermission();
    }

    if (permission ==
            LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      await updateTrackingState(
        trackingStatus:
            'LOCATION_PERMISSION_DENIED',
        trackingEnabled: false,
      );

      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final allowed =
        await ensureLocationPermission();

    if (!allowed) {
      return null;
    }

    try {
      return await Geolocator
          .getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
          timeLimit:
              Duration(seconds: 15),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> sendCurrentLocation({
    String eventType = 'HEARTBEAT',
    String? activeGpid,
    String? activityStatus,
  }) async {
    if (_sending) {
      return false;
    }

    final store =
        TrackingSessionStore.instance;

    if (!store.hasActiveSession) {
      return false;
    }

    _sending = true;

    try {
      final position =
          await getCurrentPosition();

      if (position == null) {
        return false;
      }

      final body = <String, dynamic>{
        'userSessionId':
            store.userSessionId,
        'deviceSessionId':
            store.deviceSessionId,
        'latitude':
            position.latitude,
        'longitude':
            position.longitude,
        'accuracy':
            position.accuracy,
        'speed':
            position.speed < 0
                ? 0
                : position.speed,
        'heading':
            position.heading < 0
                ? 0
                : position.heading,
        'locationSource':
            'MOBILE_GPS',
        'activityStatus':
            activityStatus ??
            _activityStatus,
        'activeGpid':
            activeGpid ??
            _activeGpid,
        'eventType':
            eventType,
        'capturedAt':
            position.timestamp
                .toUtc()
                .toIso8601String(),
      };

      final response = await _client
          .post(
            _locationUri,
            headers: const {
              'Accept':
                  'application/json',
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(
            _requestTimeout,
          );

      if (response.statusCode != 201) {
        return false;
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is! Map) {
        return false;
      }

      return decoded['success'] == true;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    } catch (_) {
      return false;
    } finally {
      _sending = false;
    }
  }

  Future<bool> startTracking({
    Duration interval =
        const Duration(
      seconds: 30,
    ),
  }) async {
    if (_trackingStarted) {
      return true;
    }

    final store =
        TrackingSessionStore.instance;

    if (!store.hasActiveSession) {
      return false;
    }

    final allowed =
        await ensureLocationPermission();

    if (!allowed) {
      return false;
    }

    await updateTrackingState(
      trackingStatus:
          'LOCATION_ACTIVE',
      trackingEnabled: true,
    );

    _trackingStarted = true;
    _activityStatus = 'ONLINE';

    await sendCurrentLocation(
      eventType: 'HEARTBEAT',
      activityStatus: 'ONLINE',
    );

    _heartbeatTimer =
        Timer.periodic(
      interval,
      (_) async {
        await sendCurrentLocation(
          eventType: 'HEARTBEAT',
        );
      },
    );

    return true;
  }

  Future<void> stopTracking({
    bool sendFinalLocation = true,
  }) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (
      _trackingStarted &&
      sendFinalLocation
    ) {
      await sendCurrentLocation(
        eventType: 'HEARTBEAT',
        activityStatus: 'OFFLINE',
      );
    }

    _trackingStarted = false;
    _activeGpid = null;
    _activityStatus = 'OFFLINE';

    await updateTrackingState(
      trackingStatus:
          'TRACKING_STOPPED',
      trackingEnabled: false,
    );
  }

  Future<bool> logout() async {
    await stopTracking(
      sendFinalLocation: true,
    );

    return closeTrackingSession();
  }

  Future<bool> startVerification(
    String gpid,
  ) async {
    final trimmed =
        gpid.trim();

    if (trimmed.isEmpty) {
      return false;
    }

    _activeGpid = trimmed;
    _activityStatus = 'VERIFYING';

    return sendCurrentLocation(
      eventType:
          'VERIFICATION_STARTED',
      activeGpid: trimmed,
      activityStatus:
          'VERIFYING',
    );
  }

  Future<bool> confirmLocation(
    String gpid,
  ) async {
    final trimmed =
        gpid.trim();

    if (trimmed.isEmpty) {
      return false;
    }

    _activeGpid = trimmed;
    _activityStatus = 'VERIFYING';

    return sendCurrentLocation(
      eventType:
          'LOCATION_CONFIRMED',
      activeGpid: trimmed,
      activityStatus:
          'VERIFYING',
    );
  }

  Future<bool> markLocationChanged(
    String gpid,
  ) async {
    final trimmed =
        gpid.trim();

    if (trimmed.isEmpty) {
      return false;
    }

    _activeGpid = trimmed;
    _activityStatus = 'VERIFYING';

    return sendCurrentLocation(
      eventType:
          'LOCATION_CHANGED',
      activeGpid: trimmed,
      activityStatus:
          'VERIFYING',
    );
  }

  Future<bool> evidenceCaptured(
    String gpid,
  ) async {
    final trimmed =
        gpid.trim();

    if (trimmed.isEmpty) {
      return false;
    }

    _activeGpid = trimmed;
    _activityStatus = 'VERIFYING';

    return sendCurrentLocation(
      eventType:
          'EVIDENCE_CAPTURED',
      activeGpid: trimmed,
      activityStatus:
          'VERIFYING',
    );
  }

  Future<bool> submission(
    String gpid,
  ) async {
    final trimmed =
        gpid.trim();

    if (trimmed.isEmpty) {
      return false;
    }

    final success =
        await sendCurrentLocation(
      eventType:
          'SUBMISSION',
      activeGpid: trimmed,
      activityStatus:
          'VERIFYING',
    );

    if (success) {
      _activeGpid = null;
      _activityStatus = 'ONLINE';
    }

    return success;
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _client.close();
  }
}