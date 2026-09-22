import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../festivity/festivity_check_screen.dart';

class GpidBasedCheckingScreen extends StatefulWidget {
  final AuthenticatedUser authenticatedUser;
  final List<Map<String, dynamic>> records;

  const GpidBasedCheckingScreen({
    super.key,
    required this.authenticatedUser,
    required this.records,
  });

  @override
  State<GpidBasedCheckingScreen> createState() =>
      _GpidBasedCheckingScreenState();
}

class _GpidBasedCheckingScreenState
    extends State<GpidBasedCheckingScreen> {
  String? _selectedRange;
  String? _selectedZone;
  String? _selectedDivision;
  String? _selectedPoliceStation;
  String? _selectedGpid;

  static const String southRange = 'South Range';
  static const String northRange = 'North Range';

  String _text(dynamic value) {
    if (value == null) {
      return '';
    }

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }

    return text;
  }

  String _display(dynamic value) {
    final text = _text(value);
    return text.isEmpty ? '-' : text;
  }

  String _normalize(dynamic value) {
    return _text(value)
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceFirst(RegExp(r'\s+ps$'), '')
        .trim();
  }

  bool _same(dynamic left, dynamic right) {
    final a = _normalize(left);
    final b = _normalize(right);

    return a.isNotEmpty && a == b;
  }

  String _zoneKey(dynamic value) {
    return _text(value)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String? _rangeForZone(dynamic zoneName) {
    switch (_zoneKey(zoneName)) {
      case 'charminar':
      case 'golconda':
      case 'golkonda':
      case 'rajendranagar':
      case 'shamshabad':
        return southRange;
      case 'jubileehills':
      case 'khairatabad':
      case 'secunderabad':
        return northRange;
      default:
        return null;
    }
  }

  List<String> _unique(
    Iterable<Map<String, dynamic>> source,
    String key,
  ) {
    final values = source
        .map((record) => _text(record[key]))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    values.sort(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );

    return values;
  }

  String get _fixedZone {
    final value = widget.authenticatedUser.zoneName;
    return _text(value);
  }

  String get _fixedDivision {
    final value = widget.authenticatedUser.divisionName;
    return _text(value);
  }

  String get _fixedPoliceStation {
    final value = widget.authenticatedUser.policeStationName;
    return _text(value);
  }

  String get _fixedSector {
    final value = widget.authenticatedUser.sectorName;
    return _text(value);
  }

  String get _fixedRange {
    final value = _text(widget.authenticatedUser.rangeName);

    if (value.isNotEmpty) {
      return value;
    }

    if (_fixedZone.isNotEmpty) {
      return _rangeForZone(_fixedZone) ?? '';
    }

    return '';
  }

  List<Map<String, dynamic>> get _rangeRecords {
    final range = _fixedRange.isNotEmpty
        ? _fixedRange
        : _selectedRange;

    if (range == null || range.isEmpty) {
      return widget.records;
    }

    return widget.records.where((record) {
      final recordRange = _rangeForZone(record['zone_name']);
      return recordRange != null && _same(recordRange, range);
    }).toList();
  }

  List<Map<String, dynamic>> get _zoneRecords {
    final zone = _fixedZone.isNotEmpty
        ? _fixedZone
        : _selectedZone;

    if (zone == null || zone.isEmpty) {
      return _rangeRecords;
    }

    return _rangeRecords.where(
      (record) => _same(record['zone_name'], zone),
    ).toList();
  }

  List<Map<String, dynamic>> get _divisionRecords {
    final division = _fixedDivision.isNotEmpty
        ? _fixedDivision
        : _selectedDivision;

    if (division == null || division.isEmpty) {
      return _zoneRecords;
    }

    return _zoneRecords.where(
      (record) => _same(record['division_name'], division),
    ).toList();
  }

  List<Map<String, dynamic>> get _stationRecords {
    final policeStation = _fixedPoliceStation.isNotEmpty
        ? _fixedPoliceStation
        : _selectedPoliceStation;

    if (policeStation == null || policeStation.isEmpty) {
      return _divisionRecords;
    }

    return _divisionRecords.where(
      (record) => _same(record['ps_name'], policeStation),
    ).toList();
  }

  List<Map<String, dynamic>> get _gpidRecords {
    final records =
        List<Map<String, dynamic>>.from(_stationRecords);

    records.sort(
      (a, b) => _text(a['unique_id']).compareTo(
        _text(b['unique_id']),
      ),
    );

    return records;
  }

  Map<String, dynamic>? get _selectedRecord {
    final selected = _selectedGpid;

    if (selected == null || selected.isEmpty) {
      return null;
    }

    for (final record in _gpidRecords) {
      if (_text(record['unique_id']) == selected) {
        return record;
      }
    }

    return null;
  }

  bool get _rangeResolved =>
      _fixedRange.isNotEmpty || _selectedRange != null;

  bool get _zoneResolved =>
      _fixedZone.isNotEmpty || _selectedZone != null;

  bool get _divisionResolved =>
      _fixedDivision.isNotEmpty || _selectedDivision != null;

  bool get _stationResolved =>
      _fixedPoliceStation.isNotEmpty ||
      _selectedPoliceStation != null;

  List<String> get _ranges {
    final availableRanges = widget.records
        .map((record) => _rangeForZone(record['zone_name']))
        .whereType<String>()
        .toSet();

    final ranges = <String>[];

    if (availableRanges.contains(southRange)) {
      ranges.add(southRange);
    }

    if (availableRanges.contains(northRange)) {
      ranges.add(northRange);
    }

    return ranges;
  }

  List<String> get _zones =>
      _unique(_rangeRecords, 'zone_name');

  List<String> get _divisions =>
      _unique(_zoneRecords, 'division_name');

  List<String> get _policeStations =>
      _unique(_divisionRecords, 'ps_name');

  void _changeRange(String? value) {
    setState(() {
      _selectedRange = value;
      _selectedZone = null;
      _selectedDivision = null;
      _selectedPoliceStation = null;
      _selectedGpid = null;
    });
  }

  void _changeZone(String? value) {
    setState(() {
      _selectedZone = value;
      _selectedDivision = null;
      _selectedPoliceStation = null;
      _selectedGpid = null;
    });
  }

  void _changeDivision(String? value) {
    setState(() {
      _selectedDivision = value;
      _selectedPoliceStation = null;
      _selectedGpid = null;
    });
  }

  void _changePoliceStation(String? value) {
    setState(() {
      _selectedPoliceStation = value;
      _selectedGpid = null;
    });
  }

  Future<void> _startChecking() async {
    final record = _selectedRecord;

    if (record == null) {
      return;
    }

    final gpid = _text(record['unique_id']);

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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _readOnlyBox({
    required String label,
    required String value,
    IconData icon = Icons.lock_outline,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const Text(
                'READ ONLY',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dropdownBox({
    required String label,
    required String hint,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    final effectiveValue =
        value != null && items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label),
        DropdownButtonFormField<String>(
          initialValue: effectiveValue,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor:
                enabled ? Colors.white : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFCBD5E1),
              ),
            ),
          ),
          hint: Text(hint),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged:
              enabled && items.isNotEmpty ? onChanged : null,
        ),
      ],
    );
  }

  Widget _buildHierarchy() {
    final children = <Widget>[];

    if (_fixedRange.isNotEmpty) {
      children.add(
        _readOnlyBox(
          label: 'Range',
          value: _fixedRange,
          icon: Icons.account_balance_outlined,
        ),
      );
    } else {
      children.add(
        _dropdownBox(
          label: 'Range',
          hint: 'Select Range',
          items: _ranges,
          value: _selectedRange,
          onChanged: _changeRange,
        ),
      );
    }

    if (_rangeResolved) {
      children.add(const SizedBox(height: 14));

      if (_fixedZone.isNotEmpty) {
        children.add(
          _readOnlyBox(
            label: 'Zone',
            value: _fixedZone,
            icon: Icons.location_city_outlined,
          ),
        );
      } else {
        children.add(
          _dropdownBox(
            label: 'Zone',
            hint: 'Select Zone',
            items: _zones,
            value: _selectedZone,
            onChanged: _changeZone,
          ),
        );
      }
    }

    if (_zoneResolved) {
      children.add(const SizedBox(height: 14));

      if (_fixedDivision.isNotEmpty) {
        children.add(
          _readOnlyBox(
            label: 'Division',
            value: _fixedDivision,
            icon: Icons.account_tree_outlined,
          ),
        );
      } else {
        children.add(
          _dropdownBox(
            label: 'Division',
            hint: 'Select Division',
            items: _divisions,
            value: _selectedDivision,
            onChanged: _changeDivision,
          ),
        );
      }
    }

    if (_divisionResolved) {
      children.add(const SizedBox(height: 14));

      if (_fixedPoliceStation.isNotEmpty) {
        children.add(
          _readOnlyBox(
            label: 'Police Station',
            value: _fixedPoliceStation,
            icon: Icons.local_police_outlined,
          ),
        );
      } else {
        children.add(
          _dropdownBox(
            label: 'Police Station',
            hint: 'Select Police Station',
            items: _policeStations,
            value: _selectedPoliceStation,
            onChanged: _changePoliceStation,
          ),
        );
      }
    }

    if (_stationResolved && _fixedSector.isNotEmpty) {
      children.add(const SizedBox(height: 14));
      children.add(
        _readOnlyBox(
          label: 'Sector',
          value: _fixedSector,
          icon: Icons.grid_view_outlined,
        ),
      );
      children.add(
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Text(
            'Sector is shown from the officer jurisdiction. GPID records are not yet sector-mapped in the GPID master.',
            style: TextStyle(
              fontSize: 10,
              height: 1.35,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    if (_stationResolved) {
      children.add(const SizedBox(height: 14));

      final gpids = _gpidRecords
          .map((record) => _text(record['unique_id']))
          .where((gpid) => gpid.isNotEmpty)
          .toList();

      children.add(
        _dropdownBox(
          label: 'GPID',
          hint: 'Select GPID',
          items: gpids,
          value: _selectedGpid,
          onChanged: (value) {
            setState(() {
              _selectedGpid = value;
            });
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _selectedGpidCard(Map<String, dynamic> record) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Ganesh Mandap',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _display(record['unique_id']),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF17365D),
            ),
          ),
          const SizedBox(height: 9),
          _detailRow(
            'Organizer',
            _display(record['name']),
          ),
          _detailRow(
            'Association',
            _display(record['association']),
          ),
          _detailRow(
            'Police Station',
            _display(record['ps_name']),
          ),
          _detailRow(
            'Division',
            _display(record['division_name']),
          ),
          _detailRow(
            'Zone',
            _display(record['zone_name']),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
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

  @override
  Widget build(BuildContext context) {
    final record = _selectedRecord;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
        title: const Text(
          'GPID Based Checking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFBFDBFE),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF17365D),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your login jurisdiction controls the hierarchy below. Fixed jurisdiction levels are read-only; only permitted subordinate levels can be selected.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Jurisdiction & GPID',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.records.length} accessible GPID records',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          _buildHierarchy(),
          if (record != null) ...[
            const SizedBox(height: 22),
            _selectedGpidCard(record),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _startChecking,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF17365D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
