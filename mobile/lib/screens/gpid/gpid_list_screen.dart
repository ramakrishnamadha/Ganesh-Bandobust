import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/gpid_api_service.dart';
import '../pre_installation/pre_installation_screen.dart';

class GpidListScreen extends StatefulWidget {
  final String userId;

  const GpidListScreen({
    super.key,
    required this.userId,
  });

  @override
  State<GpidListScreen> createState() => _GpidListScreenState();
}

class _GpidListScreenState extends State<GpidListScreen> {
  late Future<List<Map<String, dynamic>>> _futureRecords;

  @override
  void initState() {
    super.initState();
    _futureRecords = _loadRecords();
  }

  Future<List<Map<String, dynamic>>> _loadRecords() async {
    return GpidApiService.fetchGaneshRecords(
  userId: widget.userId,
).timeout(
      const Duration(seconds: 100),
      onTimeout: () {
        throw TimeoutException(
          'GPID records are taking too long to load.',
        );
      },
    );
  }

  Future<void> _refresh() async {
    final newFuture = _loadRecords();

    setState(() {
      _futureRecords = newFuture;
    });

    try {
      await newFuture;
    } catch (_) {
      // FutureBuilder will display the error.
    }
  }

  void _retry() {
    setState(() {
      _futureRecords = _loadRecords();
    });
  }

  String _text(dynamic value) {
    if (value == null) return '-';

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '-';
    }

    return text;
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

  void _openPreInstallation(
    Map<String, dynamic> record,
  ) {
    final gpid = _text(record['unique_id']);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreInstallationScreen(
          applicationId: gpid,
          ganeshRecord: record,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPID Ganesh Idols'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureRecords,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading GPID records...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Please wait',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 160),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 56,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Unable to load Ganesh records',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton.icon(
                          onPressed: _retry,
                          icon: const Icon(
                            Icons.refresh,
                          ),
                          label: const Text('RETRY'),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'You can also pull down to retry.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(
                    child: Text(
                      'No GPID records found',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];

                final gpid =
                    _text(record['unique_id']);

                return Card(
                  margin:
                      const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(12),
                    onTap: () {
                      _openPreInstallation(record);
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFF8FAFC),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.temple_hindu,
                                  size: 34,
                                  color: Color(
                                    0xFFD4AF37,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Text(
                                        'GPID',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color: Color(
                                            0xFF1565C0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 2,
                                      ),
                                      Text(
                                        gpid,
                                        style:
                                            const TextStyle(
                                          fontSize: 19,
                                          fontWeight:
                                              FontWeight
                                                  .w900,
                                          color: Color(
                                            0xFF008000,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color:
                                      Color(0xFF008000),
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 24),

                          _infoRow(
                            'Applicant',
                            record['name'],
                          ),

                          _infoRow(
                            'Association',
                            record['association'],
                          ),

                          _infoRow(
                            'Mobile',
                            record['mobile_no'],
                          ),

                          _infoRow(
                            'Police Station',
                            record['ps_name'],
                          ),

                          _infoRow(
                            'Zone',
                            record['zone_name'],
                          ),

                          _infoRow(
                            'Division',
                            record['division_name'],
                          ),

                          _infoRow(
                            'Idol Height',
                            record['idol_height'],
                          ),

                          _infoRow(
                            'Pandal Height',
                            record['pendal_height'],
                          ),

                          _infoRow(
                            'Idol Type',
                            record['idol_type'],
                          ),

                          _infoRow(
                            'Status',
                            record['status'],
                          ),

                          const SizedBox(height: 10),

                          const Align(
                            alignment:
                                Alignment.centerRight,
                            child: Text(
                              'Tap to open verification',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
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