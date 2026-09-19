class TrackingSessionStore {
  TrackingSessionStore._();

  static final TrackingSessionStore instance =
      TrackingSessionStore._();

  String? userSessionId;
  String? deviceSessionId;

  String? userId;
  String? userName;
  String? role;
  String? policeStation;
  String? sector;

  bool get hasActiveSession =>
      userSessionId != null &&
      userSessionId!.isNotEmpty &&
      deviceSessionId != null &&
      deviceSessionId!.isNotEmpty;

  void setSession({
    required String userSessionId,
    required String deviceSessionId,
    required String userId,
    required String userName,
    required String role,
    required String policeStation,
    required String sector,
  }) {
    this.userSessionId = userSessionId;
    this.deviceSessionId = deviceSessionId;
    this.userId = userId;
    this.userName = userName;
    this.role = role;
    this.policeStation = policeStation;
    this.sector = sector;
  }

  void clear() {
    userSessionId = null;
    deviceSessionId = null;
    userId = null;
    userName = null;
    role = null;
    policeStation = null;
    sector = null;
  }
}