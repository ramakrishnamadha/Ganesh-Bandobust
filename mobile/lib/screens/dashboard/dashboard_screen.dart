import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/gpid_api_service.dart';
import '../installation/installation_check_screen.dart';
import '../login/login_screen.dart';
import '../pre_installation/pre_installation_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String officerName;
  final String role;
  final String policeStation;
  final String sector;
  final AuthenticatedUser authenticatedUser;

  const DashboardScreen({
    super.key,
    required this.officerName,
    required this.role,
    required this.policeStation,
    required this.sector,
    required this.authenticatedUser,
  });

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  

  List<Map<String, dynamic>> _records =
      <Map<String, dynamic>>[];

  bool _loading = true;
  bool _refreshing = false;

  String? _errorMessage;

  String? _selectedRange;
  String? _selectedZone;
  String? _selectedDivision;
  String? _selectedPoliceStation;

  String _searchText = '';
  int _activeStage = 1;

  static const String southRange = 'South Range';
  static const String northRange = 'North Range';

  @override
void initState() {
  super.initState();

  _loadRecords();
}

  @override
  void dispose() {
     
    _searchController.dispose();

    super.dispose();
  }

  String _text(dynamic value) {
    if (value == null) {
      return '';
    }

    final text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return '';
    }

    return text;
  }

  String _displayText(dynamic value) {
    final text = _text(value);

    return text.isEmpty ? '-' : text;
  }

  String _normalizeAccessName(
    dynamic value,
  ) {
    var text = _text(value)
        .toLowerCase()
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();

    text = text.replaceFirst(
      RegExp(r'\s+ps$'),
      '',
    );

    return text.trim();
  }

  String _normalizeHierarchyName(
    dynamic value,
  ) {
    return _text(value)
        .toLowerCase()
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }

  String _zoneKey(
    dynamic value,
  ) {
    return _normalizeHierarchyName(
      value,
    ).replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
  }

  String? _rangeForZone(
    dynamic zoneName,
  ) {
    final key =
        _zoneKey(zoneName);

    const southZones =
        <String>{
      'charminar',
      'golconda',
      'golkonda',
      'shamshabad',
      'samshabad',
      'rajendranagar',
      'rajendanagar',
    };

    const northZones =
        <String>{
      'jubileehills',
      'khairatabad',
      'secunderabad',
      'central',
      'east',
      'west',
      'north',
      'begumpet',
      'panjagutta',
      'banjarahills',
      'madhapur',
      'balanagar',
      'medchal',
    };

    if (southZones.contains(key)) {
      return southRange;
    }

    // All zones that are not in South Range are grouped under North Range
    if (northZones.contains(key) || key.isNotEmpty) {
      return northRange;
    }

    return null;
  }

  bool _sameAccessName(
    dynamic left,
    dynamic right,
  ) {
    final normalizedLeft =
        _normalizeAccessName(left);

    final normalizedRight =
        _normalizeAccessName(right);

    return normalizedLeft.isNotEmpty &&
        normalizedLeft ==
            normalizedRight;
  }

  bool _canAccessRecord(
    Map<String, dynamic> record,
  ) {
    final user =
        widget.authenticatedUser;

    if (user.isAdmin ||
        user.allZones) {
      return true;
    }

    if (user.allPoliceStations) {
      final zoneName =
          user.zoneName?.trim() ?? '';

      if (zoneName.isNotEmpty) {
        return _sameAccessName(
          record['zone_name'],
          zoneName,
        );
      }

      final divisionName =
          user.divisionName?.trim() ??
              '';

      if (divisionName.isNotEmpty) {
        return _sameAccessName(
          record['division_name'],
          divisionName,
        );
      }

      final policeStationName =
          user.policeStationName
                  ?.trim() ??
              '';

      if (policeStationName
          .isNotEmpty) {
        return _sameAccessName(
          record['ps_name'],
          policeStationName,
        );
      }

      return false;
    }

    final allowedNames =
        user.allowedPoliceStations
            .where(
              (access) =>
                  access.canView,
            )
            .map(
              (access) =>
                  _normalizeAccessName(
                access.policeStationName,
              ),
            )
            .where(
              (name) =>
                  name.isNotEmpty,
            )
            .toSet();

    if (allowedNames.isEmpty) {
      return false;
    }

    return allowedNames.contains(
      _normalizeAccessName(
        record['ps_name'],
      ),
    );
  }

  List<Map<String, dynamic>>
      _filterAuthorizedRecords(
    List<Map<String, dynamic>>
        records,
  ) {
    return records
        .where(
          _canAccessRecord,
        )
        .toList();
  }

  String get _accessScopeLabel {
    final user =
        widget.authenticatedUser;

    if (user.isAdmin ||
        user.allZones) {
      return 'All Police Stations';
    }

    if (user.allPoliceStations) {
      final zoneName =
          user.zoneName?.trim() ?? '';

      if (zoneName.isNotEmpty) {
        return '$zoneName Zone';
      }

      final divisionName =
          user.divisionName?.trim() ??
              '';

      if (divisionName.isNotEmpty) {
        return '$divisionName Division';
      }
    }

    final count =
        user.allowedPoliceStations
            .where(
              (access) =>
                  access.canView,
            )
            .length;

    if (count == 1) {
      return '1 Police Station';
    }

    return '$count Police Stations';
  }

  Future<void> _loadRecords({
    bool silent = false,
  }) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    } else {
      if (mounted) {
        setState(() {
          _refreshing = true;
        });
      }
    }

    try {
      final fetchedRecords =
    await GpidApiService
        .fetchGaneshRecords(
      userId:
          widget.authenticatedUser.id,
    );

      final normalizedRecords =
          fetchedRecords
              .map<
                  Map<String,
                      dynamic>>(
                (record) =>
                    Map<String,
                        dynamic>.from(
                  record,
                ),
              )
              .toList();

      if (!mounted) return;

      final authorizedRecords =
          _filterAuthorizedRecords(
        normalizedRecords,
      );

      setState(() {
        _records =
            authorizedRecords;

        _loading = false;
        _refreshing = false;
        _errorMessage = null;

        _validateHierarchySelections();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _refreshing = false;

        if (_records.isEmpty) {
          _errorMessage =
              'Unable to load live GPID records.';
        }
      });
    }
  }

  void _validateHierarchySelections() {
    if (_selectedRange != null) {
      final rangeExists =
          _records.any(
        (record) =>
            _rangeForZone(
              record['zone_name'],
            ) ==
            _selectedRange,
      );

      if (!rangeExists) {
        _selectedRange = null;
        _selectedZone = null;
        _selectedDivision = null;
        _selectedPoliceStation = null;

        return;
      }
    }

    if (_selectedZone != null) {
      final zoneExists =
          _records.any(
        (record) =>
            _text(
              record['zone_name'],
            ) ==
            _selectedZone,
      );

      if (!zoneExists) {
        _selectedZone = null;
        _selectedDivision = null;
        _selectedPoliceStation = null;
      }
    }
  }

  List<String> _uniqueValues(
    String key, {
    List<Map<String, dynamic>>?
        source,
  }) {
    final records =
        source ?? _records;

    final values = records
        .map(
          (record) => _text(
            record[key],
          ),
        )
        .where(
          (value) =>
              value.isNotEmpty,
        )
        .toSet()
        .toList();

    values.sort(
      (a, b) =>
          a.toLowerCase().compareTo(
                b.toLowerCase(),
              ),
    );

    return values;
  }

  List<Map<String, dynamic>>
      _recordsForRange(
    String range,
  ) {
    return _records.where(
      (record) {
        return _rangeForZone(
              record['zone_name'],
            ) ==
            range;
      },
    ).toList();
  }

  List<Map<String, dynamic>> get
      _searchResults {
    final query =
        _searchText
            .trim()
            .toLowerCase();

    if (query.isEmpty) {
      return const <
          Map<String, dynamic>>[];
    }

    return _records.where(
      (record) {
        final searchableValues = [
          record['unique_id'],
          record['ref_no'],
          record['mobile_no'],
          record['name'],
          record['association'],
          record['ps_name'],
          record['division_name'],
          record['zone_name'],
          record['status'],
        ];

        return searchableValues
            .any(
          (value) => _text(
            value,
          )
              .toLowerCase()
              .contains(
                query,
              ),
        );
      },
    ).take(100).toList();
  }

  Color _statusColor(
    dynamic value,
  ) {
    final status =
        _text(value)
            .toUpperCase();

    if (status ==
        'APPROVED') {
      return Colors
          .green.shade700;
    }

    if (status ==
        'REJECTED') {
      return Colors.red.shade700;
    }

    if (status ==
        'PENDING') {
      return Colors
          .orange.shade800;
    }

    return const Color(
      0xFF475569,
    );
  }

  Color _statusBackground(
    dynamic value,
  ) {
    final status =
        _text(value)
            .toUpperCase();

    if (status ==
        'APPROVED') {
      return const Color(
        0xFFF0FDF4,
      );
    }

    if (status ==
        'REJECTED') {
      return const Color(
        0xFFFEF2F2,
      );
    }

    if (status ==
        'PENDING') {
      return const Color(
        0xFFFFFBEB,
      );
    }

    return const Color(
      0xFFF8FAFC,
    );
  }

  Color _statusBorder(
    dynamic value,
  ) {
    final status =
        _text(value)
            .toUpperCase();

    if (status ==
        'APPROVED') {
      return const Color(
        0xFFBBF7D0,
      );
    }

    if (status ==
        'REJECTED') {
      return const Color(
        0xFFFECACA,
      );
    }

    if (status ==
        'PENDING') {
      return const Color(
        0xFFFDE68A,
      );
    }

    return const Color(
      0xFFE2E8F0,
    );
  }

  void _clearHierarchy() {
    setState(() {
      _selectedRange = null;
      _selectedZone = null;
      _selectedDivision = null;
      _selectedPoliceStation = null;
    });
  }

  void _selectRange(
    String range,
  ) {
    setState(() {
      _selectedRange = range;
      _selectedZone = null;
      _selectedDivision = null;
      _selectedPoliceStation = null;
    });
  }

  void _selectZone(
    String zone,
  ) {
    setState(() {
      _selectedZone = zone;
      _selectedDivision = null;
      _selectedPoliceStation = null;
    });
  }

  void _selectDivision(
    String division,
  ) {
    setState(() {
      _selectedDivision = division;
      _selectedPoliceStation = null;
    });
  }

  void _selectPoliceStation(
    String policeStation,
  ) {
    setState(() {
      _selectedPoliceStation =
          policeStation;
    });
  }

  Future<void> _openGpid(
    Map<String, dynamic> record,
  ) async {
    if (!_canAccessRecord(
      record,
    )) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'You do not have access to this Police Station.',
          ),
        ),
      );

      return;
    }

    final gpid =
        _text(
      record['unique_id'],
    );

    if (gpid.isEmpty) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _activeStage == 2
            ? InstallationCheckScreen(
                applicationId: gpid,
                ganeshRecord: record,
              )
            : PreInstallationScreen(
                applicationId: gpid,
                ganeshRecord: record,
              ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color:
                const Color(
              0xFFE2E8F0,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color:
                  Color(
                0x08000000,
              ),
              blurRadius: 5,
              offset:
                  Offset(
                0,
                2,
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Icon(
              icon,
              color:
                  const Color(
                0xFF17365D,
              ),
              size: 22,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(
                  0xFF0F172A,
                ),
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              title,
              maxLines: 1,
              overflow:
                  TextOverflow
                      .ellipsis,
              style:
                  const TextStyle(
                fontSize: 11,
                color:
                    Color(
                  0xFF64748B,
                ),
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(
    dynamic value,
  ) {
    final status =
        _displayText(
      value,
    ).toUpperCase();

    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            _statusBackground(
          value,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
              _statusBorder(
            value,
          ),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          fontWeight:
              FontWeight.bold,
          color:
              _statusColor(
            value,
          ),
        ),
      ),
    );
  }

  Widget _gpidRecordTile(
    Map<String, dynamic> record,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color:
              const Color(
            0xFFE2E8F0,
          ),
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        onTap: () {
          _openGpid(
            record,
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(
            12,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Expanded(
                    child: Text(
                      _displayText(
                        record[
                            'unique_id'],
                      ),
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(
                          0xFF17365D,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  _statusChip(
                    record['status'],
                  ),
                ],
              ),
              const SizedBox(
                height: 7,
              ),
              Text(
                _displayText(
                  record['name'],
                ),
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'Ref: ${_displayText(record['ref_no'])}',
                style:
                    const TextStyle(
                  fontSize: 11,
                  color:
                      Color(
                    0xFF64748B,
                  ),
                ),
              ),
              Text(
                'Mobile: ${_displayText(record['mobile_no'])}',
                style:
                    const TextStyle(
                  fontSize: 11,
                  color:
                      Color(
                    0xFF64748B,
                  ),
                ),
              ),
              Text(
                _displayText(
                  record[
                      'association'],
                ),
                style:
                    const TextStyle(
                  fontSize: 11,
                  color:
                      Color(
                    0xFF64748B,
                  ),
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Row(
                children: [
                  const Icon(
                    Icons
                        .local_police_outlined,
                    size: 14,
                    color:
                        Color(
                      0xFF64748B,
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Expanded(
                    child: Text(
                      _displayText(
                        record[
                            'ps_name'],
                      ),
                      style:
                          const TextStyle(
                        fontSize: 11,
                        color:
                            Color(
                          0xFF475569,
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons
                        .chevron_right,
                    color:
                        Color(
                      0xFF94A3B8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchSection() {
    final results =
        _searchResults;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Search GPID Records',
          style: TextStyle(
            fontSize: 19,
            fontWeight:
                FontWeight.bold,
            color:
                Color(
              0xFF0F172A,
            ),
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        TextField(
          controller:
              _searchController,
          onChanged: (value) {
            setState(() {
              _searchText =
                  value;
            });
          },
          decoration:
              InputDecoration(
            hintText:
                'GPID, Ref ID, Mobile, Applicant...',
            prefixIcon:
                const Icon(
              Icons.search,
            ),
            suffixIcon:
                _searchText.isEmpty
                    ? null
                    : IconButton(
                        icon:
                            const Icon(
                          Icons.close,
                        ),
                        onPressed:
                            () {
                          _searchController
                              .clear();

                          setState(
                            () {
                              _searchText =
                                  '';
                            },
                          );
                        },
                      ),
            filled: true,
            fillColor:
                Colors.white,
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius
                      .circular(
                12,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(
                  0xFFE2E8F0,
                ),
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius
                      .circular(
                12,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(
                  0xFFE2E8F0,
                ),
              ),
            ),
          ),
        ),
        if (_searchText
            .trim()
            .isNotEmpty) ...[
          const SizedBox(
            height: 10,
          ),
          Text(
            '${results.length} result${results.length == 1 ? '' : 's'}',
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  Color(
                0xFF64748B,
              ),
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          if (results.isEmpty)
            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets
                      .all(
                18,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius
                        .circular(
                  12,
                ),
                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFE2E8F0,
                  ),
                ),
              ),
              child:
                  const Text(
                'No matching GPID records found.',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF64748B,
                  ),
                ),
              ),
            )
          else
            ...results.map(
              _gpidRecordTile,
            ),
        ],
      ],
    );
  }

  Widget _hierarchySection() {
    if (_selectedRange ==
        null) {
      final ranges =
          <String>[];

      final southCount =
          _recordsForRange(
        southRange,
      ).length;

      final northCount =
          _recordsForRange(
        northRange,
      ).length;

      if (southCount > 0) {
        ranges.add(
          southRange,
        );
      }

      if (northCount > 0) {
        ranges.add(
          northRange,
        );
      }

      return _hierarchyList(
        title:
            'Hyderabad Commissionerate',
        subtitle:
            'Select a Range to view Zones',
        items: ranges,
        recordCount:
            (range) {
          return _recordsForRange(
            range,
          ).length;
        },
        onTap: _selectRange,
        icon:
            Icons.account_balance_outlined,
      );
    }

    final rangeRecords =
        _recordsForRange(
      _selectedRange!,
    );

    if (_selectedZone ==
        null) {
      final zones =
          _uniqueValues(
        'zone_name',
        source:
            rangeRecords,
      );

      return _hierarchyList(
        title:
            _selectedRange!,
        subtitle:
            'Select a Zone',
        items: zones,
        recordCount:
            (zone) {
          return rangeRecords.where(
            (record) =>
                _text(
                  record[
                      'zone_name'],
                ) ==
                zone,
          ).length;
        },
        onBack:
            _clearHierarchy,
        onTap:
            _selectZone,
        icon:
            Icons.location_city,
      );
    }

    final zoneRecords =
        rangeRecords.where(
      (record) =>
          _text(
            record['zone_name'],
          ) ==
          _selectedZone,
    ).toList();

    if (_selectedDivision ==
        null) {
      final divisions =
          _uniqueValues(
        'division_name',
        source:
            zoneRecords,
      );

      return _hierarchyList(
        title:
            _selectedZone!,
        subtitle:
            'Select a Division',
        items: divisions,
        recordCount:
            (division) {
          return zoneRecords.where(
            (record) =>
                _text(
                  record[
                      'division_name'],
                ) ==
                division,
          ).length;
        },
        onBack: () {
          setState(() {
            _selectedZone =
                null;
            _selectedDivision =
                null;
            _selectedPoliceStation =
                null;
          });
        },
        onTap:
            _selectDivision,
        icon:
            Icons.account_tree_outlined,
      );
    }

    final divisionRecords =
        zoneRecords.where(
      (record) =>
          _text(
            record[
                'division_name'],
          ) ==
          _selectedDivision,
    ).toList();

    if (_selectedPoliceStation ==
        null) {
      final policeStations =
          _uniqueValues(
        'ps_name',
        source:
            divisionRecords,
      );

      return _hierarchyList(
        title:
            _selectedDivision!,
        subtitle:
            'Select a Police Station',
        items:
            policeStations,
        recordCount:
            (policeStation) {
          return divisionRecords
              .where(
                (record) =>
                    _text(
                      record[
                          'ps_name'],
                    ) ==
                    policeStation,
              )
              .length;
        },
        onBack: () {
          setState(() {
            _selectedDivision =
                null;
            _selectedPoliceStation =
                null;
          });
        },
        onTap:
            _selectPoliceStation,
        icon:
            Icons.local_police,
      );
    }

    final stationRecords =
        divisionRecords.where(
      (record) =>
          _text(
            record['ps_name'],
          ) ==
          _selectedPoliceStation,
    ).toList();

    stationRecords.sort(
      (a, b) =>
          _text(
            a['unique_id'],
          ).compareTo(
        _text(
          b['unique_id'],
        ),
      ),
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedPoliceStation =
                      null;
                });
              },
              icon:
                  const Icon(
                Icons.arrow_back,
              ),
              padding:
                  EdgeInsets.zero,
              constraints:
                  const BoxConstraints(),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    _selectedPoliceStation!,
                    style:
                        const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(
                        0xFF0F172A,
                      ),
                    ),
                  ),
                  Text(
                    '${stationRecords.length} GPID records',
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Color(
                        0xFF64748B,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        ...stationRecords.map(
          _gpidRecordTile,
        ),
      ],
    );
  }

  Widget _hierarchyList({
    required String title,
    required String subtitle,
    required List<String> items,
    required int Function(
      String item,
    ) recordCount,
    required void Function(
      String item,
    ) onTap,
    required IconData icon,
    VoidCallback? onBack,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null) ...[
              IconButton(
                onPressed:
                    onBack,
                icon:
                    const Icon(
                  Icons.arrow_back,
                ),
                padding:
                    EdgeInsets.zero,
                constraints:
                    const BoxConstraints(),
              ),
              const SizedBox(
                width: 10,
              ),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(
                        0xFF0F172A,
                      ),
                    ),
                  ),
                  Text(
                    subtitle,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Color(
                        0xFF64748B,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        if (items.isEmpty)
          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets
                    .all(
              18,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius
                      .circular(
                12,
              ),
              border:
                  Border.all(
                color:
                    const Color(
                  0xFFE2E8F0,
                ),
              ),
            ),
            child:
                const Text(
              'No records available.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Color(
                  0xFF64748B,
                ),
              ),
            ),
          )
        else
          ...items.map(
            (item) =>
                Container(
              margin:
                  const EdgeInsets
                      .only(
                bottom: 8,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius
                        .circular(
                  12,
                ),
                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFE2E8F0,
                  ),
                ),
              ),
              child:
                  ListTile(
                leading:
                    CircleAvatar(
                  backgroundColor:
                      const Color(
                    0xFFEFF6FF,
                  ),
                  child:
                      Icon(
                    icon,
                    size: 20,
                    color:
                        const Color(
                      0xFF17365D,
                    ),
                  ),
                ),
                title:
                    Text(
                  item,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle:
                    Text(
                  '${recordCount(item)} GPIDs',
                ),
                trailing:
                    const Icon(
                  Icons
                      .chevron_right,
                ),
                onTap: () {
                  onTap(
                    item,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final zones =
        _uniqueValues(
      'zone_name',
    ).length;

    final divisions =
        _uniqueValues(
      'division_name',
    ).length;

    final policeStations =
        _uniqueValues(
      'ps_name',
    ).length;

    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF1F5F9,
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
          'Ganesh Bandobust 2026',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          if (_refreshing)
            const Padding(
              padding:
                  EdgeInsets
                      .symmetric(
                horizontal:
                    12,
              ),
              child:
                  Center(
                child:
                    SizedBox(
                  width: 17,
                  height: 17,
                  child:
                      CircularProgressIndicator(
                    strokeWidth:
                        2,
                    color:
                        Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              tooltip:
                  'Refresh',
              icon:
                  const Icon(
                Icons.refresh,
              ),
              onPressed:
                  () {
                _loadRecords();
              },
            ),
          IconButton(
            tooltip:
                'Logout',
            icon:
                const Icon(
              Icons.logout,
            ),
            onPressed:
                () {
              AuthService
                  .clearSession();

              Navigator
                  .pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                          const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body:
          RefreshIndicator(
        onRefresh:
            () =>
                _loadRecords(),
        child:
            SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets
                  .all(
            14,
          ),
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets
                        .all(
                  16,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFFE2E8F0,
                    ),
                  ),
                ),
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      'Logged-in Officer',
                      style:
                          TextStyle(
                        fontSize:
                            11,
                        color:
                            Color(
                          0xFF64748B,
                        ),
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      widget
                          .officerName,
                      style:
                          const TextStyle(
                        fontSize:
                            20,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            Color(
                          0xFF17365D,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      children: [
                        _officerChip(
                          widget
                              .role,
                        ),
                        _officerChip(
                          _accessScopeLabel,
                        ),
                        if (widget
                            .policeStation
                            .trim()
                            .isNotEmpty)
                          _officerChip(
                            widget
                                .policeStation,
                          ),
                        if (widget
                            .sector
                            .trim()
                            .isNotEmpty)
                          _officerChip(
                            'Sector ${widget.sector}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              if (_loading &&
                  _records.isEmpty)
                const Center(
                  child:
                      Padding(
                    padding:
                        EdgeInsets
                            .all(
                      35,
                    ),
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage !=
                      null &&
                  _records.isEmpty)
                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets
                          .all(
                    18,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFFEF2F2,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                    border:
                        Border.all(
                      color:
                          const Color(
                        0xFFFECACA,
                      ),
                    ),
                  ),
                  child:
                      Column(
                    children: [
                      const Icon(
                        Icons
                            .cloud_off_outlined,
                        size: 34,
                        color:
                            Colors.red,
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        _errorMessage!,
                        textAlign:
                            TextAlign
                                .center,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      OutlinedButton
                          .icon(
                        onPressed:
                            () {
                          _loadRecords();
                        },
                        icon:
                            const Icon(
                          Icons.refresh,
                        ),
                        label:
                            const Text(
                          'Retry',
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                const Text(
                  'Live GPID Overview',
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight
                            .bold,
                    color:
                        Color(
                      0xFF0F172A,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    _summaryCard(
                      title:
                          'Total GPIDs',
                      value:
                          _records
                              .length
                              .toString(),
                      icon:
                          Icons
                              .temple_hindu,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    _summaryCard(
                      title:
                          'Zones',
                      value:
                          zones
                              .toString(),
                      icon:
                          Icons
                              .location_city,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  children: [
                    _summaryCard(
                      title:
                          'Divisions',
                      value:
                          divisions
                              .toString(),
                      icon:
                          Icons
                              .account_tree_outlined,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    _summaryCard(
                      title:
                          'Police Stations',
                      value:
                          policeStations
                              .toString(),
                      icon:
                          Icons
                              .local_police,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                _searchSection(),
                const SizedBox(
                  height: 22,
                ),
                _hierarchySection(),
                const SizedBox(
                  height: 22,
                ),
              ],
              const Text(
                'My Work',
                style:
                    TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(
                    0xFF0F172A,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Card(
                elevation: 0,
                color:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                  side:
                      const BorderSide(
                    color:
                        Color(
                      0xFFE2E8F0,
                    ),
                  ),
                ),
                child:
                    ListTile(
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        14,
                    vertical: 8,
                  ),
                  leading:
                      const CircleAvatar(
                    backgroundColor:
                        Color(
                      0xFF17365D,
                    ),
                    child:
                        Icon(
                      Icons
                          .temple_hindu,
                      color:
                          Colors.white,
                    ),
                  ),
                  title:
                      const Text(
                    'GPID Ganesh Idols',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle:
                      const Text(
                    'View complete GPID list',
                  ),
                  trailing:
                      Row(
                    mainAxisSize:
                        MainAxisSize
                            .min,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              9,
                          vertical:
                              4,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFEFF6FF,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child:
                            Text(
                          _records
                              .length
                              .toString(),
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF17365D,
                            ),
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons
                            .chevron_right,
                      ),
                    ],
                  ),
                  onTap:
                      () async {
                    await Navigator
                        .push(
                      context,
                      MaterialPageRoute<
                          void>(
                        builder:
                            (_) =>
                                _ScopedGpidListScreen(
                          records:
                              List<
                                  Map<String,
                                      dynamic>>.from(
                            _records,
                          ),
                          stage:
                              _activeStage,
                        ),
                      ),
                    );

                    _loadRecords(
                      silent: true,
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 22,
              ),
              const Text(
                'Festival Stages',
                style:
                    TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(
                    0xFF0F172A,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              _StageTile(
                number: '1',
                title:
                    'Pre-Installation',
                status:
                    _activeStage == 1
                        ? 'ACTIVE'
                        : 'Available',
                active:
                    _activeStage == 1,
                unlocked: true,
                onTap: () {
                  setState(() {
                    _activeStage = 1;
                  });
                },
              ),
              _StageTile(
                number: '2',
                title:
                    'Installation',
                status:
                    _activeStage == 2
                        ? 'ACTIVE'
                        : 'Available',
                active:
                    _activeStage == 2,
                unlocked: true,
                onTap: () {
                  setState(() {
                    _activeStage = 2;
                  });
                },
              ),
              const _StageTile(
                number: '3',
                title:
                    'During Festivity',
                status:
                    'Not Started',
              ),
              const _StageTile(
                number: '4',
                title:
                    'Immersion',
                status:
                    'Not Started',
              ),
              const _StageTile(
                number: '5',
                title:
                    'Post-Immersion',
                status:
                    'Not Started',
              ),
              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _officerChip(
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF1F5F9,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFFE2E8F0,
          ),
        ),
      ),
      child:
          Text(
        text,
        style:
            const TextStyle(
          fontSize: 11,
          color:
              Color(
            0xFF475569,
          ),
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScopedGpidListScreen
    extends StatelessWidget {
  final List<Map<String, dynamic>>
      records;
  final int stage;

  const _ScopedGpidListScreen({
    required this.records,
    required this.stage,
  });

  String _text(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    final text =
        value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() ==
            'null') {
      return '';
    }

    return text;
  }

  String _displayText(
    dynamic value,
  ) {
    final valueText =
        _text(value);

    return valueText.isEmpty
        ? '-'
        : valueText;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final sortedRecords =
        List<Map<String, dynamic>>.from(
      records,
    );

    sortedRecords.sort(
      (
        Map<String, dynamic> a,
        Map<String, dynamic> b,
      ) {
        return _text(
          a['unique_id'],
        ).compareTo(
          _text(
            b['unique_id'],
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF1F5F9,
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
            Text(
          stage == 2
              ? 'Installation - Accessible GPIDs'
              : 'Pre-Installation - Accessible GPIDs',
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body:
          sortedRecords.isEmpty
              ? const Center(
                  child:
                      Padding(
                    padding:
                        EdgeInsets
                            .all(
                      24,
                    ),
                    child:
                        Text(
                      'No GPID records are available in your assigned Police Stations.',
                      textAlign:
                          TextAlign
                              .center,
                    ),
                  ),
                )
              : ListView
                  .builder(
                  padding:
                      const EdgeInsets
                          .all(
                    12,
                  ),
                  itemCount:
                      sortedRecords
                          .length,
                  itemBuilder:
                      (
                    BuildContext
                        context,
                    int index,
                  ) {
                    final record =
                        sortedRecords[
                            index];

                    final gpid =
                        _text(
                      record[
                          'unique_id'],
                    );

                    return Card(
                      elevation: 0,
                      margin:
                          const EdgeInsets
                              .only(
                        bottom: 8,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                        side:
                            const BorderSide(
                          color:
                              Color(
                            0xFFE2E8F0,
                          ),
                        ),
                      ),
                      child:
                          ListTile(
                        title:
                            Text(
                          _displayText(
                            record[
                                'unique_id'],
                          ),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                Color(
                              0xFF17365D,
                            ),
                          ),
                        ),
                        subtitle:
                            Text(
                          '${_displayText(record['name'])}\n'
                          '${_displayText(record['ps_name'])}',
                        ),
                        isThreeLine:
                            true,
                        trailing:
                            const Icon(
                          Icons
                              .chevron_right,
                        ),
                        onTap:
                            gpid.isEmpty
                                ? null
                                : () {
                                    Navigator
                                        .push(
                                      context,
                                      MaterialPageRoute<
                                          void>(
                                        builder:
                                            (_) =>
                                                stage == 2
                                                    ? InstallationCheckScreen(
                                                        applicationId:
                                                            gpid,
                                                        ganeshRecord:
                                                            record,
                                                      )
                                                    : PreInstallationScreen(
                                                        applicationId:
                                                            gpid,
                                                        ganeshRecord:
                                                            record,
                                                      ),
                                      ),
                                    );
                                  },
                      ),
                    );
                  },
                ),
    );
  }
}

class _StageTile
    extends StatelessWidget {
  final String number;
  final String title;
  final String status;
  final bool active;
  final bool unlocked;
  final VoidCallback? onTap;

  const _StageTile({
    required this.number,
    required this.title,
    required this.status,
    this.active = false,
    this.unlocked = false,
    this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      elevation: 0,
      color:
          Colors.white,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        side:
            const BorderSide(
          color:
              Color(
            0xFFE2E8F0,
          ),
        ),
      ),
      child:
          ListTile(
        onTap:
            unlocked ? onTap : null,
        leading:
            CircleAvatar(
          backgroundColor:
              active || unlocked
                  ? const Color(
                      0xFF17365D,
                    )
                  : const Color(
                      0xFFE2E8F0,
                    ),
          foregroundColor:
              active || unlocked
                  ? Colors.white
                  : Colors.black54,
          child:
              Text(
            number,
          ),
        ),
        title:
            Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle:
            Text(
          status,
        ),
        trailing:
            active
                ? const Icon(
                    Icons
                        .check_circle,
                    color:
                        Colors.green,
                  )
                : unlocked
                    ? const Icon(
                        Icons
                            .chevron_right,
                      )
                    : const Icon(
                        Icons
                            .lock_outline,
                      ),
      ),
    );
  }
}