import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PoliceStationAccess {
  final String? id;

  final String? policeStationCode;
  final String policeStationName;

  final bool canView;
  final bool canEdit;

  const PoliceStationAccess({
    required this.id,
    required this.policeStationCode,
    required this.policeStationName,
    required this.canView,
    required this.canEdit,
  });

  factory PoliceStationAccess.fromJson(
    Map<String, dynamic> json,
  ) {
    return PoliceStationAccess(
      id: json['id']?.toString(),

      policeStationCode:
          json['policeStationCode']?.toString(),

      policeStationName:
          (json['policeStationName'] ?? '')
              .toString()
              .trim(),

      canView:
          json['canView'] == true,

      canEdit:
          json['canEdit'] == true,
    );
  }
}

class AuthenticatedUser {
  final String id;
  final String employeeId;
  final String username;

  final String officerName;
  final String rank;

  final String? phoneNumber;
  final String? team;

  final String role;
  final int accessLevel;

  final String? commissionerateCode;
  final String? commissionerateName;

  final String? rangeCode;
  final String? rangeName;

  final String? zoneCode;
  final String? zoneName;

  final String? divisionCode;
  final String? divisionName;

  final String? policeStationCode;
  final String? policeStationName;

  final String? sectorCode;
  final String? sectorName;

  final bool allPoliceStations;
  final bool allDivisions;
  final bool allZones;
  final bool allRanges;

  final List<PoliceStationAccess>
      allowedPoliceStations;

  final bool canViewLiveTracking;
  final bool mustChangePassword;

  const AuthenticatedUser({
    required this.id,
    required this.employeeId,
    required this.username,
    required this.officerName,
    required this.rank,
    required this.phoneNumber,
    required this.team,
    required this.role,
    required this.accessLevel,
    required this.commissionerateCode,
    required this.commissionerateName,
    required this.rangeCode,
    required this.rangeName,
    required this.zoneCode,
    required this.zoneName,
    required this.divisionCode,
    required this.divisionName,
    required this.policeStationCode,
    required this.policeStationName,
    required this.sectorCode,
    required this.sectorName,
    required this.allPoliceStations,
    required this.allDivisions,
    required this.allZones,
    required this.allRanges,
    required this.allowedPoliceStations,
    required this.canViewLiveTracking,
    required this.mustChangePassword,
  });

  factory AuthenticatedUser.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawJurisdiction =
        json['jurisdiction'];

    final Map<String, dynamic> jurisdiction =
        rawJurisdiction is Map<String, dynamic>
            ? rawJurisdiction
            : <String, dynamic>{};

    final dynamic rawAllowedPoliceStations =
        jurisdiction['allowedPoliceStations'];

    final List<PoliceStationAccess>
        allowedPoliceStations =
        <PoliceStationAccess>[];

    if (rawAllowedPoliceStations is List) {
      for (
        final dynamic item
        in rawAllowedPoliceStations
      ) {
        if (item is Map<String, dynamic>) {
          final PoliceStationAccess access =
              PoliceStationAccess.fromJson(
            item,
          );

          if (
              access.policeStationName
                  .isNotEmpty) {
            allowedPoliceStations.add(
              access,
            );
          }
        }
      }
    }

    return AuthenticatedUser(
      id:
          (json['id'] ?? '')
              .toString(),

      employeeId:
          (json['employeeId'] ?? '')
              .toString(),

      username:
          (json['username'] ?? '')
              .toString(),

      officerName:
          (json['officerName'] ?? '')
              .toString(),

      rank:
          (json['rank'] ?? '')
              .toString(),

      phoneNumber:
          json['phoneNumber']
              ?.toString(),

      team:
          json['team']
              ?.toString(),

      role:
          (json['role'] ?? '')
              .toString(),

      accessLevel:
          (json['accessLevel'] as num?)
                  ?.toInt() ??
              0,

      commissionerateCode:
          jurisdiction[
                  'commissionerateCode']
              ?.toString(),

      commissionerateName:
          jurisdiction[
                  'commissionerateName']
              ?.toString(),

      rangeCode:
          jurisdiction['rangeCode']
              ?.toString(),

      rangeName:
          jurisdiction['rangeName']
              ?.toString(),

      zoneCode:
          jurisdiction['zoneCode']
              ?.toString(),

      zoneName:
          jurisdiction['zoneName']
              ?.toString(),

      divisionCode:
          jurisdiction['divisionCode']
              ?.toString(),

      divisionName:
          jurisdiction['divisionName']
              ?.toString(),

      policeStationCode:
          jurisdiction[
                  'policeStationCode']
              ?.toString(),

      policeStationName:
          jurisdiction[
                  'policeStationName']
              ?.toString(),

      sectorCode:
          jurisdiction['sectorCode']
              ?.toString(),

      sectorName:
          jurisdiction['sectorName']
              ?.toString(),

      allPoliceStations:
          jurisdiction[
                  'allPoliceStations'] ==
              true,

      allDivisions:
          jurisdiction['allDivisions'] ==
              true,

      allZones:
          jurisdiction['allZones'] ==
              true,

      allRanges:
          jurisdiction['allRanges'] ==
              true,

      allowedPoliceStations:
          allowedPoliceStations,

      canViewLiveTracking:
          json['canViewLiveTracking'] ==
              true,

      mustChangePassword:
          json['mustChangePassword'] ==
              true,
    );
  }

  bool get isAdmin =>
      role.toUpperCase() == 'ADMIN';

  List<String>
      get viewablePoliceStationNames {
    return allowedPoliceStations
        .where(
          (PoliceStationAccess access) =>
              access.canView,
        )
        .map(
          (PoliceStationAccess access) =>
              access.policeStationName,
        )
        .where(
          (String value) =>
              value.trim().isNotEmpty,
        )
        .toList();
  }

  List<String>
      get editablePoliceStationNames {
    return allowedPoliceStations
        .where(
          (PoliceStationAccess access) =>
              access.canEdit,
        )
        .map(
          (PoliceStationAccess access) =>
              access.policeStationName,
        )
        .where(
          (String value) =>
              value.trim().isNotEmpty,
        )
        .toList();
  }
}

class LoginResult {
  final bool success;
  final String? error;
  final AuthenticatedUser? user;
  final bool requiresPasswordChange;

  const LoginResult({
    required this.success,
    required this.error,
    required this.user,
    required this.requiresPasswordChange,
  });
}

class ChangePasswordResult {
  final bool success;
  final String? message;
  final String? error;

  const ChangePasswordResult({
    required this.success,
    required this.message,
    required this.error,
  });
}

class AuthService {
  AuthService._();

  static const String _baseUrl =
      'http://13.200.137.199';

  /*
   * The Web authentication API returns an
   * HTTP-only session cookie.
   *
   * A browser stores this automatically.
   * Flutter does not, so we keep the cookie
   * here for subsequent authenticated API calls.
   */
  static String? _sessionCookie;
  
  static String? _pendingUserJson;

  static String? get sessionCookie =>
      _sessionCookie;

  static bool get hasActiveSession =>
      _sessionCookie != null &&
      _sessionCookie!.isNotEmpty;

  static Future<AuthenticatedUser?> restoreSession() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cookie = prefs.getString('session_cookie');
      final String? userJsonStr = prefs.getString('user_profile');

      if (cookie != null && cookie.isNotEmpty && userJsonStr != null && userJsonStr.isNotEmpty) {
        final dynamic userData = jsonDecode(userJsonStr);
        if (userData is Map<String, dynamic>) {
          final AuthenticatedUser user = AuthenticatedUser.fromJson(userData);
          _sessionCookie = cookie;
          return user;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<void> persistSession() async {
    if (_sessionCookie != null && _pendingUserJson != null) {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_cookie', _sessionCookie!);
        await prefs.setString('user_profile', _pendingUserJson!);
      } catch (_) {}
    }
  }

  static Future<LoginResult> login({
    required String employeeId,
    required String password,
  }) async {
    try {
      final http.Response response =
          await http.post(
        Uri.parse(
          '$_baseUrl/api/auth/login',
        ),
        headers: const <String, String>{
          'Content-Type':
              'application/json',
          'Accept':
              'application/json',
        },
        body: jsonEncode(
          <String, dynamic>{
            'username':
                employeeId,
            'password':
                password,
          },
        ),
      );

      Map<String, dynamic> data =
          <String, dynamic>{};

      if (response.body.isNotEmpty) {
        final dynamic decoded =
            jsonDecode(
          response.body,
        );

        if (
            decoded
                is Map<String, dynamic>) {
          data = decoded;
        }
      }

      if (
          response.statusCode != 200) {
        _sessionCookie = null;

        return LoginResult(
          success: false,
          error:
              data['error']
                      ?.toString() ??
                  'Login failed.',
          user: null,
          requiresPasswordChange:
              false,
        );
      }

      /*
       * Capture:
       *
       * ganesh_web_session=xxxxx
       */
      final String? setCookie =
          response
              .headers['set-cookie'];

      if (
          setCookie != null &&
          setCookie.isNotEmpty) {
        final String firstCookiePart =
            setCookie
                .split(';')
                .first
                .trim();

        if (
            firstCookiePart
                .isNotEmpty) {
          _sessionCookie =
              firstCookiePart;
        }
      }

      final dynamic userData =
          data['user'];

      if (
          userData
              is! Map<String, dynamic>) {
        _sessionCookie = null;

        return const LoginResult(
          success: false,
          error:
              'Login response did not contain a valid user profile.',
          user: null,
          requiresPasswordChange:
              false,
        );
      }

      final AuthenticatedUser user =
          AuthenticatedUser.fromJson(
        userData,
      );

      _pendingUserJson = jsonEncode(userData);

      return LoginResult(
        success: true,
        error: null,
        user: user,
        requiresPasswordChange:
            data[
                    'requiresPasswordChange'] ==
                true ||
            user.mustChangePassword,
      );
    } catch (_) {
      _sessionCookie = null;

      return const LoginResult(
        success: false,
        error:
            'Unable to connect to the authentication server.',
        user: null,
        requiresPasswordChange:
            false,
      );
    }
  }

  static Future<ChangePasswordResult>
      changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final String? cookie =
        _sessionCookie;

    if (
        cookie == null ||
        cookie.isEmpty) {
      return const ChangePasswordResult(
        success: false,
        message: null,
        error:
            'Your login session is not available. Please login again.',
      );
    }

    try {
      final http.Response response =
          await http.post(
        Uri.parse(
          '$_baseUrl/api/auth/change-password',
        ),
        headers: <String, String>{
          'Content-Type':
              'application/json',
          'Accept':
              'application/json',
          'Cookie':
              cookie,
        },
        body: jsonEncode(
          <String, dynamic>{
            'currentPassword':
                currentPassword,
            'newPassword':
                newPassword,
          },
        ),
      );

      Map<String, dynamic> data =
          <String, dynamic>{};

      if (response.body.isNotEmpty) {
        final dynamic decoded =
            jsonDecode(
          response.body,
        );

        if (
            decoded
                is Map<String, dynamic>) {
          data = decoded;
        }
      }

      if (
          response.statusCode != 200 ||
          data['success'] != true) {
        return ChangePasswordResult(
          success: false,
          message: null,
          error:
              data['error']
                      ?.toString() ??
                  'Unable to change password.',
        );
      }

      return ChangePasswordResult(
        success: true,
        message:
            data['message']
                    ?.toString() ??
                'Password changed successfully.',
        error: null,
      );
    } catch (_) {
      return const ChangePasswordResult(
        success: false,
        message: null,
        error:
            'Unable to connect to the authentication server.',
      );
    }
  }

  static void clearSession() {
    _sessionCookie = null;
    _pendingUserJson = null;
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      prefs.remove('session_cookie');
      prefs.remove('user_profile');
    }).catchError((_) {});
  }
}