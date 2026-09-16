import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../festivity/festivity_check_screen.dart';

class MapBasedCheckingScreen extends StatefulWidget {
  final List<Map<String, dynamic>> authorizedRecords;

  const MapBasedCheckingScreen({
    super.key,
    required this.authorizedRecords,
  });

  @override
  State<MapBasedCheckingScreen> createState() =>
      _MapBasedCheckingScreenState();
}

class _MapBasedCheckingScreenState extends State<MapBasedCheckingScreen> {
  static const String _geoMasterUrl =
      'http://13.200.137.199/api/festivity/gpid-master';

  final MapController _mapController = MapController();

  bool _loading = true;
  bool _locatingOfficer = false;
  String? _errorMessage;

  Position? _officerPosition;

  List<Map<String, dynamic>> _geoRecords = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selectedRecord;

  String _text(dynamic value) {
    if (value == null) {
      return '';
    }

    final String text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }

    return text;
  }

  double? _number(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().trim());
  }

  String _display(dynamic value) {
    final String valueText = _text(value);
    return valueText.isEmpty ? '-' : valueText;
  }

  Set<String> get _authorizedGpids {
    return widget.authorizedRecords
        .map((record) => _text(record['unique_id']))
        .where((gpid) => gpid.isNotEmpty)
        .toSet();
  }

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait<void>([
        _loadGeoMaster(),
        _captureOfficerLocation(silent: true),
      ]);
    } catch (_) {
      // Individual methods already handle their own errors.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });

    _moveToBestInitialPosition();
  }

  Future<void> _loadGeoMaster() async {
    try {
      final http.Response response = await http
          .get(
            Uri.parse(_geoMasterUrl),
            headers: const <String, String>{
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 90),
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Geo master returned HTTP ${response.statusCode}.',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      List<dynamic> rawRecords = <dynamic>[];

      if (decoded is List) {
        rawRecords = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final dynamic records = decoded['records'];

        if (records is List) {
          rawRecords = records;
        } else {
          final dynamic data = decoded['data'];

          if (data is List) {
            rawRecords = data;
          }
        }
      }

      final Set<String> authorized = _authorizedGpids;

      final List<Map<String, dynamic>> filtered =
          <Map<String, dynamic>>[];

      for (final dynamic item in rawRecords) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final Map<String, dynamic> record =
            Map<String, dynamic>.from(item);

        final String gpid = _text(record['gpid']);

        if (gpid.isEmpty || !authorized.contains(gpid)) {
          continue;
        }

        final double? latitude = _number(record['latitude']);
        final double? longitude = _number(record['longitude']);

        final bool hasGeo = record['hasGeoLocation'] == true ||
            (latitude != null && longitude != null);

        if (!hasGeo ||
            latitude == null ||
            longitude == null ||
            latitude < -90 ||
            latitude > 90 ||
            longitude < -180 ||
            longitude > 180) {
          continue;
        }

        filtered.add(record);
      }

      if (_officerPosition != null) {
        filtered.sort(
          (a, b) {
            return _distanceFromOfficer(a).compareTo(
              _distanceFromOfficer(b),
            );
          },
        );
      } else {
        filtered.sort(
          (a, b) => _text(a['gpid']).compareTo(
            _text(b['gpid']),
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _geoRecords = filtered;

        if (_geoRecords.isEmpty) {
          _errorMessage =
              'No geo-tagged Mandaps are available within your permitted jurisdiction.';
        }
      });
    } on TimeoutException {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Geo-tagged Mandap data request timed out. Please try again.';
      });
    } on FormatException {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Invalid geo-tagged Mandap data was received.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Unable to load geo-tagged Mandaps. Please try again.';
      });
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showMessage(
        'Please switch ON GPS / Location Services.',
      );
      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

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
    } catch (_) {
      _showMessage(
        'Unable to capture geo-location.',
      );
      return null;
    }
  }

  Future<void> _captureOfficerLocation({
    bool silent = false,
  }) async {
    if (!silent && mounted) {
      setState(() {
        _locatingOfficer = true;
      });
    }

    final Position? position = await _getCurrentPosition();

    if (!mounted) {
      return;
    }

    setState(() {
      _officerPosition = position;
      _locatingOfficer = false;
    });

    if (position != null) {
      _sortByDistance();

      try {
        _mapController.move(
          LatLng(
            position.latitude,
            position.longitude,
          ),
          15,
        );
      } catch (_) {
        // Map may not yet be attached during initial loading.
      }
    }
  }

  void _sortByDistance() {
    if (_officerPosition == null || _geoRecords.isEmpty) {
      return;
    }

    final List<Map<String, dynamic>> sorted =
        List<Map<String, dynamic>>.from(_geoRecords)
          ..sort(
            (a, b) => _distanceFromOfficer(a).compareTo(
              _distanceFromOfficer(b),
            ),
          );

    _geoRecords = sorted;
  }

  double _distanceFromOfficer(
    Map<String, dynamic> record,
  ) {
    final Position? officer = _officerPosition;
    final double? latitude = _number(record['latitude']);
    final double? longitude = _number(record['longitude']);

    if (officer == null ||
        latitude == null ||
        longitude == null) {
      return double.infinity;
    }

    return Geolocator.distanceBetween(
      officer.latitude,
      officer.longitude,
      latitude,
      longitude,
    );
  }

  String _distanceLabel(
    Map<String, dynamic> record,
  ) {
    final double distance = _distanceFromOfficer(record);

    if (!distance.isFinite) {
      return '';
    }

    if (distance < 1000) {
      return '${distance.round()} m away';
    }

    return '${(distance / 1000).toStringAsFixed(2)} km away';
  }

  void _moveToBestInitialPosition() {
    if (!mounted) {
      return;
    }

    final Position? officer = _officerPosition;

    if (officer != null) {
      try {
        _mapController.move(
          LatLng(
            officer.latitude,
            officer.longitude,
          ),
          15,
        );
      } catch (_) {
        // Map may not yet be attached.
      }
      return;
    }

    if (_geoRecords.isNotEmpty) {
      final double? latitude =
          _number(_geoRecords.first['latitude']);
      final double? longitude =
          _number(_geoRecords.first['longitude']);

      if (latitude != null && longitude != null) {
        try {
          _mapController.move(
            LatLng(latitude, longitude),
            14,
          );
        } catch (_) {
          // Map may not yet be attached.
        }
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _selectMandap(
    Map<String, dynamic> record,
  ) {
    final double? latitude = _number(record['latitude']);
    final double? longitude = _number(record['longitude']);

    setState(() {
      _selectedRecord = record;
    });

    if (latitude != null && longitude != null) {
      _mapController.move(
        LatLng(latitude, longitude),
        17,
      );
    }
  }

  Future<void> _startChecking(
    Map<String, dynamic> record,
  ) async {
    final String gpid = _text(record['gpid']);

    if (gpid.isEmpty) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FestivityCheckScreen(
          applicationId: gpid,
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = <Marker>[];

    final Position? officer = _officerPosition;

    if (officer != null) {
      markers.add(
        Marker(
          point: LatLng(
            officer.latitude,
            officer.longitude,
          ),
          width: 54,
          height: 54,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.blue,
              size: 34,
            ),
          ),
        ),
      );
    }

    for (final Map<String, dynamic> record in _geoRecords) {
      final double? latitude = _number(record['latitude']);
      final double? longitude = _number(record['longitude']);

      if (latitude == null || longitude == null) {
        continue;
      }

      final bool selected =
          _selectedRecord != null &&
              _text(_selectedRecord!['gpid']) ==
                  _text(record['gpid']);

      markers.add(
        Marker(
          point: LatLng(
            latitude,
            longitude,
          ),
          width: selected ? 58 : 50,
          height: selected ? 58 : 50,
          child: GestureDetector(
            onTap: () {
              _selectMandap(record);
            },
            child: Container(
              decoration: BoxDecoration(
                color: selected
                    ? Colors.deepPurple.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.88),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Colors.deepPurple
                      : const Color(0xFFCBD5E1),
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: Icon(
                Icons.temple_hindu,
                color: selected
                    ? Colors.deepPurple
                    : const Color(0xFF17365D),
                size: selected ? 38 : 32,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  LatLng get _initialCenter {
    final Position? officer = _officerPosition;

    if (officer != null) {
      return LatLng(
        officer.latitude,
        officer.longitude,
      );
    }

    if (_geoRecords.isNotEmpty) {
      final double? latitude =
          _number(_geoRecords.first['latitude']);
      final double? longitude =
          _number(_geoRecords.first['longitude']);

      if (latitude != null && longitude != null) {
        return LatLng(latitude, longitude);
      }
    }

    return const LatLng(
      17.3850,
      78.4867,
    );
  }

  Widget _buildMap() {
    return Container(
      height: 430,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
        ),
      ),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: 13,
          minZoom: 5,
          maxZoom: 19,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName:
                'in.gov.tspolice.hyderabad.ganesh_bandobust_mobile',
          ),
          MarkerLayer(
            markers: _buildMarkers(),
          ),
        ],
      ),
    );
  }

  Widget _selectedMandapCard(
    Map<String, dynamic> record,
  ) {
    final String distance = _distanceLabel(record);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.temple_hindu,
                color: Color(0xFF17365D),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _display(record['gpid']),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17365D),
                  ),
                ),
              ),
              if (distance.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    distance,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF17365D),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow(
            'Organizer',
            _display(record['name']),
          ),
          _detailRow(
            'Police Station',
            _display(record['policeStation']),
          ),
          _detailRow(
            'Division',
            _display(record['division']),
          ),
          _detailRow(
            'Zone',
            _display(record['zone']),
          ),
          _detailRow(
            'Association',
            _display(record['association']),
          ),
          _detailRow(
            'Geo Source',
            _display(record['geoSource']),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                _startChecking(record);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF17365D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text(
                'START STAGE-3 CHECKING',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 98,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nearestMandaps() {
    if (_geoRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Map<String, dynamic>> nearest =
        _geoRecords.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const Text(
          'Nearby Geo-Tagged Mandaps',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        ...nearest.map(
          (record) {
            final String distance = _distanceLabel(record);

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(
                    Icons.temple_hindu,
                    color: Color(0xFF17365D),
                  ),
                ),
                title: Text(
                  _display(record['gpid']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17365D),
                  ),
                ),
                subtitle: Text(
                  '${_display(record['policeStation'])}\n'
                  '${_display(record['name'])}',
                ),
                isThreeLine: true,
                trailing: distance.isEmpty
                    ? const Icon(Icons.chevron_right)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Text(
                            distance,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                          ),
                        ],
                      ),
                onTap: () {
                  _selectMandap(record);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
        title: const Text(
          'Map / Geo-Tagged Mandap Checking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'My Location',
            onPressed: _locatingOfficer
                ? null
                : () {
                    _captureOfficerLocation();
                  },
            icon: _locatingOfficer
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.my_location),
          ),
          IconButton(
            tooltip: 'Refresh Mandaps',
            onPressed: _loading ? null : _loadMapData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading && _geoRecords.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadMapData,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF17365D),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            '${_geoRecords.length} geo-tagged Mandaps are available within your permitted GPID scope. '
                            'Tap a Mandap icon to view its details and start checking.',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_errorMessage != null &&
                      _geoRecords.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFECACA),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_off_outlined,
                            size: 34,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _loadMapData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _buildMap(),
                    if (_selectedRecord != null)
                      _selectedMandapCard(
                        _selectedRecord!,
                      ),
                    _nearestMandaps(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
