import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/verification_api_service.dart';

class RouteVerificationScreen extends StatefulWidget {
  const RouteVerificationScreen({
    super.key,
    required this.applicationId,
    this.gpid,
    this.mandapLatitude,
    this.mandapLongitude,
    this.idolConstructedAtLocation = false,
  });

  final String applicationId;
  final String? gpid;
  final double? mandapLatitude;
  final double? mandapLongitude;
  final bool idolConstructedAtLocation;

  @override
  State<RouteVerificationScreen> createState() =>
      _RouteVerificationScreenState();
}

class _RouteIssueDefinition {
  const _RouteIssueDefinition({
    required this.number,
    required this.title,
    required this.departments,
    this.askRouteImpact = false,
    this.askObstructionType = false,
  });

  final int number;
  final String title;
  final List<String> departments;
  final bool askRouteImpact;
  final bool askObstructionType;
}

class _RouteIssueData {
  _RouteIssueData(this.definition);

  final _RouteIssueDefinition definition;

  String? noticed;
  String? routeImpact;
  String? obstructionType;
  String obstructionOther = '';

  double? latitude;
  double? longitude;
  DateTime? capturedAt;

  String? informRequired;
  String? informed;

  String? department;
  String privateAgency = '';
  String trafficPoliceStation = '';

  String name = '';
  String rank = '';
  String cellNo = '';
  String remarks = '';

  bool saved = false;

  Map<String, dynamic> toMap() {
    return {
      'pointNo': definition.number,
      'title': definition.title,
      'noticed': noticed,
      'routeImpact': routeImpact,
      'obstructionType': obstructionType,
      'obstructionOther': obstructionOther,
      'latitude': latitude,
      'longitude': longitude,
      'capturedAt': capturedAt?.toIso8601String(),
      'informRequired': informRequired,
      'informed': informed,
      'department': department,
      'privateAgency': privateAgency,
      'trafficPoliceStation': trafficPoliceStation,
      'name': name,
      'rank': rank,
      'cellNo': cellNo,
      'remarks': remarks,
      'saved': saved,
    };
  }
}

class _RouteStretch {
  _RouteStretch({
    required this.index,
    required this.pointName,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    required this.issues,
  });

  final int index;
  final String pointName;
  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final List<_RouteIssueData> issues;

  String? reachedMandap;

  Map<String, dynamic> toMap() {
    return {
      'stretchNo': index,
      'pointName': pointName,
      'latitude': latitude,
      'longitude': longitude,
      'capturedAt': capturedAt.toIso8601String(),
      'reachedMandap': reachedMandap,
      'issues': issues.map((e) => e.toMap()).toList(),
    };
  }
}

class _RouteVerificationScreenState extends State<RouteVerificationScreen> {
  final MapController _mapController = MapController();

  final TextEditingController _notVerifiedRemarksController =
      TextEditingController();
  final TextEditingController _enteringPointController =
      TextEditingController();
  final TextEditingController _furtherPointController =
      TextEditingController();

  String? _installationRouteVerified;
  String? _constructedAtLocationProcessionRouteVerified;

  double? _enteringLatitude;
  double? _enteringLongitude;
  DateTime? _enteringCapturedAt;

  bool _capturingLocation = false;
  bool _saving = false;

  final List<_RouteStretch> _stretches = [];

  String get _selectedGpid {
    final String value =
        (widget.gpid ?? widget.applicationId).trim();

    return value.isEmpty
        ? widget.applicationId
        : value;
  }

  static const List<_RouteIssueDefinition> _issueDefinitions = [
    _RouteIssueDefinition(
      number: 3,
      title: 'Hanging Wires Noticed?',
      departments: [
        'TGSPDCL',
        'Electrical - GHMC',
        'POLICE',
        'PRIVATE',
      ],
    ),
    _RouteIssueDefinition(
      number: 4,
      title: 'Obstructive Tree Branches Noticed?',
      departments: [
        'GHMC - Horticulture',
        'HYDRAA',
        'NDRF',
        'POLICE',
        'PRIVATE',
      ],
    ),
    _RouteIssueDefinition(
      number: 5,
      title: 'Pot Holes Noticed?',
      departments: [
        'GHMC - Engineering',
        'GHMC - CRMP',
        'HMDA',
        'R&B',
        'NHAI',
        'POLICE',
        'PRIVATE',
      ],
    ),
    _RouteIssueDefinition(
      number: 6,
      title: 'Open Manholes / Drainage Openings Noticed?',
      departments: [
        'GHMC - Engineering',
        'GHMC - Sewerage',
        'HMWSSB',
        'HYDRAA',
        'POLICE',
        'PRIVATE',
      ],
    ),
    _RouteIssueDefinition(
      number: 7,
      title: 'Waterlogging / Stagnant Water Noticed on the Route?',
      departments: [
        'GHMC - Engineering',
        'GHMC - Sanitation',
        'HMWSSB',
        'HYDRAA',
        'POLICE',
        'PRIVATE',
      ],
    ),
    _RouteIssueDefinition(
      number: 8,
      title: 'Road Excavation / Construction Work Noticed on the Route?',
      departments: [
        'GHMC - Engineering',
        'HMWSSB',
        'HMDA',
        'R&B',
        'NHAI',
        'HYDRAA',
        'POLICE',
        'PRIVATE',
      ],
      askRouteImpact: true,
    ),
    _RouteIssueDefinition(
      number: 9,
      title:
          'Temporary Structures / Encroachments Obstructing the Route Noticed?',
      departments: [
        'GHMC - Enforcement',
        'HYDRAA',
        'Traffic Police',
        'Law & Order Police',
        'PRIVATE',
      ],
    ),
    _RouteIssueDefinition(
      number: 10,
      title:
          'Road-Side Obstructions Affecting Idol / Vehicle Movement Noticed?',
      departments: [
        'GHMC',
        'Traffic Police',
        'Law & Order Police',
        'HYDRAA',
        'PRIVATE',
      ],
      askObstructionType: true,
    ),
  ];

  static const List<String> _obstructionTypes = [
    'Parked Vehicle',
    'Abandoned Vehicle',
    'Construction Material',
    'Debris',
    'Dumped Material',
    'Movable Object / Temporary Obstruction',
    'Other',
  ];

  @override
  void dispose() {
    _notVerifiedRemarksController.dispose();
    _enteringPointController.dispose();
    _furtherPointController.dispose();
    super.dispose();
  }

  List<_RouteIssueData> _newIssues() {
    return _issueDefinitions.map((e) => _RouteIssueData(e)).toList();
  }

  Future<bool> _ensureLocationPermission() async {
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showMessage('Please switch ON GPS / Location Services.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showMessage('Location permission denied.');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage(
        'Location permission is permanently denied. '
        'Please enable it from phone settings.',
      );
      return false;
    }

    return true;
  }

  Future<Position?> _getCurrentPosition() async {
    if (!await _ensureLocationPermission()) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      _showMessage('Unable to capture geo-location.');
      return null;
    }
  }

  Future<void> _captureEnteringPoint() async {
    final String pointName = _enteringPointController.text.trim();

    if (pointName.isEmpty) {
      _showMessage(
        'Please enter the Entering Point Name / Description.',
      );
      return;
    }

    setState(() => _capturingLocation = true);

    final Position? position = await _getCurrentPosition();

    if (!mounted) return;

    setState(() => _capturingLocation = false);

    if (position == null) return;

    final DateTime now = DateTime.now();

    setState(() {
      _enteringLatitude = position.latitude;
      _enteringLongitude = position.longitude;
      _enteringCapturedAt = now;

      _stretches
        ..clear()
        ..add(
          _RouteStretch(
            index: 1,
            pointName: pointName,
            latitude: position.latitude,
            longitude: position.longitude,
            capturedAt: now,
            issues: _newIssues(),
          ),
        );
    });

    _moveMap(position.latitude, position.longitude);
    _showMessage('Entering Point geo-location captured.');
  }

  Future<void> _captureIssueLocation(_RouteIssueData issue) async {
    final Position? position = await _getCurrentPosition();

    if (!mounted || position == null) return;

    setState(() {
      issue.latitude = position.latitude;
      issue.longitude = position.longitude;
      issue.capturedAt = DateTime.now();
      issue.saved = false;
    });

    _moveMap(position.latitude, position.longitude);
    _showMessage('Issue geo-location captured.');
  }

  bool _vehicleObstruction(_RouteIssueData issue) {
    return issue.obstructionType == 'Parked Vehicle' ||
        issue.obstructionType == 'Abandoned Vehicle';
  }

  bool _validateIssue(_RouteIssueData issue) {
    if (issue.noticed == null) {
      _showMessage('Please answer Point ${issue.definition.number}.');
      return false;
    }

    if (issue.noticed == 'NO') {
      return true;
    }

    if (issue.definition.askRouteImpact) {
      if (issue.routeImpact == null) {
        _showMessage(
          'Please confirm whether the excavation affects the route.',
        );
        return false;
      }

      if (issue.routeImpact == 'NO') {
        return true;
      }
    }

    if (issue.definition.askObstructionType) {
      if (issue.obstructionType == null) {
        _showMessage('Please select Type of Obstruction.');
        return false;
      }

      if (issue.obstructionType == 'Other' &&
          issue.obstructionOther.trim().isEmpty) {
        _showMessage('Please specify the obstruction.');
        return false;
      }
    }

    if (issue.latitude == null || issue.longitude == null) {
      _showMessage(
        'Please capture the geo-location for Point '
        '${issue.definition.number}.',
      );
      return false;
    }

    if (issue.informRequired == null) {
      _showMessage(
        'Please answer whether the concerned authority '
        'is required to be informed.',
      );
      return false;
    }

    if (issue.informRequired == 'NO') {
      return true;
    }

    if (issue.informed == null) {
      _showMessage('Please answer: Informed to the concerned?');
      return false;
    }

    if (issue.informed == 'NO') {
      if (issue.remarks.trim().isEmpty) {
        _showMessage(
          'Remarks / Reason is mandatory when not informed.',
        );
        return false;
      }
      return true;
    }

    if (issue.department == null || issue.department!.trim().isEmpty) {
      _showMessage('Please select Department.');
      return false;
    }

    if (issue.department == 'PRIVATE' &&
        issue.privateAgency.trim().isEmpty) {
      _showMessage(
        'Please enter Private Agency / Organisation Name.',
      );
      return false;
    }

    if (_vehicleObstruction(issue) &&
        issue.trafficPoliceStation.trim().isEmpty) {
      _showMessage(
        'Please enter / select the concerned Traffic Police Station.',
      );
      return false;
    }

    if (issue.name.trim().isEmpty ||
        issue.rank.trim().isEmpty ||
        issue.cellNo.trim().isEmpty) {
      _showMessage(
        'Please enter Name, Rank / Designation and Cell No.',
      );
      return false;
    }

    return true;
  }

  Future<void> _saveIssue(_RouteIssueData issue) async {
    if (!_validateIssue(issue)) return;

    final bool confirmed = await _showConfirmation(
      title: 'Confirmation',
      message:
          'I have personally verified the above details and confirm '
          'that the information entered is correct.',
    );

    if (!confirmed || !mounted) return;

    setState(() => issue.saved = true);
    _showMessage('Point ${issue.definition.number} saved.');
  }

  bool _validateAllIssues(_RouteStretch stretch) {
    for (final _RouteIssueData issue in stretch.issues) {
      if (!_validateIssue(issue)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _setReachedMandap(
    _RouteStretch stretch,
    String value,
  ) async {
    if (!_validateAllIssues(stretch)) return;

    if (value == 'NO') {
      setState(() {
        stretch.reachedMandap = 'NO';
        _furtherPointController.clear();
      });
      return;
    }

    final Position? current = await _getCurrentPosition();

    if (!mounted || current == null) return;

    if (widget.mandapLatitude == null ||
        widget.mandapLongitude == null) {
      _showMessage(
        'Mandap pre-tagged geo-location is not yet connected '
        'to this screen.',
      );
      return;
    }

    final double distance = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      widget.mandapLatitude!,
      widget.mandapLongitude!,
    );

    const double allowedDistanceMeters = 50;

    if (distance > allowedDistanceMeters) {
      _showMessage(
        'Mandap geo-location not matched. '
        'Current location is ${distance.toStringAsFixed(0)} metres away.',
      );
      return;
    }

    final bool confirmed = await _showConfirmation(
      title: 'Mandap Geo-Location Matched',
      message:
          'The present location matches the pre-tagged Mandap '
          'geo-location. Save this point and complete the route?',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      stretch.reachedMandap = 'YES';
    });

    _showMessage('Route reached Mandap and geo-location matched.');
  }

  Future<void> _captureFurtherPoint() async {
    final String name = _furtherPointController.text.trim();

    if (name.isEmpty) {
      _showMessage(
        'Please enter Further Point Name / Description.',
      );
      return;
    }

    setState(() => _capturingLocation = true);

    final Position? position = await _getCurrentPosition();

    if (!mounted) return;

    setState(() => _capturingLocation = false);

    if (position == null) return;

    setState(() {
      _stretches.add(
        _RouteStretch(
          index: _stretches.length + 1,
          pointName: name,
          latitude: position.latitude,
          longitude: position.longitude,
          capturedAt: DateTime.now(),
          issues: _newIssues(),
        ),
      );

      _furtherPointController.clear();
    });

    _moveMap(position.latitude, position.longitude);

    _showMessage(
      'Next / deviation point captured. '
      'Points 3 to 10 are displayed again.',
    );
  }

  Future<bool> _saveRouteResult(
    Map<String, dynamic> result,
  ) async {
    if (!mounted) return false;

    setState(() => _saving = true);

    try {
      await VerificationApiService.saveModuleResult(
        applicationId: widget.applicationId,
        gpid: _selectedGpid,
        moduleKey: 'routeResult',
        result: result,
      );

      if (!mounted) return false;

      setState(() => _saving = false);

      _showMessage(
        'Route-Based Verification saved successfully.',
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      setState(() => _saving = false);

      _showMessage(
        'Unable to save Route Verification to the server. '
        'Please check the network and try again.',
      );

      return false;
    }
  }

  Future<void> _saveRouteVerification() async {
    if (widget.idolConstructedAtLocation &&
        _constructedAtLocationProcessionRouteVerified == null) {
      _showMessage(
        'Please answer whether route for procession is verified '
        'for the Idol constructed at location.',
      );
      return;
    }

    if (_installationRouteVerified == null) {
      _showMessage('Please answer: Installation Route Verified?');
      return;
    }

    if (_installationRouteVerified == 'NO') {
      if (_notVerifiedRemarksController.text.trim().isEmpty) {
        _showMessage(
          'Remarks are mandatory when Installation Route Verified is NO.',
        );
        return;
      }

      final bool confirmed = await _showConfirmation(
        title: 'Confirmation',
        message:
            'I have personally verified the above details and confirm '
            'that the information entered is correct.',
      );

      if (!confirmed || !mounted) return;

      final Map<String, dynamic> result = {
        'applicationId': widget.applicationId,
        'gpid': _selectedGpid,
        'idolConstructedAtLocation':
            widget.idolConstructedAtLocation,
        'constructedAtLocationProcessionRouteVerified':
            _constructedAtLocationProcessionRouteVerified,
        'installationRouteVerified': 'NO',
        'remarks': _notVerifiedRemarksController.text.trim(),
        'verifiedAt': DateTime.now().toIso8601String(),
      };

      final bool saved = await _saveRouteResult(result);

      if (!saved || !mounted) return;

      Navigator.pop(
        context,
        result,
      );
      return;
    }

    if (_stretches.isEmpty ||
        _enteringLatitude == null ||
        _enteringLongitude == null) {
      _showMessage('Please capture the Entering Point geo-location.');
      return;
    }

    final _RouteStretch lastStretch = _stretches.last;

    if (!_validateAllIssues(lastStretch)) return;

    if (lastStretch.reachedMandap != 'YES') {
      _showMessage(
        'The route can be completed only after '
        'Route Ended / Reached Mandap = YES.',
      );
      return;
    }

    final bool confirmed = await _showConfirmation(
      title: 'Final Route Confirmation',
      message:
          'I have personally verified the complete Installation Route '
          'and confirm that the information entered is correct.',
    );

    if (!confirmed || !mounted) return;

    final Map<String, dynamic> result = {
      'applicationId': widget.applicationId,
      'gpid': _selectedGpid,
      'idolConstructedAtLocation':
          widget.idolConstructedAtLocation,
      'constructedAtLocationProcessionRouteVerified':
          _constructedAtLocationProcessionRouteVerified,
      'installationRouteVerified': 'YES',
      'enteringPoint': {
        'name': _enteringPointController.text.trim(),
        'latitude': _enteringLatitude,
        'longitude': _enteringLongitude,
        'capturedAt': _enteringCapturedAt?.toIso8601String(),
      },
      'routeStretches':
          _stretches.map((stretch) => stretch.toMap()).toList(),

      // These observations are intended to be stored at ROUTE level
      // so the same geo-tagged issue can be shown automatically for
      // every idol using the same route/common route stretch.
      'recordScope': 'ROUTE_LEVEL',
      'shareWithLinkedIdols': true,

      'verifiedAt': DateTime.now().toIso8601String(),
    };

    final bool saved = await _saveRouteResult(result);

    if (!saved || !mounted) return;

    Navigator.pop(
      context,
      result,
    );
  }

  Future<bool> _showConfirmation({
    required String title,
    required String message,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('CONFIRM & SAVE'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _moveMap(double latitude, double longitude) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        _mapController.move(
          LatLng(latitude, longitude),
          17,
        );
      } catch (_) {}
    });
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFD8DEE8),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF17365D),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _pointHeader(
    int number,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF17365D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17365D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _yesNoSelector({
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const SizedBox(
              width: double.infinity,
              child: Text(
                'YES',
                textAlign: TextAlign.center,
              ),
            ),
            selected: value == 'YES',
            onSelected: (_) => onChanged('YES'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const SizedBox(
              width: double.infinity,
              child: Text(
                'NO',
                textAlign: TextAlign.center,
              ),
            ),
            selected: value == 'NO',
            onSelected: (_) => onChanged('NO'),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';

    final DateTime local = value.toLocal();

    String two(int v) => v.toString().padLeft(2, '0');

    return '${two(local.day)}-${two(local.month)}-${local.year} '
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  Widget _locationBox({
    required double? latitude,
    required double? longitude,
    required DateTime? time,
  }) {
    if (latitude == null || longitude == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(
          color: Colors.green.shade200,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Geo-Location Captured\n'
        'Latitude: ${latitude.toStringAsFixed(6)}\n'
        'Longitude: ${longitude.toStringAsFixed(6)}\n'
        'Date & Time: ${_formatDateTime(time)}',
      ),
    );
  }

  Widget _buildMap() {
    final List<Marker> markers = [];
    final List<LatLng> routePoints = [];

    if (_enteringLatitude != null &&
        _enteringLongitude != null) {
      final LatLng entering = LatLng(
        _enteringLatitude!,
        _enteringLongitude!,
      );

      routePoints.add(entering);

      markers.add(
        Marker(
          point: entering,
          width: 48,
          height: 48,
          child: const Icon(
            Icons.login,
            color: Colors.green,
            size: 40,
          ),
        ),
      );
    }

    for (final _RouteStretch stretch in _stretches.skip(1)) {
      final LatLng point = LatLng(
        stretch.latitude,
        stretch.longitude,
      );

      routePoints.add(point);

      markers.add(
        Marker(
          point: point,
          width: 46,
          height: 46,
          child: const Icon(
            Icons.alt_route,
            color: Colors.orange,
            size: 38,
          ),
        ),
      );
    }

    for (final _RouteStretch stretch in _stretches) {
      for (final _RouteIssueData issue in stretch.issues) {
        if (issue.latitude != null &&
            issue.longitude != null) {
          markers.add(
            Marker(
              point: LatLng(
                issue.latitude!,
                issue.longitude!,
              ),
              width: 40,
              height: 40,
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 34,
              ),
            ),
          );
        }
      }
    }

    if (widget.mandapLatitude != null &&
        widget.mandapLongitude != null) {
      markers.add(
        Marker(
          point: LatLng(
            widget.mandapLatitude!,
            widget.mandapLongitude!,
          ),
          width: 52,
          height: 52,
          child: const Icon(
            Icons.temple_hindu,
            color: Colors.deepPurple,
            size: 44,
          ),
        ),
      );
    }

    if (routePoints.isEmpty &&
        widget.mandapLatitude == null) {
      return const SizedBox.shrink();
    }

    final LatLng center = routePoints.isNotEmpty
        ? routePoints.last
        : LatLng(
            widget.mandapLatitude!,
            widget.mandapLongitude!,
          );

    return Container(
      height: 300,
      margin: const EdgeInsets.only(top: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFD8DEE8),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 16,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName:
                'in.gov.tspolice.hyderabad.ganesh_bandobust_mobile',
          ),
          if (routePoints.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  strokeWidth: 5,
                  color: Colors.blue,
                ),
              ],
            ),
          MarkerLayer(
            markers: markers,
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(
    _RouteIssueData issue,
  ) {
    final bool needsDetails =
        issue.noticed == 'YES' &&
        (!issue.definition.askRouteImpact ||
            issue.routeImpact == 'YES');

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: issue.saved
              ? Colors.green.shade300
              : const Color(0xFFD8DEE8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${issue.definition.number}. '
            '${issue.definition.title}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF17365D),
            ),
          ),
          const SizedBox(height: 10),

          _yesNoSelector(
            value: issue.noticed,
            onChanged: (String value) {
              setState(() {
                issue.noticed = value;
                issue.saved = false;
              });
            },
          ),

          if (issue.noticed == 'YES' &&
              issue.definition.askRouteImpact) ...[
            const SizedBox(height: 14),
            const Text(
              'Is it likely to obstruct / affect the Installation Route?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            _yesNoSelector(
              value: issue.routeImpact,
              onChanged: (String value) {
                setState(() {
                  issue.routeImpact = value;
                  issue.saved = false;
                });
              },
            ),
          ],

          if (issue.noticed == 'YES' &&
              issue.definition.askObstructionType) ...[
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: issue.obstructionType,
              decoration:
                  _inputDecoration('Type of Obstruction'),
              isExpanded: true,
              items: _obstructionTypes
                  .map(
                    (String item) =>
                        DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                setState(() {
                  issue.obstructionType = value;
                  issue.saved = false;

                  if (value == 'Parked Vehicle' ||
                      value == 'Abandoned Vehicle') {
                    issue.department = 'Traffic Police';
                  }
                });
              },
            ),

            if (issue.obstructionType == 'Other') ...[
              const SizedBox(height: 10),

              TextFormField(
                initialValue: issue.obstructionOther,
                decoration:
                    _inputDecoration('Specify Obstruction'),
                onChanged: (String value) {
                  issue.obstructionOther = value;
                },
              ),
            ],
          ],

          if (needsDetails) ...[
            const SizedBox(height: 14),

            ElevatedButton.icon(
              onPressed: () =>
                  _captureIssueLocation(issue),
              icon: const Icon(Icons.my_location),
              label: Text(
                issue.latitude == null
                    ? 'CAPTURE ISSUE GEO-LOCATION'
                    : 'REFRESH ISSUE GEO-LOCATION',
              ),
            ),

            _locationBox(
              latitude: issue.latitude,
              longitude: issue.longitude,
              time: issue.capturedAt,
            ),

            const SizedBox(height: 14),

            const Text(
              'Required to inform the concerned for '
              'removal / rectification / clearance?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            _yesNoSelector(
              value: issue.informRequired,
              onChanged: (String value) {
                setState(() {
                  issue.informRequired = value;
                  issue.saved = false;
                });
              },
            ),

            if (issue.informRequired == 'YES') ...[
              const SizedBox(height: 14),

              const Text(
                'Informed to the concerned?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              _yesNoSelector(
                value: issue.informed,
                onChanged: (String value) {
                  setState(() {
                    issue.informed = value;
                    issue.saved = false;
                  });
                },
              ),

              if (issue.informed == 'NO') ...[
                const SizedBox(height: 12),

                TextFormField(
                  initialValue: issue.remarks,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    'Mandatory Remarks / Reason',
                    hint:
                        'Explain why the concerned authority was not informed',
                  ),
                  onChanged: (String value) {
                    issue.remarks = value;
                  },
                ),
              ],

              if (issue.informed == 'YES') ...[
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: issue.department,
                  decoration:
                      _inputDecoration('Department'),
                  isExpanded: true,
                  items: issue.definition.departments
                      .map(
                        (String item) =>
                            DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: _vehicleObstruction(issue)
                      ? null
                      : (String? value) {
                          setState(() {
                            issue.department = value;
                            issue.saved = false;
                          });
                        },
                ),

                if (issue.department == 'PRIVATE') ...[
                  const SizedBox(height: 10),

                  TextFormField(
                    initialValue: issue.privateAgency,
                    decoration: _inputDecoration(
                      'Private Agency / Organisation Name',
                    ),
                    onChanged: (String value) {
                      issue.privateAgency = value;
                    },
                  ),
                ],

                if (_vehicleObstruction(issue)) ...[
                  const SizedBox(height: 10),

                  TextFormField(
                    initialValue:
                        issue.trafficPoliceStation,
                    decoration: _inputDecoration(
                      'Traffic Police Station',
                      hint:
                          'Search / enter concerned Traffic Police Station',
                    ),
                    onChanged: (String value) {
                      issue.trafficPoliceStation = value;
                    },
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Traffic Police is selected automatically for '
                    'Parked / Abandoned Vehicle. '
                    'The Hyderabad Traffic PS master list and '
                    'geo-jurisdiction auto-suggestion will be '
                    'connected to master data.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                TextFormField(
                  initialValue: issue.name,
                  decoration:
                      _inputDecoration('Name'),
                  onChanged: (String value) {
                    issue.name = value;
                  },
                ),

                const SizedBox(height: 10),

                TextFormField(
                  initialValue: issue.rank,
                  decoration: _inputDecoration(
                    'Rank / Designation',
                  ),
                  onChanged: (String value) {
                    issue.rank = value;
                  },
                ),

                const SizedBox(height: 10),

                TextFormField(
                  initialValue: issue.cellNo,
                  keyboardType: TextInputType.phone,
                  decoration:
                      _inputDecoration('Cell No.'),
                  onChanged: (String value) {
                    issue.cellNo = value;
                  },
                ),
              ],
            ],
          ],

          const SizedBox(height: 14),

          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => _saveIssue(issue),
              icon: Icon(
                issue.saved
                    ? Icons.check_circle
                    : Icons.save,
              ),
              label: Text(
                issue.saved ? 'SAVED' : 'SAVE',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStretch(
    _RouteStretch stretch,
    int index,
  ) {
    final bool isLast = index == _stretches.length - 1;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFBEC9D8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            stretch.index == 1
                ? 'ROUTE STRETCH 1 - FROM ENTERING POINT'
                : 'ROUTE STRETCH ${stretch.index} - '
                    'FROM NEXT / DEVIATION POINT',
            style: const TextStyle(
              color: Color(0xFF17365D),
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            stretch.pointName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            '${stretch.latitude.toStringAsFixed(6)}, '
            '${stretch.longitude.toStringAsFixed(6)}  |  '
            '${_formatDateTime(stretch.capturedAt)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),

          for (final _RouteIssueData issue in stretch.issues)
            _buildIssueCard(issue),

          _pointHeader(
            11,
            'Route Ended / Reached Mandap?',
          ),

          _yesNoSelector(
            value: stretch.reachedMandap,
            onChanged: (String value) {
              _setReachedMandap(
                stretch,
                value,
              );
            },
          ),

          if (stretch.reachedMandap == 'YES') ...[
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.temple_hindu,
                    color: Colors.green,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mandap geo-location matched. '
                      'Route reached Mandap.',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (stretch.reachedMandap == 'NO' &&
              isLast) ...[
            const SizedBox(height: 14),

            TextFormField(
              controller: _furtherPointController,
              decoration: _inputDecoration(
                'Further Point Name / Description',
                hint:
                    'Enter next point from where the route takes deviation',
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _capturingLocation
                    ? null
                    : _captureFurtherPoint,
                icon:
                    const Icon(Icons.add_location_alt),
                label: Text(
                  _capturingLocation
                      ? 'CAPTURING GEO-LOCATION...'
                      : 'CAPTURE NEXT POINT & CONTINUE',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
        title: const Text(
          'Route-Based Verification',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRE-INSTALLATION VERIFICATION',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Installation Route Verification',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF17365D),
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Verify the installation route stretch-by-stretch, '
                    'capture geo-location of every issue and reuse the '
                    'same route-level observations for idols travelling '
                    'through the same route.',
                    style: TextStyle(
                      height: 1.4,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            if (widget.idolConstructedAtLocation) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE7C46A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Since this Idol is constructed at the location, '
                      'whether route for procession verified?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17365D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _yesNoSelector(
                      value:
                          _constructedAtLocationProcessionRouteVerified,
                      onChanged: (String value) {
                        setState(() {
                          _constructedAtLocationProcessionRouteVerified =
                              value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],

            _pointHeader(
              1,
              'Installation Route Verified?',
            ),

            _yesNoSelector(
              value: _installationRouteVerified,
              onChanged: (String value) {
                setState(() {
                  _installationRouteVerified = value;
                });
              },
            ),

            if (_installationRouteVerified == 'NO') ...[
              const SizedBox(height: 12),

              TextFormField(
                controller: _notVerifiedRemarksController,
                maxLines: 4,
                decoration: _inputDecoration(
                  'Mandatory Remarks',
                  hint:
                      'Enter reason why the Installation Route is not verified',
                ),
              ),
            ],

            if (_installationRouteVerified == 'YES') ...[
              _pointHeader(
                2,
                'Entering Point in this Police Station',
              ),

              TextFormField(
                controller: _enteringPointController,
                decoration: _inputDecoration(
                  'Entering Point Name / Description',
                  hint:
                      'Enter landmark / road / junction name',
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _capturingLocation
                      ? null
                      : _captureEnteringPoint,
                  icon:
                      const Icon(Icons.my_location),
                  label: Text(
                    _capturingLocation
                        ? 'CAPTURING GEO-LOCATION...'
                        : _enteringLatitude == null
                            ? 'CAPTURE ENTERING POINT GEO-LOCATION'
                            : 'REFRESH ENTERING POINT GEO-LOCATION',
                  ),
                ),
              ),

              _locationBox(
                latitude: _enteringLatitude,
                longitude: _enteringLongitude,
                time: _enteringCapturedAt,
              ),

              _buildMap(),

              if (_stretches.isNotEmpty)
                for (int i = 0; i < _stretches.length; i++)
                  _buildStretch(
                    _stretches[i],
                    i,
                  ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    _saving ? null : _saveRouteVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF17365D),
                  foregroundColor: Colors.white,
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _saving
                      ? 'SAVING...'
                      : 'SAVE ROUTE VERIFICATION',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
