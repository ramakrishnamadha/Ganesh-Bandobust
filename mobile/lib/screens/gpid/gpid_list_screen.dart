import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/gpid_api_service.dart';
import '../festivity/festivity_check_screen.dart';
import '../immersion/immersion_workflow_screen.dart';
import '../installation/installation_check_screen.dart';
import '../pre_installation/pre_installation_screen.dart';

class GpidListScreen extends StatefulWidget {
  final AuthenticatedUser user;

  const GpidListScreen({
    super.key,
    required this.user,
  });

  @override
  State<GpidListScreen> createState() => _GpidListScreenState();
}

class _GpidListScreenState extends State<GpidListScreen> {
  late Future<List<Map<String, dynamic>>> _futureRecords;
  List<Map<String, dynamic>> _allRecords = [];

  String? selectedRange;
  String? selectedZone;
  String? selectedDivision;
  String? selectedPs;

  @override
  void initState() {
    super.initState();
    _futureRecords = _loadRecords();
  }

  Future<List<Map<String, dynamic>>> _loadRecords() async {
    final records = await GpidApiService.fetchGaneshRecords(
      userId: widget.user.employeeId,
    ).timeout(
      const Duration(seconds: 100),
      onTimeout: () {
        throw TimeoutException(
          'GPID records are taking too long to load.',
        );
      },
    );

    setState(() {
      _allRecords = records;
      selectedRange = null;
      selectedZone = null;
      selectedDivision = null;
      selectedPs = null;
    });

    return records;
  }

  Future<void> _refresh() async {
    final newFuture = _loadRecords();
    setState(() {
      _futureRecords = newFuture;
    });
    try {
      await newFuture;
    } catch (_) {}
  }

  void _retry() {
    setState(() {
      _futureRecords = _loadRecords();
    });
  }

  String _text(dynamic value) {
    if (value == null) return '-';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '-';
    return text;
  }

  List<String> get availableRanges {
    final ranges = _allRecords.map((e) => _text(e['range_name'] ?? e['range'])).where((e) => e != '-').toSet().toList();
    ranges.sort();
    return ranges;
  }

  List<String> get availableZones {
    var records = _allRecords;
    if (selectedRange != null) {
      records = records.where((e) => _text(e['range_name'] ?? e['range']) == selectedRange).toList();
    }
    final zones = records.map((e) => _text(e['zone_name'])).where((e) => e != '-').toSet().toList();
    zones.sort();
    return zones;
  }

  List<String> get availableDivisions {
    var records = _allRecords;
    if (selectedRange != null) {
      records = records.where((e) => _text(e['range_name'] ?? e['range']) == selectedRange).toList();
    }
    if (selectedZone != null) {
      records = records.where((e) => _text(e['zone_name']) == selectedZone).toList();
    }
    final divs = records.map((e) => _text(e['division_name'])).where((e) => e != '-').toSet().toList();
    divs.sort();
    return divs;
  }

  List<String> get availablePss {
    var records = _allRecords;
    if (selectedRange != null) {
      records = records.where((e) => _text(e['range_name'] ?? e['range']) == selectedRange).toList();
    }
    if (selectedZone != null) {
      records = records.where((e) => _text(e['zone_name']) == selectedZone).toList();
    }
    if (selectedDivision != null) {
      records = records.where((e) => _text(e['division_name']) == selectedDivision).toList();
    }
    final pss = records.map((e) => _text(e['ps_name'])).where((e) => e != '-').toSet().toList();
    pss.sort();
    return pss;
  }

  List<Map<String, dynamic>> get filteredRecords {
    var records = _allRecords;
    if (selectedRange != null) {
      records = records.where((e) => _text(e['range_name'] ?? e['range']) == selectedRange).toList();
    }
    if (selectedZone != null) {
      records = records.where((e) => _text(e['zone_name']) == selectedZone).toList();
    }
    if (selectedDivision != null) {
      records = records.where((e) => _text(e['division_name']) == selectedDivision).toList();
    }
    if (selectedPs != null) {
      records = records.where((e) => _text(e['ps_name']) == selectedPs).toList();
    }
    return records;
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _text(value),
            ),
          ),
        ],
      ),
    );
  }

  void _showStageSelectionBottomSheet(Map<String, dynamic> record) {
    final gpid = _text(record['unique_id']);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.temple_hindu, color: Color(0xFF17365D)),
                      const SizedBox(width: 10),
                      Text(
                        'Select Festival Stage',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF17365D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Text('1'),
                  ),
                  title: const Text('Pre-Installation', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PreInstallationScreen(
                          applicationId: gpid,
                          ganeshRecord: record,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Text('2'),
                  ),
                  title: const Text('Installation', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InstallationCheckScreen(
                          applicationId: gpid,
                          ganeshRecord: record,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Text('3'),
                  ),
                  title: const Text('During Festivity', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FestivityCheckScreen(
                          applicationId: gpid,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Text('4'),
                  ),
                  title: const Text('Immersion', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImmersionWorkflowScreen(
                          applicationId: gpid,
                          ganeshRecord: record,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF1F5F9),
                    foregroundColor: Colors.grey,
                    child: Text('5'),
                  ),
                  title: const Text('Post-Immersion', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  trailing: const Icon(Icons.lock_outline, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post-Immersion is not yet active.')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    final ranges = availableRanges;
    final zones = availableZones;
    final divs = availableDivisions;
    final pss = availablePss;
    final isAdmin = widget.user.role.toLowerCase() == 'admin' || widget.user.accessLevel >= 8;

    if (!isAdmin && ranges.length <= 1 && zones.length <= 1 && divs.length <= 1 && pss.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Jurisdiction',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF17365D)),
          ),
          const SizedBox(height: 8),
          if (ranges.length > 1 || (isAdmin && ranges.isNotEmpty)) ...[
            DropdownButtonFormField<String>(
              value: selectedRange,
              decoration: const InputDecoration(
                labelText: 'Select Range',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Ranges')),
                ...ranges.map((e) => DropdownMenuItem(value: e, child: Text(e))),
              ],
              onChanged: (val) {
                setState(() {
                  selectedRange = val;
                  selectedZone = null;
                  selectedDivision = null;
                  selectedPs = null;
                });
              },
            ),
            const SizedBox(height: 8),
          ],
          if (zones.length > 1 || (isAdmin && zones.isNotEmpty)) ...[
            DropdownButtonFormField<String>(
              value: selectedZone,
              decoration: const InputDecoration(
                labelText: 'Select Zone',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Zones')),
                ...zones.map((e) => DropdownMenuItem(value: e, child: Text(e))),
              ],
              onChanged: (val) {
                setState(() {
                  selectedZone = val;
                  selectedDivision = null;
                  selectedPs = null;
                });
              },
            ),
            const SizedBox(height: 8),
          ],
          if (divs.length > 1 || (isAdmin && divs.isNotEmpty)) ...[
            DropdownButtonFormField<String>(
              value: selectedDivision,
              decoration: const InputDecoration(
                labelText: 'Select Division',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Divisions')),
                ...divs.map((e) => DropdownMenuItem(value: e, child: Text(e))),
              ],
              onChanged: (val) {
                setState(() {
                  selectedDivision = val;
                  selectedPs = null;
                });
              },
            ),
            const SizedBox(height: 8),
          ],
          if (pss.length > 1 || (isAdmin && pss.isNotEmpty)) ...[
            DropdownButtonFormField<String>(
              value: selectedPs,
              decoration: const InputDecoration(
                labelText: 'Select Police Station',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Police Stations')),
                ...pss.map((e) => DropdownMenuItem(value: e, child: Text(e))),
              ],
              onChanged: (val) {
                setState(() {
                  selectedPs = val;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('GPID Ganesh Idols'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureRecords,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading GPID records...', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 160),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 56, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Unable to load Ganesh records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF475569))),
                        const SizedBox(height: 22),
                        ElevatedButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (_allRecords.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(
                    child: Text('No GPID records found', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }

          final records = filteredRecords;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: records.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 100),
                            Center(
                              child: Text('No records match the selected filters.', style: TextStyle(fontSize: 15, color: Colors.grey)),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final record = records[index];
                            final gpid = _text(record['unique_id']);

                            return Card(
                              key: ValueKey(gpid),
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showStageSelectionBottomSheet(record),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.temple_hindu, size: 34, color: Color(0xFFD4AF37)),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('GPID', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                                                  const SizedBox(height: 2),
                                                  Text(gpid, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF008000))),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.touch_app, color: Color(0xFF008000)),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 24),
                                      _infoRow('Applicant', record['name']),
                                      _infoRow('Association', record['association']),
                                      _infoRow('Mobile', record['mobile_no']),
                                      if (_text(record['range_name'] ?? record['range']) != '-') _infoRow('Range', record['range_name'] ?? record['range']),
                                      _infoRow('Police Station', record['ps_name']),
                                      _infoRow('Zone', record['zone_name']),
                                      _infoRow('Division', record['division_name']),
                                      _infoRow('Idol Height', record['idol_height']),
                                      _infoRow('Pandal Height', record['pendal_height']),
                                      _infoRow('Idol Type', record['idol_type']),
                                      _infoRow('Status', record['status']),
                                      const SizedBox(height: 10),
                                      const Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'Tap to Select Stage',
                                          style: TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}