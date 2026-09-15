import 'package:flutter/material.dart';

import '../../services/verification_api_service.dart';

import 'location_verification_screen.dart';
import 'mandap_verification_screen.dart';
import 'idol_verification_screen.dart';
import 'route_verification_screen.dart';
import 'security_verification_screen.dart';
import 'organizer_verification_screen.dart';
import 'inter_departmental_verification_screen.dart';
import 'permission_sho_review_screen.dart';

class PreInstallationScreen extends StatefulWidget {
  final String applicationId;
  final Map<String, dynamic>? ganeshRecord;

  const PreInstallationScreen({
    super.key,
    required this.applicationId,
    this.ganeshRecord,
  });

  @override
  State<PreInstallationScreen> createState() =>
      _PreInstallationScreenState();
}

class _PreInstallationScreenState extends State<PreInstallationScreen> {
  bool _idolConstructedAtLocation = false;

  Map<String, dynamic>? _locationResult;
  Map<String, dynamic>? _mandapResult;
  Map<String, dynamic>? _idolResult;
  Map<String, dynamic>? _routeResult;
  Map<String, dynamic>? _securityResult;
  Map<String, dynamic>? _organizerResult;
  Map<String, dynamic>? _interDepartmentalResult;
  Map<String, dynamic>? _permissionShoReviewResult;

  final Set<int> _startedModules = <int>{};
  bool _loadingSavedVerification = true;
String _loadVerificationError = '';

@override
void initState() {
  super.initState();
  _loadSavedVerification();
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return null;
}

Future<void> _loadSavedVerification() async {
  try {
    final records =
        await VerificationApiService.fetchVerifications();

    final gpid =
        widget.applicationId.trim();

    Map<String, dynamic>? matched;

    for (final record in records) {
      final recordGpid =
          record['gpid']
              ?.toString()
              .trim() ??
          '';

      if (recordGpid == gpid) {
        matched = record;
        break;
      }
    }

    if (!mounted) {
      return;
    }

    if (matched == null) {
      setState(() {
        _loadingSavedVerification = false;
        _loadVerificationError = '';
      });
      return;
    }

    final idolResult =
        _asMap(
      matched['idolResult'],
    );

    final constructedValue =
        idolResult?[
          'idolConstructedAtLocation'
        ];

    setState(() {
      _locationResult =
          _asMap(
        matched!['locationResult'],
      );

      _mandapResult =
          _asMap(
        matched['mandapResult'],
      );

      _idolResult =
          idolResult;

      _routeResult =
          _asMap(
        matched['routeResult'],
      );

      _securityResult =
          _asMap(
        matched['securityResult'],
      );

      _organizerResult =
          _asMap(
        matched['organizerResult'],
      );

      _interDepartmentalResult =
          _asMap(
        matched[
          'interDepartmentalResult'
        ],
      );

      _permissionShoReviewResult =
          _asMap(
        matched[
          'permissionShoReviewResult'
        ],
      );

      _idolConstructedAtLocation =
          constructedValue == true ||
          constructedValue
                  ?.toString()
                  .trim()
                  .toUpperCase() ==
              'YES';

      _loadingSavedVerification = false;
      _loadVerificationError = '';
    });
  } catch (e) {
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingSavedVerification = false;
      _loadVerificationError =
          'Unable to load previously saved verification data.';
    });
  }
}

  Map<String, dynamic>? _resultForModule(int index) {
    switch (index) {
      case 0:
        return _locationResult;
      case 1:
        return _mandapResult;
      case 2:
        return _idolResult;
      case 3:
        return _routeResult;
      case 4:
        return _securityResult;
      case 5:
        return _organizerResult;
      case 6:
        return _interDepartmentalResult;
      case 7:
        return _permissionShoReviewResult;
      default:
        return null;
    }
  }

  String _moduleStatus(int index) {
    if (_resultForModule(index) != null) {
      return 'Completed';
    }

    if (_startedModules.contains(index)) {
      return 'In Progress';
    }

    return 'Ready';
  }

  void _markModuleStarted(int index) {
    if (_resultForModule(index) != null ||
        _startedModules.contains(index)) {
      return;
    }

    setState(() {
      _startedModules.add(index);
    });
  }

  String _text(dynamic value) {
    if (value == null) return '-';

    final valueText = value.toString().trim();

    if (valueText.isEmpty || valueText.toLowerCase() == 'null') {
      return '-';
    }

    return valueText;
  }

  Color _applicationStatusColor(dynamic value) {
    final status = _text(value).toUpperCase();

    if (status == 'APPROVED') {
      return Colors.green.shade700;
    }

    if (status == 'REJECTED') {
      return Colors.red.shade700;
    }

    if (status == 'PENDING') {
      return Colors.orange.shade800;
    }

    return const Color(0xFF475569);
  }

  Color _applicationStatusBackground(dynamic value) {
    final status = _text(value).toUpperCase();

    if (status == 'APPROVED') {
      return const Color(0xFFF0FDF4);
    }

    if (status == 'REJECTED') {
      return const Color(0xFFFEF2F2);
    }

    if (status == 'PENDING') {
      return const Color(0xFFFFFBEB);
    }

    return const Color(0xFFF8FAFC);
  }

  Color _applicationStatusBorder(dynamic value) {
    final status = _text(value).toUpperCase();

    if (status == 'APPROVED') {
      return const Color(0xFFBBF7D0);
    }

    if (status == 'REJECTED') {
      return const Color(0xFFFECACA);
    }

    if (status == 'PENDING') {
      return const Color(0xFFFDE68A);
    }

    return const Color(0xFFE2E8F0);
  }

  Widget _applicationField(
    String label,
    dynamic value, {
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),

          // Selectable so officers can long-press and copy
          // GPID, Reference ID, Mobile Number and other values.
          SelectableText(
            _text(value),
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicationInformationCard(
    int completedVerificationCount,
  ) {
    final record = widget.ganeshRecord;
    final status = record?['status'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD7E0EA),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIVE GANESH APPLICATION',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Application / GPID Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17365D),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _applicationStatusBackground(status),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _applicationStatusBorder(status),
                  ),
                ),
                child: Text(
                  _text(status).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _applicationStatusColor(status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFBFDBFE),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF17365D),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Verification Modules Completed: '
                    '$completedVerificationCount / 8',
                    style: const TextStyle(
                      color: Color(0xFF17365D),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _applicationField(
            'GPID',
            record?['unique_id'] ?? widget.applicationId,
          ),

          const SizedBox(height: 8),

          _applicationField(
            'Reference ID',
            record?['ref_no'],
          ),

          const SizedBox(height: 8),

          _applicationField(
            'Applicant Name',
            record?['name'],
          ),

          const SizedBox(height: 8),

          _applicationField(
            'Mobile Number',
            record?['mobile_no'],
          ),

          const SizedBox(height: 8),

          _applicationField(
            'Association / Mandal',
            record?['association'],
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _applicationField(
                  'Police Station',
                  record?['ps_name'],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _applicationField(
                  'Division',
                  record?['division_name'],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _applicationField(
                  'Zone',
                  record?['zone_name'],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _applicationField(
                  'District / Commissionerate',
                  record?['dist_name'],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _applicationField(
                  'Idol Type',
                  record?['idol_type'],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _applicationField(
                  'Declared Idol Height',
                  record?['idol_height'] == null
                      ? null
                      : '${record?['idol_height']} ft',
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _applicationField(
            'Area Category',
            record?['idol_area_type'],
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _applicationField(
                  'Installation From Date',
                  record?['instal_from_date'],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _applicationField(
                  'Installation To Date',
                  record?['instal_to_date'],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _applicationField(
                  'Immersion Date',
                  record?['immr_date'],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _applicationField(
                  'Immersion Point',
                  record?['riv_name'],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _applicationField(
            'House / Location',
            record?['h_no'],
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _applicationField(
                  'Street',
                  record?['street'],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _applicationField(
                  'Town / City',
                  record?['town'],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _applicationField(
            'PIN Code',
            record?['pin'],
          ),
        ],
      ),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    );
  }

  double? get _mandapLatitude {
    final evidence = _mandapResult?['mandapPhotoEvidence'];

    if (evidence is! Map) {
      return null;
    }

    return _toDouble(
      evidence['latitude'],
    );
  }

  double? get _mandapLongitude {
    final evidence = _mandapResult?['mandapPhotoEvidence'];

    if (evidence is! Map) {
      return null;
    }

    return _toDouble(
      evidence['longitude'],
    );
  }

  Future<void> _openIdolVerification() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => IdolVerificationScreen(
          applicationId: widget.applicationId,
          gpid: widget.applicationId,
          ganeshRecord: widget.ganeshRecord,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final constructedValue =
        result['idolConstructedAtLocation'];

    setState(() {
      _idolResult = result;

      _idolConstructedAtLocation =
          constructedValue == true ||
          constructedValue
                  ?.toString()
                  .trim()
                  .toUpperCase() ==
              'YES';
    });
  }

  Future<void> _openOrganizerVerification() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizerVerificationScreen(
          applicationId: widget.applicationId,
          gpid: widget.applicationId,
          ganeshRecord: widget.ganeshRecord,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _organizerResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'number': '1',
        'title': 'Location-Based Verification',
        'status': _moduleStatus(0),
      },
      {
        'number': '2',
        'title': 'Mandap-Based Verification',
        'status': _moduleStatus(1),
      },
      {
        'number': '3',
        'title': 'Idol-Based Verification',
        'status': _moduleStatus(2),
      },
      {
        'number': '4',
        'title': 'Route-Based Verification',
        'status': _moduleStatus(3),
      },
      {
        'number': '5',
        'title': 'Security-Based Verification',
        'status': _moduleStatus(4),
      },
      {
        'number': '6',
        'title': 'Organizer-Based Verification',
        'status': _moduleStatus(5),
      },
      {
        'number': '7',
        'title': 'Inter-Departmental Coordination / NOCs',
        'status': _moduleStatus(6),
      },
      {
        'number': '8',
        'title': 'Permission / SHO Review',
        'status': _moduleStatus(7),
      },
    ];

    final retainedVerificationResults =
        <Map<String, dynamic>?>[
      _locationResult,
      _mandapResult,
      _idolResult,
      _routeResult,
      _securityResult,
      _organizerResult,
      _interDepartmentalResult,
      _permissionShoReviewResult,
    ];

    final completedVerificationCount =
        retainedVerificationResults.where((e) => e != null).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
        title: const Text(
          'Pre-Installation Verification',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loadingSavedVerification
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text(
                    'Loading saved verification data...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
        padding: const EdgeInsets.only(
          bottom: 24,
        ),
        children: [
          _applicationInformationCard(
            completedVerificationCount,
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              4,
            ),
            child: Text(
              'Verification Modules',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              10,
            ),
            child: Text(
              'Complete the field verification modules for this GPID.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),

          ...List.generate(
            modules.length,
            (index) {
              final module = modules[index];

              final status = module['status']!;
              final bool completed = status == 'Completed';
              final bool inProgress = status == 'In Progress';

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: completed
                        ? Colors.green
                        : inProgress
                            ? Colors.orange
                            : const Color(0xFF17365D),
                    child: Text(
                      module['number']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    module['title']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(
                      top: 4,
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: completed
                            ? Colors.green
                            : inProgress
                                ? Colors.orange
                                : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  trailing: completed
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        )
                      : inProgress
                          ? const Icon(
                              Icons.pending_actions,
                              color: Colors.orange,
                            )
                          : const Icon(
                              Icons.chevron_right,
                            ),
                  onTap: () async {
                    _markModuleStarted(index);

                    // 1. LOCATION
                    if (index == 0) {
                      final result =
                          await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LocationVerificationScreen(
                            applicationId: widget.applicationId,
                            gpid: widget.applicationId,
                            ganeshRecord: widget.ganeshRecord,
                          ),
                        ),
                      );

                      if (!mounted || result == null) {
                        return;
                      }

                      setState(() {
                        _locationResult = result;
                      });

                      return;
                    }

                    // 2. MANDAP
                    if (index == 1) {
                      final result =
                          await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MandapVerificationScreen(
                            applicationId: widget.applicationId,
                            gpid: widget.applicationId,
                            ganeshRecord: widget.ganeshRecord,
                          ),
                        ),
                      );

                      if (!mounted || result == null) {
                        return;
                      }

                      setState(() {
                        _mandapResult = result;
                      });

                      return;
                    }

                    // 3. IDOL
                    if (index == 2) {
                      await _openIdolVerification();
                      return;
                    }

                    // 4. ROUTE
                    if (index == 3) {
                      final result =
                          await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RouteVerificationScreen(
                            applicationId: widget.applicationId,
                            gpid: widget.applicationId,
                            mandapLatitude: _mandapLatitude,
                            mandapLongitude: _mandapLongitude,
                            idolConstructedAtLocation:
                                _idolConstructedAtLocation,
                          ),
                        ),
                      );

                      if (!mounted || result == null) {
                        return;
                      }

                      setState(() {
                        _routeResult = result;
                      });

                      return;
                    }

                    // 5. SECURITY
                    if (index == 4) {
                      final result =
                          await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SecurityVerificationScreen(
                            applicationId: widget.applicationId,
                            gpid: widget.applicationId,
                          ),
                        ),
                      );

                      if (!mounted || result == null) {
                        return;
                      }

                      setState(() {
                        _securityResult = result;
                      });

                      return;
                    }

                    // 6. ORGANIZER
                    if (index == 5) {
                      await _openOrganizerVerification();
                      return;
                    }

                    // 7. INTER-DEPARTMENTAL COORDINATION / NOCs
                    if (index == 6) {
                      final result =
                          await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              InterDepartmentalVerificationScreen(
                            applicationId: widget.applicationId,
                            gpid: widget.applicationId,
                            ganeshRecord: widget.ganeshRecord,
                            locationResult: _locationResult,
                            mandapResult: _mandapResult,
                            idolResult: _idolResult,
                            routeResult: _routeResult,
                            securityResult: _securityResult,
                            organizerResult: _organizerResult,
                          ),
                        ),
                      );

                      if (!mounted || result == null) {
                        return;
                      }

                      setState(() {
                        _interDepartmentalResult = result;
                      });

                      return;
                    }

                    // 8. PERMISSION / SHO REVIEW
                    if (index == 7) {
                      final result =
                          await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PermissionShoReviewScreen(
                            applicationId: widget.applicationId,
                            gpid: widget.applicationId,
                            ganeshRecord: widget.ganeshRecord,
                            locationResult: _locationResult,
                            mandapResult: _mandapResult,
                            idolResult: _idolResult,
                            routeResult: _routeResult,
                            securityResult: _securityResult,
                            organizerResult: _organizerResult,
                            interDepartmentalResult:
                                _interDepartmentalResult,
                          ),
                        ),
                      );

                      if (!mounted || result == null) {
                        return;
                      }

                      setState(() {
                        _permissionShoReviewResult = result;
                      });

                      return;
                    }

                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${module['title']} will be developed next.',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}