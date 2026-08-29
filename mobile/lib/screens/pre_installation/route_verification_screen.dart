import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class RouteVerificationScreen extends StatefulWidget {
  const RouteVerificationScreen({
    super.key,
  });

  @override
  State<RouteVerificationScreen> createState() =>
      _RouteVerificationScreenState();
}

class _RouteVerificationScreenState
    extends State<RouteVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  final MapController _mapController = MapController();

  // ============================================================
  // ROUTE TRACKING
  // ============================================================

  StreamSubscription<Position>? _positionSubscription;

  final List<LatLng> _routePoints = [];

  bool _isTrackingRoute = false;
  bool _routeCompleted = false;

  DateTime? _routeStartedAt;
  DateTime? _routeEndedAt;

  double? _routeStartLatitude;
  double? _routeStartLongitude;

  double? _routeEndLatitude;
  double? _routeEndLongitude;

  double _routeDistanceMeters = 0;

  // ============================================================
  // GENERAL VERIFICATION
  // ============================================================

  String? _routeAvailable;
  String? _routeType;
  String? _obstructionPresent;
  String? _emergencyMovementPossible;
  String? _sensitivePointsPresent;

  // ============================================================
  // TEXT CONTROLLERS
  // ============================================================

  final TextEditingController _startPointController =
      TextEditingController();

  final TextEditingController _endPointController =
      TextEditingController();

  final TextEditingController _distanceController =
      TextEditingController();

  final TextEditingController _roadWidthController =
      TextEditingController();

  final TextEditingController _obstructionTypeController =
      TextEditingController();

  final TextEditingController _obstructionRemarksController =
      TextEditingController();

  final TextEditingController _sensitivePointController =
      TextEditingController();

  final TextEditingController _remarksController =
      TextEditingController();

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  double? _latitude;
  double? _longitude;

  DateTime? _locationCapturedAt;

  bool _gettingLocation = false;

  // ============================================================
  // ROUTE PHOTO
  // ============================================================

  final ImagePicker _imagePicker = ImagePicker();

  XFile? _routePhoto;

  DateTime? _routePhotoCapturedAt;

  double? _routePhotoLatitude;
  double? _routePhotoLongitude;

  bool _capturingPhoto = false;

  // ============================================================
  // SAVE
  // ============================================================

  bool _saving = false;

  // ============================================================
  // ROUTE TYPES
  // ============================================================

  final List<String> _routeTypes = const [
    'Procession Route',
    'Immersion Route',
    'Vehicle Movement Route',
    'Other',
  ];

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _positionSubscription?.cancel();

    _startPointController.dispose();
    _endPointController.dispose();
    _distanceController.dispose();
    _roadWidthController.dispose();
    _obstructionTypeController.dispose();
    _obstructionRemarksController.dispose();
    _sensitivePointController.dispose();
    _remarksController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOCATION PERMISSION
  // ============================================================

  Future<bool> _ensureLocationPermission() async {
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return false;

      _showMessage(
        'Location service is disabled. Please enable GPS.',
      );

      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) return false;

      _showMessage(
        'Location permission denied.',
      );

      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;

      _showMessage(
        'Location permission is permanently denied. '
        'Please enable location permission from device settings.',
      );

      return false;
    }

    return true;
  }

  // ============================================================
  // CAPTURE CURRENT LOCATION
  // ============================================================

  Future<void> _captureCurrentLocation() async {
    try {
      setState(() {
        _gettingLocation = true;
      });

      final bool permissionGranted =
          await _ensureLocationPermission();

      if (!permissionGranted) {
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;

        _locationCapturedAt = DateTime.now();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        try {
          _mapController.move(
            LatLng(
              position.latitude,
              position.longitude,
            ),
            17,
          );
        } catch (_) {}
      });

      _showMessage(
        'Current route location captured successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to capture location: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // START ROUTE TRACKING
  // ============================================================

  Future<void> _startRouteTracking() async {
    if (_isTrackingRoute) {
      return;
    }

    final bool permissionGranted =
        await _ensureLocationPermission();

    if (!permissionGranted) {
      return;
    }

    try {
      final Position startPosition =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      await _positionSubscription?.cancel();

      if (!mounted) return;

      final LatLng startPoint = LatLng(
        startPosition.latitude,
        startPosition.longitude,
      );

      setState(() {
        _routePoints.clear();

        _routePoints.add(startPoint);

        _routeDistanceMeters = 0;

        _isTrackingRoute = true;
        _routeCompleted = false;

        _routeStartedAt = DateTime.now();
        _routeEndedAt = null;

        _routeStartLatitude =
            startPosition.latitude;

        _routeStartLongitude =
            startPosition.longitude;

        _routeEndLatitude = null;
        _routeEndLongitude = null;

        _latitude =
            startPosition.latitude;

        _longitude =
            startPosition.longitude;

        _locationCapturedAt =
            DateTime.now();

        _distanceController.text =
            '0.00';
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        try {
          _mapController.move(
            startPoint,
            18,
          );
        } catch (_) {}
      });

      const LocationSettings settings =
          LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      );

      _positionSubscription =
          Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        _handleRoutePosition,
        onError: (Object error) {
          if (!mounted) return;

          _showMessage(
            'Route GPS tracking error: $error',
          );
        },
      );

      _showMessage(
        'Route tracking started.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to start route tracking: $e',
      );
    }
  }

  // ============================================================
  // HANDLE LIVE GPS POSITION
  // ============================================================

  void _handleRoutePosition(
    Position position,
  ) {
    if (!_isTrackingRoute ||
        !mounted) {
      return;
    }

    // Ignore very inaccurate GPS points.
    if (position.accuracy > 50) {
      return;
    }

    final LatLng newPoint = LatLng(
      position.latitude,
      position.longitude,
    );

    double additionalDistance = 0;

    if (_routePoints.isNotEmpty) {
      final LatLng previous =
          _routePoints.last;

      additionalDistance =
          Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        newPoint.latitude,
        newPoint.longitude,
      );

      // Ignore GPS drift.
      if (additionalDistance < 2) {
        return;
      }

      // Ignore abnormal GPS jumps.
      if (additionalDistance > 250) {
        return;
      }
    }

    setState(() {
      _routePoints.add(newPoint);

      _routeDistanceMeters +=
          additionalDistance;

      _latitude =
          position.latitude;

      _longitude =
          position.longitude;

      _locationCapturedAt =
          DateTime.now();

      _distanceController.text =
          (_routeDistanceMeters / 1000)
              .toStringAsFixed(2);
    });

    try {
      _mapController.move(
        newPoint,
        18,
      );
    } catch (_) {}
  }

  // ============================================================
  // END ROUTE TRACKING
  // ============================================================

  Future<void> _endRouteTracking() async {
    if (!_isTrackingRoute) {
      return;
    }

    await _positionSubscription?.cancel();

    _positionSubscription = null;

    Position? finalPosition;

    try {
      finalPosition =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
    } catch (_) {
      // Last recorded point will be used.
    }

    if (!mounted) return;

    double? endLatitude;
    double? endLongitude;

    if (finalPosition != null) {
      endLatitude =
          finalPosition.latitude;

      endLongitude =
          finalPosition.longitude;

      if (_routePoints.isNotEmpty) {
        final LatLng previous =
            _routePoints.last;

        final double finalDistance =
            Geolocator.distanceBetween(
          previous.latitude,
          previous.longitude,
          finalPosition.latitude,
          finalPosition.longitude,
        );

        if (finalDistance >= 2 &&
            finalDistance <= 250) {
          _routeDistanceMeters +=
              finalDistance;

          _routePoints.add(
            LatLng(
              finalPosition.latitude,
              finalPosition.longitude,
            ),
          );
        }
      }
    } else if (_routePoints.isNotEmpty) {
      endLatitude =
          _routePoints.last.latitude;

      endLongitude =
          _routePoints.last.longitude;
    }

    setState(() {
      _isTrackingRoute = false;

      _routeCompleted = true;

      _routeEndedAt =
          DateTime.now();

      _routeEndLatitude =
          endLatitude;

      _routeEndLongitude =
          endLongitude;

      if (endLatitude != null &&
          endLongitude != null) {
        _latitude =
            endLatitude;

        _longitude =
            endLongitude;
      }

      _distanceController.text =
          (_routeDistanceMeters / 1000)
              .toStringAsFixed(2);
    });

    _showMessage(
      'Route tracking completed. '
      'Distance: '
      '${(_routeDistanceMeters / 1000).toStringAsFixed(2)} km',
    );
  }

  // ============================================================
  // RESET ROUTE
  // ============================================================

  Future<void> _resetRouteTracking() async {
    await _positionSubscription?.cancel();

    _positionSubscription = null;

    if (!mounted) return;

    setState(() {
      _isTrackingRoute = false;
      _routeCompleted = false;

      _routePoints.clear();

      _routeDistanceMeters = 0;

      _routeStartedAt = null;
      _routeEndedAt = null;

      _routeStartLatitude = null;
      _routeStartLongitude = null;

      _routeEndLatitude = null;
      _routeEndLongitude = null;

      _distanceController.clear();
    });

    _showMessage(
      'Route tracking reset.',
    );
  }

  // ============================================================
  // CAPTURE ROUTE PHOTO
  // ============================================================

  Future<void> _captureRoutePhoto() async {
    try {
      setState(() {
        _capturingPhoto = true;
      });

      final XFile? photo =
          await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice:
            CameraDevice.rear,
        imageQuality: 90,
      );

      if (photo == null) {
        return;
      }

      double? photoLatitude;
      double? photoLongitude;

      try {
        final bool permissionGranted =
            await _ensureLocationPermission();

        if (permissionGranted) {
          final Position position =
              await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(
              accuracy:
                  LocationAccuracy.high,
            ),
          );

          photoLatitude =
              position.latitude;

          photoLongitude =
              position.longitude;
        }
      } catch (_) {
        // Keep photo even if GPS fails.
      }

      if (!mounted) return;

      setState(() {
        _routePhoto = photo;

        _routePhotoCapturedAt =
            DateTime.now();

        _routePhotoLatitude =
            photoLatitude;

        _routePhotoLongitude =
            photoLongitude;
      });

      _showMessage(
        'Route evidence photograph captured successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to capture route photograph: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _capturingPhoto = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE VERIFICATION
  // ============================================================

  void _saveVerification() {
    FocusScope.of(context).unfocus();

    if (_routeAvailable == null) {
      _showMessage(
        'Please select whether the route is available.',
      );

      return;
    }

    // ----------------------------------------------------------
    // ROUTE NOT AVAILABLE
    // ----------------------------------------------------------

    if (_routeAvailable == 'No') {
      if (_remarksController.text
          .trim()
          .isEmpty) {
        _showMessage(
          'Remarks are mandatory when the route '
          'is not available / identified.',
        );

        return;
      }

      _completeSave();

      return;
    }

    // ----------------------------------------------------------
    // ROUTE AVAILABLE
    // ----------------------------------------------------------

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_routeType == null) {
      _showMessage(
        'Please select the route type.',
      );

      return;
    }

    if (!_routeCompleted) {
      _showMessage(
        'Please complete route tracking before saving.',
      );

      return;
    }

    if (_obstructionPresent == null) {
      _showMessage(
        'Please select whether any obstruction '
        'is present on the route.',
      );

      return;
    }

    if (_obstructionPresent == 'Yes' &&
        _obstructionTypeController.text
            .trim()
            .isEmpty) {
      _showMessage(
        'Please enter obstruction details.',
      );

      return;
    }

    if (_emergencyMovementPossible == null) {
      _showMessage(
        'Please verify whether emergency vehicle '
        'movement is possible.',
      );

      return;
    }

    if (_sensitivePointsPresent == null) {
      _showMessage(
        'Please verify sensitive / critical '
        'points on the route.',
      );

      return;
    }

    if (_sensitivePointsPresent == 'Yes' &&
        _sensitivePointController.text
            .trim()
            .isEmpty) {
      _showMessage(
        'Please enter sensitive / critical '
        'point details.',
      );

      return;
    }

    if (_latitude == null ||
        _longitude == null) {
      _showMessage(
        'Please capture the current geo-location.',
      );

      return;
    }

    if (_routePhoto == null) {
      _showMessage(
        'Please capture the route evidence photograph.',
      );

      return;
    }

    _completeSave();
  }

  // ============================================================
  // COMPLETE SAVE
  // ============================================================

  Future<void> _completeSave() async {
    setState(() {
      _saving = true;
    });

    await Future.delayed(
      const Duration(
        milliseconds: 500,
      ),
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    final result = {
      'routeAvailable':
          _routeAvailable,

      'routeType':
          _routeType,

      'startPoint':
          _startPointController.text.trim(),

      'endPoint':
          _endPointController.text.trim(),

      'distance':
          _distanceController.text.trim(),

      'routeDistanceMeters':
          _routeDistanceMeters,

      'roadWidth':
          _roadWidthController.text.trim(),

      'obstructionPresent':
          _obstructionPresent,

      'obstructionType':
          _obstructionTypeController.text.trim(),

      'obstructionRemarks':
          _obstructionRemarksController.text.trim(),

      'emergencyMovementPossible':
          _emergencyMovementPossible,

      'sensitivePointsPresent':
          _sensitivePointsPresent,

      'sensitivePointDetails':
          _sensitivePointController.text.trim(),

      'latitude':
          _latitude,

      'longitude':
          _longitude,

      'locationCapturedAt':
          _locationCapturedAt
              ?.toIso8601String(),

      // ROUTE TRACKING DATA

      'routeStartedAt':
          _routeStartedAt
              ?.toIso8601String(),

      'routeEndedAt':
          _routeEndedAt
              ?.toIso8601String(),

      'routeStartLatitude':
          _routeStartLatitude,

      'routeStartLongitude':
          _routeStartLongitude,

      'routeEndLatitude':
          _routeEndLatitude,

      'routeEndLongitude':
          _routeEndLongitude,

      'routePoints':
          _routePoints
              .map(
                (point) => {
                  'latitude':
                      point.latitude,

                  'longitude':
                      point.longitude,
                },
              )
              .toList(),

      // PHOTO DATA

      'routePhotoPath':
          _routePhoto?.path,

      'routePhotoCapturedAt':
          _routePhotoCapturedAt
              ?.toIso8601String(),

      'routePhotoLatitude':
          _routePhotoLatitude,

      'routePhotoLongitude':
          _routePhotoLongitude,

      'remarks':
          _remarksController.text.trim(),

      'verifiedAt':
          DateTime.now()
              .toIso8601String(),
    };

    _showMessage(
      'Route-Based Verification saved successfully.',
    );

    Navigator.pop(
      context,
      result,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String number,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,

            alignment:
                Alignment.center,

            decoration: BoxDecoration(
              color:
                  const Color(0xFF17365D),

              borderRadius:
                  BorderRadius.circular(8),
            ),

            child: Text(
              number,

              style: const TextStyle(
                color: Colors.white,

                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(
                top: 4,
              ),

              child: Text(
                title,

                style: const TextStyle(
                  fontSize: 16,

                  fontWeight:
                      FontWeight.w700,

                  color:
                      Color(0xFF17365D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // YES / NO
  // ============================================================

  Widget _yesNoSelector({
    required String? value,
    required ValueChanged<String?>
        onChanged,
  }) {
    return RadioGroup<String>(
      groupValue: value,

      onChanged: onChanged,

      child: const Row(
        children: [
          Expanded(
            child:
                RadioListTile<String>(
              contentPadding:
                  EdgeInsets.zero,

              title:
                  Text('YES'),

              value:
                  'Yes',
            ),
          ),

          Expanded(
            child:
                RadioListTile<String>(
              contentPadding:
                  EdgeInsets.zero,

              title:
                  Text('NO'),

              value:
                  'No',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
  }) {
    return InputDecoration(
      labelText:
          label,

      hintText:
          hint,

      filled:
          true,

      fillColor:
          Colors.white,

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),

        borderSide:
            const BorderSide(
          color:
              Color(0xFFD4DAE2),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),

        borderSide:
            const BorderSide(
          color:
              Color(0xFF17365D),

          width:
              1.5,
        ),
      ),
    );
  }

  // ============================================================
  // DATE TIME
  // ============================================================

  String _formatDateTime(
    DateTime? dateTime,
  ) {
    if (dateTime == null) {
      return '-';
    }

    final DateTime local =
        dateTime.toLocal();

    String twoDigits(
      int value,
    ) =>
        value
            .toString()
            .padLeft(2, '0');

    return '${twoDigits(local.day)}-'
        '${twoDigits(local.month)}-'
        '${local.year} '
        '${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}:'
        '${twoDigits(local.second)}';
  }

  // ============================================================
  // ROUTE MAP
  // ============================================================

  Widget _buildRouteMap() {
    if (_latitude == null ||
        _longitude == null) {
      return const SizedBox.shrink();
    }

    final LatLng currentLocation =
        LatLng(
      _latitude!,
      _longitude!,
    );

    final List<Marker> markers = [];

    // Start point
    if (_routePoints.isNotEmpty) {
      markers.add(
        Marker(
          point:
              _routePoints.first,

          width:
              45,

          height:
              45,

          child:
              const Icon(
            Icons.trip_origin,

            size:
                34,

            color:
                Colors.green,
          ),
        ),
      );
    }

    // End point
    if (_routeCompleted &&
        _routePoints.length > 1) {
      markers.add(
        Marker(
          point:
              _routePoints.last,

          width:
              45,

          height:
              45,

          child:
              const Icon(
            Icons.flag,

            size:
                36,

            color:
                Colors.red,
          ),
        ),
      );
    }

    // Current position
    markers.add(
      Marker(
        point:
            currentLocation,

        width:
            50,

        height:
            50,

        child:
            const Icon(
          Icons.location_on,

          size:
              44,

          color:
              Colors.blue,
        ),
      ),
    );

    return Column(
      children: [
        const SizedBox(
          height: 16,
        ),

        Container(
          height:
              350,

          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(12),

            border:
                Border.all(
              color:
                  const Color(
                0xFFD4DAE2,
              ),
            ),
          ),

          clipBehavior:
              Clip.antiAlias,

          child:
              FlutterMap(
            mapController:
                _mapController,

            options:
                MapOptions(
              initialCenter:
                  currentLocation,

              initialZoom:
                  17,
            ),

            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                userAgentPackageName:
                    'in.gov.tspolice.hyderabad.ganesh_bandobust_mobile',
              ),

              // Live route line
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points:
                          _routePoints,

                      strokeWidth:
                          5,

                      color:
                          Colors.blue,
                    ),
                  ],
                ),

              MarkerLayer(
                markers:
                    markers,
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ------------------------------------------------------
        // TRACKING STATUS
        // ------------------------------------------------------

        Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets.all(14),

          decoration:
              BoxDecoration(
            color:
                Colors.white,

            borderRadius:
                BorderRadius.circular(10),

            border:
                Border.all(
              color:
                  const Color(
                0xFFD4DAE2,
              ),
            ),
          ),

          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Icon(
                    _isTrackingRoute
                        ? Icons.gps_fixed
                        : _routeCompleted
                            ? Icons.check_circle
                            : Icons.route,

                    color:
                        _isTrackingRoute
                            ? Colors.green
                            : _routeCompleted
                                ? Colors.green
                                : const Color(
                                    0xFF17365D,
                                  ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child:
                        Text(
                      _isTrackingRoute
                          ? 'ROUTE TRACKING IN PROGRESS'
                          : _routeCompleted
                              ? 'ROUTE TRACKING COMPLETED'
                              : 'ROUTE NOT STARTED',

                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,

                        color:
                            _isTrackingRoute
                                ? Colors.green
                                : _routeCompleted
                                    ? Colors.green
                                    : const Color(
                                        0xFF17365D,
                                      ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                'Distance: '
                '${(_routeDistanceMeters / 1000).toStringAsFixed(2)} km',

                style:
                    const TextStyle(
                  fontSize:
                      17,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                'GPS Points Recorded: '
                '${_routePoints.length}',
              ),

              if (_routeStartedAt != null) ...[
                const SizedBox(
                  height: 4,
                ),

                Text(
                  'Started: '
                  '${_formatDateTime(_routeStartedAt)}',
                ),
              ],

              if (_routeEndedAt != null) ...[
                const SizedBox(
                  height: 4,
                ),

                Text(
                  'Ended: '
                  '${_formatDateTime(_routeEndedAt)}',
                ),
              ],

              if (_routeStartLatitude != null &&
                  _routeStartLongitude != null) ...[
                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Start GPS: '
                  '${_routeStartLatitude!.toStringAsFixed(6)}, '
                  '${_routeStartLongitude!.toStringAsFixed(6)}',
                ),
              ],

              if (_routeEndLatitude != null &&
                  _routeEndLongitude != null) ...[
                const SizedBox(
                  height: 4,
                ),

                Text(
                  'End GPS: '
                  '${_routeEndLatitude!.toStringAsFixed(6)}, '
                  '${_routeEndLongitude!.toStringAsFixed(6)}',
                ),
              ],

              const SizedBox(
                height: 16,
              ),

              // START
              if (!_isTrackingRoute &&
                  !_routeCompleted)
                SizedBox(
                  width:
                      double.infinity,

                  height:
                      50,

                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _startRouteTracking,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.green,

                      foregroundColor:
                          Colors.white,
                    ),

                    icon:
                        const Icon(
                      Icons.play_arrow,
                    ),

                    label:
                        const Text(
                      'START ROUTE',

                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // END
              if (_isTrackingRoute)
                SizedBox(
                  width:
                      double.infinity,

                  height:
                      50,

                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _endRouteTracking,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red,

                      foregroundColor:
                          Colors.white,
                    ),

                    icon:
                        const Icon(
                      Icons.stop,
                    ),

                    label:
                        const Text(
                      'END ROUTE',

                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // RESET
              if (_routeCompleted) ...[
                const SizedBox(
                  height: 10,
                ),

                SizedBox(
                  width:
                      double.infinity,

                  height:
                      48,

                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _resetRouteTracking,

                    icon:
                        const Icon(
                      Icons.refresh,
                    ),

                    label:
                        const Text(
                      'RESET / RECORD AGAIN',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF4F6F9,
      ),

      appBar:
          AppBar(
        backgroundColor:
            const Color(
          0xFF17365D,
        ),

        foregroundColor:
            Colors.white,

        title:
            const Text(
          'Route-Based Verification',
        ),
      ),

      body:
          SafeArea(
        child:
            Form(
          key:
              _formKey,

          child:
              ListView(
            padding:
                const EdgeInsets.all(16),

            children: [
              // =================================================
              // HEADER
              // =================================================

              Container(
                padding:
                    const EdgeInsets.all(16),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius.circular(12),

                  boxShadow:
                      const [
                    BoxShadow(
                      color:
                          Color(0x14000000),

                      blurRadius:
                          8,

                      offset:
                          Offset(0, 2),
                    ),
                  ],
                ),

                child:
                    const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'PRE-INSTALLATION VERIFICATION',

                      style:
                          TextStyle(
                        fontSize:
                            12,

                        color:
                            Colors.grey,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    SizedBox(
                      height:
                          5,
                    ),

                    Text(
                      'Route-Based Verification',

                      style:
                          TextStyle(
                        fontSize:
                            20,

                        fontWeight:
                            FontWeight.bold,

                        color:
                            Color(
                          0xFF17365D,
                        ),
                      ),
                    ),

                    SizedBox(
                      height:
                          7,
                    ),

                    Text(
                      'Verify and physically trace the proposed '
                      'procession / immersion route using GPS.',

                      style:
                          TextStyle(
                        height:
                            1.4,

                        color:
                            Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // =================================================
              // 1 ROUTE AVAILABLE
              // =================================================

              _sectionTitle(
                '1',
                'Route Available / Identified?',
              ),

              _yesNoSelector(
                value:
                    _routeAvailable,

                onChanged:
                    (value) {
                  setState(() {
                    _routeAvailable =
                        value;
                  });
                },
              ),

              if (_routeAvailable == 'No') ...[
                const SizedBox(
                  height: 12,
                ),

                TextFormField(
                  controller:
                      _remarksController,

                  maxLines:
                      4,

                  decoration:
                      _inputDecoration(
                    'Mandatory Remarks',

                    hint:
                        'Explain why the route is not available / identified',
                  ),
                ),
              ],

              // =================================================
              // ROUTE YES
              // =================================================

              if (_routeAvailable == 'Yes') ...[
                // ===============================================
                // 2 ROUTE TYPE
                // ===============================================

                _sectionTitle(
                  '2',
                  'Route Type',
                ),

                DropdownButtonFormField<String>(
                  initialValue:
                      _routeType,

                  decoration:
                      _inputDecoration(
                    'Select Route Type',
                  ),

                  items:
                      _routeTypes
                          .map(
                            (type) =>
                                DropdownMenuItem<String>(
                              value:
                                  type,

                              child:
                                  Text(type),
                            ),
                          )
                          .toList(),

                  onChanged:
                      (value) {
                    setState(() {
                      _routeType =
                          value;
                    });
                  },
                ),

                // ===============================================
                // 3 START / END
                // ===============================================

                _sectionTitle(
                  '3',
                  'Route Start & End Points',
                ),

                TextFormField(
                  controller:
                      _startPointController,

                  decoration:
                      _inputDecoration(
                    'Start Point',

                    hint:
                        'Enter route starting point / landmark',
                  ),

                  validator:
                      (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Start point is required';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 12,
                ),

                TextFormField(
                  controller:
                      _endPointController,

                  decoration:
                      _inputDecoration(
                    'End Point',

                    hint:
                        'Enter route ending point / landmark',
                  ),

                  validator:
                      (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'End point is required';
                    }

                    return null;
                  },
                ),

                // ===============================================
                // 4 GPS DISTANCE
                // ===============================================

                _sectionTitle(
                  '4',
                  'GPS Route Distance',
                ),

                TextFormField(
                  controller:
                      _distanceController,

                  readOnly:
                      true,

                  decoration:
                      _inputDecoration(
                    'GPS Route Distance (KM)',

                    hint:
                        'Automatically calculated during route tracking',
                  ),

                  validator:
                      (value) {
                    if (!_routeCompleted) {
                      return 'Complete route tracking to calculate distance';
                    }

                    return null;
                  },
                ),

                // ===============================================
                // 5 ROAD WIDTH
                // ===============================================

                _sectionTitle(
                  '5',
                  'Minimum Road Width',
                ),

                TextFormField(
                  controller:
                      _roadWidthController,

                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal:
                        true,
                  ),

                  decoration:
                      _inputDecoration(
                    'Minimum Road Width (Feet)',

                    hint:
                        'Enter width at the narrowest point',
                  ),

                  validator:
                      (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Road width is required';
                    }

                    return null;
                  },
                ),

                // ===============================================
                // 6 OBSTRUCTIONS
                // ===============================================

                _sectionTitle(
                  '6',
                  'Any Obstruction on Route?',
                ),

                _yesNoSelector(
                  value:
                      _obstructionPresent,

                  onChanged:
                      (value) {
                    setState(() {
                      _obstructionPresent =
                          value;
                    });
                  },
                ),

                if (_obstructionPresent == 'Yes') ...[
                  const SizedBox(
                    height: 10,
                  ),

                  TextFormField(
                    controller:
                        _obstructionTypeController,

                    decoration:
                        _inputDecoration(
                      'Obstruction Details',

                      hint:
                          'Electric poles, wires, road work, '
                          'narrow lanes, structures, etc.',
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  TextFormField(
                    controller:
                        _obstructionRemarksController,

                    maxLines:
                        3,

                    decoration:
                        _inputDecoration(
                      'Obstruction Remarks',
                    ),
                  ),
                ],

                // ===============================================
                // 7 EMERGENCY VEHICLES
                // ===============================================

                _sectionTitle(
                  '7',
                  'Emergency Vehicle Movement Possible?',
                ),

                _yesNoSelector(
                  value:
                      _emergencyMovementPossible,

                  onChanged:
                      (value) {
                    setState(() {
                      _emergencyMovementPossible =
                          value;
                    });
                  },
                ),

                // ===============================================
                // 8 SENSITIVE POINTS
                // ===============================================

                _sectionTitle(
                  '8',
                  'Sensitive / Critical Points on Route?',
                ),

                _yesNoSelector(
                  value:
                      _sensitivePointsPresent,

                  onChanged:
                      (value) {
                    setState(() {
                      _sensitivePointsPresent =
                          value;
                    });
                  },
                ),

                if (_sensitivePointsPresent == 'Yes') ...[
                  const SizedBox(
                    height: 10,
                  ),

                  TextFormField(
                    controller:
                        _sensitivePointController,

                    maxLines:
                        3,

                    decoration:
                        _inputDecoration(
                      'Sensitive / Critical Point Details',

                      hint:
                          'Mention location and nature of the sensitive point',
                    ),
                  ),
                ],

                // ===============================================
                // 9 GPS + LIVE ROUTE MAP
                // ===============================================

                _sectionTitle(
                  '9',
                  'GPS Route Tracking & Map',
                ),

                Container(
                  padding:
                      const EdgeInsets.all(14),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,

                    borderRadius:
                        BorderRadius.circular(10),

                    border:
                        Border.all(
                      color:
                          const Color(
                        0xFFD4DAE2,
                      ),
                    ),
                  ),

                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      if (_latitude != null &&
                          _longitude != null) ...[
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle,

                              color:
                                  Colors.green,
                            ),

                            SizedBox(
                              width:
                                  7,
                            ),

                            Text(
                              'GPS Location Available',

                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.bold,

                                color:
                                    Colors.green,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height:
                              10,
                        ),

                        Text(
                          'Latitude: '
                          '${_latitude!.toStringAsFixed(6)}',
                        ),

                        Text(
                          'Longitude: '
                          '${_longitude!.toStringAsFixed(6)}',
                        ),

                        Text(
                          'Updated At: '
                          '${_formatDateTime(_locationCapturedAt)}',
                        ),

                        const SizedBox(
                          height:
                              12,
                        ),
                      ],

                      SizedBox(
                        width:
                            double.infinity,

                        child:
                            ElevatedButton.icon(
                          onPressed:
                              _gettingLocation ||
                                      _isTrackingRoute
                                  ? null
                                  : _captureCurrentLocation,

                          icon:
                              _gettingLocation
                                  ? const SizedBox(
                                      width:
                                          18,

                                      height:
                                          18,

                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location,
                                    ),

                          label:
                              Text(
                            _gettingLocation
                                ? 'CAPTURING LOCATION...'
                                : _latitude == null
                                    ? 'CAPTURE CURRENT LOCATION'
                                    : 'REFRESH CURRENT LOCATION',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildRouteMap(),

                // ===============================================
                // 10 PHOTO
                // ===============================================

                _sectionTitle(
                  '10',
                  'Route Evidence Photograph',
                ),

                Container(
                  padding:
                      const EdgeInsets.all(14),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,

                    borderRadius:
                        BorderRadius.circular(12),

                    border:
                        Border.all(
                      color:
                          const Color(
                        0xFFD4DAE2,
                      ),
                    ),
                  ),

                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [
                      if (_routePhoto == null) ...[
                        const SizedBox(
                          height:
                              15,
                        ),

                        const Icon(
                          Icons.camera_alt_outlined,

                          size:
                              50,

                          color:
                              Color(
                            0xFF17365D,
                          ),
                        ),

                        const SizedBox(
                          height:
                              10,
                        ),

                        const Text(
                          'No route evidence photograph captured',

                          textAlign:
                              TextAlign.center,

                          style:
                              TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),

                        const SizedBox(
                          height:
                              15,
                        ),
                      ],

                      if (_routePhoto != null) ...[
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(10),

                          child:
                              Image.file(
                            File(
                              _routePhoto!.path,
                            ),

                            height:
                                220,

                            width:
                                double.infinity,

                            fit:
                                BoxFit.cover,
                          ),
                        ),

                        const SizedBox(
                          height:
                              12,
                        ),

                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle,

                              color:
                                  Colors.green,
                            ),

                            SizedBox(
                              width:
                                  7,
                            ),

                            Expanded(
                              child:
                                  Text(
                                'Evidence Photograph Captured',

                                style:
                                    TextStyle(
                                  color:
                                      Colors.green,

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height:
                              10,
                        ),

                        Text(
                          'Captured At: '
                          '${_formatDateTime(_routePhotoCapturedAt)}',
                        ),

                        Text(
                          'Latitude: '
                          '${_routePhotoLatitude?.toStringAsFixed(6) ?? '-'}',
                        ),

                        Text(
                          'Longitude: '
                          '${_routePhotoLongitude?.toStringAsFixed(6) ?? '-'}',
                        ),

                        const SizedBox(
                          height:
                              10,
                        ),
                      ],

                      SizedBox(
                        height:
                            48,

                        child:
                            ElevatedButton.icon(
                          onPressed:
                              _capturingPhoto
                                  ? null
                                  : _captureRoutePhoto,

                          icon:
                              _capturingPhoto
                                  ? const SizedBox(
                                      width:
                                          18,

                                      height:
                                          18,

                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                    ),

                          label:
                              Text(
                            _capturingPhoto
                                ? 'OPENING CAMERA...'
                                : _routePhoto == null
                                    ? 'CAPTURE ROUTE PHOTO'
                                    : 'RETAKE ROUTE PHOTO',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===============================================
                // 11 REMARKS
                // ===============================================

                _sectionTitle(
                  '11',
                  'Field Officer Remarks',
                ),

                TextFormField(
                  controller:
                      _remarksController,

                  maxLines:
                      4,

                  decoration:
                      _inputDecoration(
                    'Remarks',

                    hint:
                        'Enter additional route verification observations',
                  ),
                ),
              ],

              const SizedBox(
                height:
                    28,
              ),

              // =================================================
              // SAVE
              // =================================================

              SizedBox(
                height:
                    52,

                child:
                    ElevatedButton.icon(
                  onPressed:
                      _saving ||
                              _isTrackingRoute
                          ? null
                          : _saveVerification,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF17365D,
                    ),

                    foregroundColor:
                        Colors.white,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),

                  icon:
                      _saving
                          ? const SizedBox(
                              width:
                                  20,

                              height:
                                  20,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,

                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.save,
                            ),

                  label:
                      Text(
                    _isTrackingRoute
                        ? 'END ROUTE BEFORE SAVING'
                        : _saving
                            ? 'SAVING...'
                            : 'SAVE ROUTE VERIFICATION',

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height:
                    30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}