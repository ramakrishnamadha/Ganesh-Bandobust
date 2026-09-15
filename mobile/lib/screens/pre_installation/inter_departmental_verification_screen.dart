import 'package:flutter/material.dart';

import '../../services/verification_api_service.dart';

class InterDepartmentalVerificationScreen extends StatefulWidget {
  const InterDepartmentalVerificationScreen({
    super.key,
    required this.applicationId,
    this.gpid,
    this.ganeshRecord,
    this.locationResult,
    this.mandapResult,
    this.idolResult,
    this.routeResult,
    this.securityResult,
    this.organizerResult,
  });

  final String applicationId;
  final String? gpid;
  final Map<String, dynamic>? ganeshRecord;
  final Map<String, dynamic>? locationResult;
  final Map<String, dynamic>? mandapResult;
  final Map<String, dynamic>? idolResult;
  final Map<String, dynamic>? routeResult;
  final Map<String, dynamic>? securityResult;
  final Map<String, dynamic>? organizerResult;

  @override
  State<InterDepartmentalVerificationScreen> createState() =>
      _InterDepartmentalVerificationScreenState();
}

class _CoordinationItem {
  _CoordinationItem({
    required this.sourceModule,
    required this.finding,
    required this.suggestedDepartments,
  });

  final String sourceModule;
  final String finding;
  final List<String> suggestedDepartments;

  String? coordinationRequired;
  String noReason = '';
  String? department;
  String? status;
  String referenceNo = '';
  DateTime? referenceDate;
  String remarks = '';
  String conditions = '';
  String? conditionsComplied;
  String rejectionReason = '';
  String furtherAction = '';
  String documentReference = '';

  Map<String, dynamic> toMap() {
    return {
      'sourceModule': sourceModule,
      'finding': finding,
      'coordinationRequired': coordinationRequired,
      'notRequiredReason': noReason,
      'department': department,
      'status': status,
      'referenceNo': referenceNo,
      'referenceDate': referenceDate?.toIso8601String(),
      'remarks': remarks,
      'conditions': conditions,
      'conditionsComplied': conditionsComplied,
      'rejectionReason': rejectionReason,
      'furtherAction': furtherAction,
      'documentReference': documentReference,
    };
  }
}

class _InterDepartmentalVerificationScreenState
    extends State<InterDepartmentalVerificationScreen> {
  final List<_CoordinationItem> _items = [];
  bool _initialized = false;
  bool _additionalRequired = false;
  bool? _unresolvedIssue;
  bool _declaration = false;
  bool _saving = false;

  final TextEditingController _additionalReasonController =
      TextEditingController();
  final TextEditingController _additionalReferenceController =
      TextEditingController();
  final TextEditingController _additionalRemarksController =
      TextEditingController();
  final TextEditingController _unresolvedDepartmentController =
      TextEditingController();
  final TextEditingController _unresolvedIssueController =
      TextEditingController();
  final TextEditingController _unresolvedActionController =
      TextEditingController();
  final TextEditingController _unresolvedRemarksController =
      TextEditingController();

  String? _additionalDepartment;
  String? _additionalStatus;

  static const List<String> _allDepartments = [
    'TGSPDCL',
    'Electrical - GHMC',
    'GHMC - Engineering',
    'GHMC - Horticulture',
    'GHMC - Sewerage',
    'GHMC - Sanitation',
    'GHMC - Enforcement',
    'GHMC',
    'HMWSSB',
    'HMDA',
    'HYDRAA',
    'R&B',
    'NHAI',
    'Traffic Police',
    'Law & Order Police',
    'Fire Services',
    'NDRF',
    'Revenue',
    'Other Government Department',
    'Private Agency / Organisation',
  ];

  static const List<String> _statuses = [
    'Not Initiated',
    'Request Sent',
    'Under Process',
    'NOC / Clearance Received',
    'Conditional Clearance',
    'Rejected',
    'Not Applicable',
  ];

  String get _selectedGpid {
    final value = (widget.gpid ?? widget.applicationId).trim();
    return value.isEmpty ? widget.applicationId : value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _buildAutomaticFindings();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _additionalReasonController.dispose();
    _additionalReferenceController.dispose();
    _additionalRemarksController.dispose();
    _unresolvedDepartmentController.dispose();
    _unresolvedIssueController.dispose();
    _unresolvedActionController.dispose();
    _unresolvedRemarksController.dispose();
    super.dispose();
  }

  bool _yes(dynamic value) =>
      value == true || value?.toString().toUpperCase() == 'YES';

  bool _no(dynamic value) =>
      value == false || value?.toString().toUpperCase() == 'NO';

  Map<String, dynamic>? _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<dynamic> _list(dynamic value) => value is List ? value : const [];

  void _addFinding(
    String module,
    String finding,
    List<String> departments,
  ) {
    final duplicate = _items.any(
      (e) => e.sourceModule == module && e.finding == finding,
    );
    if (!duplicate) {
      _items.add(
        _CoordinationItem(
          sourceModule: module,
          finding: finding,
          suggestedDepartments: departments,
        ),
      );
    }
  }

  void _buildAutomaticFindings() {
    final location = widget.locationResult;
    if (location != null) {
      if (_no(location['locationVerified'])) {
        _addFinding(
          'Location-Based Verification',
          'Installation location could not be verified. '
              'Remarks: ${location['remarks'] ?? '-'}',
          ['Law & Order Police'],
        );
      }
      if (_yes(location['locationChanged'])) {
        if (_no(location['samePoliceStation'])) {
          _addFinding(
            'Location-Based Verification',
            'Installation location has changed and falls outside the '
                'present Police Station jurisdiction. Recorded PS: '
                '${location['policeStation'] ?? '-'}, Commissionerate: '
                '${location['commissionerate'] ?? '-'}.',
            ['Law & Order Police'],
          );
        } else {
          _addFinding(
            'Location-Based Verification',
            'Installation location has changed within the Police Station. '
                'Sector: ${location['sector'] ?? '-'}.',
            ['Law & Order Police'],
          );
        }
      }
      if (_yes(location['disputedLand'])) {
        _addFinding(
          'Location-Based Verification',
          'Disputed land / location issue reported. '
              'Remarks: ${location['disputedLandRemarks'] ?? '-'}.',
          ['Revenue', 'Law & Order Police'],
        );
      }
      final sensitivity =
          (location['sensitivity'] ?? '').toString().toUpperCase();
      if (sensitivity == 'MEDIUM' || sensitivity == 'HIGH') {
        _addFinding(
          'Location-Based Verification',
          '$sensitivity sensitivity location recorded. '
              'Remarks: ${location['sensitivityRemarks'] ?? '-'}.',
          ['Law & Order Police'],
        );
      }
    }

    final mandap = widget.mandapResult;
    if (mandap != null && _yes(mandap['mandapInstalled'])) {
      if (_no(mandap['structuralStability'])) {
        _addFinding(
          'Mandap-Based Verification',
          'Mandap structural stability was not found satisfactory. '
              'Remarks: ${mandap['structuralRemarks'] ?? '-'}.',
          ['GHMC - Engineering'],
        );
      }
      if (_yes(mandap['roadObstruction'])) {
        _addFinding(
          'Mandap-Based Verification',
          'Mandap is causing road obstruction. Type: '
              '${mandap['obstructionType'] ?? '-'}. Traffic impact: '
              '${mandap['trafficImpact'] ?? '-'}.',
          ['Traffic Police', 'GHMC - Engineering', 'Law & Order Police'],
        );
      }
      if (_no(mandap['emergencyAccess'])) {
        _addFinding(
          'Mandap-Based Verification',
          'Emergency vehicle access is not satisfactory. '
              'Remarks: ${mandap['emergencyRemarks'] ?? '-'}.',
          ['Traffic Police', 'Fire Services', 'Law & Order Police'],
        );
      }
      if (_yes(mandap['overheadWires']) ||
          _yes(mandap['overheadWiresRisk'])) {
        _addFinding(
          'Mandap-Based Verification',
          'Overhead wire risk was observed at/near the Mandap. '
              'Remarks: ${mandap['overheadWiresRemarks'] ?? '-'}.',
          ['TGSPDCL', 'Electrical - GHMC'],
        );
      }
      if (_yes(mandap['electricalHazard']) ||
          _yes(mandap['electricalHazardRisk'])) {
        _addFinding(
          'Mandap-Based Verification',
          'Electrical hazard/risk was observed. Type: '
              '${mandap['electricalHazardType'] ?? '-'}. Remarks: '
              '${mandap['electricalHazardRemarks'] ?? '-'}.',
          ['TGSPDCL', 'Electrical - GHMC', 'Fire Services'],
        );
      }
      if (_no(mandap['mandapHeightVerified'])) {
        _addFinding(
          'Mandap-Based Verification',
          'Actual Mandap height does not match the declared height. '
              'Declared: ${mandap['declaredMandapHeight'] ?? '-'}, '
              'Actual: ${mandap['actualMandapHeight'] ?? '-'}.',
          ['GHMC - Engineering', 'Law & Order Police'],
        );
      }
    }

    final idol = widget.idolResult;
    if (idol != null && _yes(idol['idolInstalled'])) {
      if (_yes(idol['idolConstructedAtLocation'])) {
        _addFinding(
          'Idol-Based Verification',
          'Idol is constructed at the installation location; '
              'procession/route coordination may need review.',
          ['Traffic Police', 'Law & Order Police'],
        );
      }
      if (_no(idol['heightMatches'])) {
        _addFinding(
          'Idol-Based Verification',
          'Actual Idol height does not match the declared height. '
              'Declared: ${idol['declaredIdolHeight'] ?? '-'}, '
              'Actual: ${idol['actualHeightFeet'] ?? '-'} ft '
              '${idol['actualHeightInches'] ?? '-'} in.',
          ['Traffic Police', 'Law & Order Police'],
        );
      }
      if (_no(idol['basePlatformSafe'])) {
        _addFinding(
          'Idol-Based Verification',
          'Idol base/platform was not found safe. '
              'Remarks: ${idol['baseSafetyRemarks'] ?? '-'}.',
          ['GHMC - Engineering', 'Law & Order Police'],
        );
      }
    }

    final route = widget.routeResult;
    if (route != null) {
      if (_no(route['installationRouteVerified'])) {
        _addFinding(
          'Route-Based Verification',
          'Installation route was not verified. '
              'Remarks: ${route['remarks'] ?? '-'}.',
          ['Traffic Police', 'Law & Order Police'],
        );
      }
      if (_no(route['constructedAtLocationProcessionRouteVerified'])) {
        _addFinding(
          'Route-Based Verification',
          'Procession route for the Idol constructed at location '
              'was not verified.',
          ['Traffic Police', 'Law & Order Police'],
        );
      }

      for (final stretchValue in _list(route['routeStretches'])) {
        final stretch = _map(stretchValue);
        if (stretch == null) continue;
        for (final issueValue in _list(stretch['issues'])) {
          final issue = _map(issueValue);
          if (issue == null || !_yes(issue['noticed'])) continue;
          if (issue['routeImpact'] != null && _no(issue['routeImpact'])) {
            continue;
          }
          if (_no(issue['informRequired'])) continue;

          final title = (issue['title'] ?? 'Route issue').toString();
          final department = (issue['department'] ?? '').toString().trim();
          final informed = issue['informed'];

          final departments = <String>[];
          if (department.isNotEmpty) departments.add(department);
          if (departments.isEmpty) {
            departments.addAll(['Traffic Police', 'Law & Order Police']);
          }

          final statusText = _yes(informed)
              ? 'Concerned authority was informed; follow-up/status may be recorded.'
              : 'Concerned authority was not informed or remains pending.';

          _addFinding(
            'Route-Based Verification',
            '$title $statusText Remarks: ${issue['remarks'] ?? '-'}.',
            departments,
          );
        }
      }
    }

    final security = widget.securityResult;
    if (security != null) {
      if (_no(security['securityVerified'])) {
        _addFinding(
          'Security-Based Verification',
          'Security arrangements were not verified/satisfactory. '
              'Remarks: ${security['securityVerificationRemarks'] ?? '-'}.',
          ['Law & Order Police'],
        );
      } else {
        const commonLabels = <int, String>{
          2: 'Organiser / volunteer security arrangements are not available.',
          4: 'Barricading / access control arrangements are not available.',
          6: 'Electrical safety arrangements are not proper.',
          7: 'Emergency vehicle access is not available.',
          8: 'Adequate crowd management arrangements are not available.',
          9: 'Safe entry and exit arrangements are not available.',
          10: 'Adequate lighting arrangements are not available.',
          11: 'Public Address / announcement system is not available.',
        };

        for (final entry in commonLabels.entries) {
          final point = _map(security['point${entry.key}']);
          if (point == null || !_no(point['available'])) continue;
          if (_no(point['adviseRequired'])) continue;

          final deps = entry.key == 6
              ? ['TGSPDCL', 'Electrical - GHMC', 'Fire Services']
              : entry.key == 7
                  ? ['Traffic Police', 'Fire Services', 'Law & Order Police']
                  : ['Law & Order Police'];

          _addFinding(
            'Security-Based Verification',
            '${entry.value} Organiser informed: '
                '${point['organiserInformed'] ?? '-'}. '
                'Remarks: ${point['remarks'] ?? '-'}.',
            deps,
          );
        }

        final cctv = _map(security['point3']);
        if (cctv != null && _no(cctv['cctvAvailable'])) {
          _addFinding(
            'Security-Based Verification',
            'CCTV surveillance is not available at the Mandap. '
                'Organiser informed: ${cctv['organiserInformed'] ?? '-'}. '
                'Remarks: ${cctv['remarks'] ?? '-'}.',
            ['Law & Order Police'],
          );
        }

        final fire = _map(security['point5']);
        if (fire != null &&
            (_no(fire['fireExtinguisherAvailable']) ||
                _no(fire['waterArrangementAvailable']) ||
                _no(fire['sandArrangementAvailable']))) {
          _addFinding(
            'Security-Based Verification',
            'One or more fire safety arrangements are missing. '
                'Organiser informed: ${fire['organiserInformed'] ?? '-'}. '
                'Remarks: ${fire['remarks'] ?? '-'}.',
            ['Fire Services', 'Law & Order Police'],
          );
        }
      }
    }

    final organizer = widget.organizerResult;
    if (organizer != null) {
      if (_no(organizer['allOrganizersPersonallyVerified'])) {
        _addFinding(
          'Organizer-Based Verification',
          'All organizer/member details could not be personally verified. '
              'Remarks: ${organizer['remarks'] ?? '-'}.',
          ['Law & Order Police'],
        );
      }

      for (final personValue in _list(organizer['organizers'])) {
        final person = _map(personValue);
        if (person == null) continue;
        final name = (person['name'] ?? 'Organizer').toString();

        if (_no(person['contactVerified'])) {
          _addFinding(
            'Organizer-Based Verification',
            'Contact/identity verification was not successful for $name. '
                'Remarks: ${person['contactRemarks'] ?? '-'}.',
            ['Law & Order Police'],
          );
        }

        if (_yes(person['adverseInformation'])) {
          _addFinding(
            'Organizer-Based Verification',
            'CONFIDENTIAL: Adverse information / previous case(s) '
                'were recorded for $name. Requires officer-level review.',
            ['Law & Order Police'],
          );
        }
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _yesNo({
    required bool? value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const SizedBox(
              width: double.infinity,
              child: Text('YES', textAlign: TextAlign.center),
            ),
            selected: value == true,
            onSelected: (_) => onChanged(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const SizedBox(
              width: double.infinity,
              child: Text('NO', textAlign: TextAlign.center),
            ),
            selected: value == false,
            onSelected: (_) => onChanged(false),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(_CoordinationItem item, int index) {
    final departmentItems = <String>{
      ...item.suggestedDepartments,
      ..._allDepartments,
    }.toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${index + 1}. ${item.sourceModule}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF17365D),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(item.finding),
            ),
            const SizedBox(height: 14),
            const Text(
              'Is Coordination / NOC Required?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _yesNo(
              value: item.coordinationRequired == null
                  ? null
                  : item.coordinationRequired == 'YES',
              onChanged: (value) {
                setState(() {
                  item.coordinationRequired = value ? 'YES' : 'NO';
                  if (value) {
                    item.noReason = '';
                    item.department ??= item.suggestedDepartments.isNotEmpty
                        ? item.suggestedDepartments.first
                        : null;
                  } else {
                    item.department = null;
                    item.status = null;
                  }
                });
              },
            ),
            if (item.coordinationRequired == 'NO') ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: item.noReason,
                maxLines: 3,
                decoration: _inputDecoration(
                  'Mandatory Reason / Remarks',
                ),
                onChanged: (value) => item.noReason = value,
              ),
            ],
            if (item.coordinationRequired == 'YES') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: item.department,
                isExpanded: true,
                decoration: _inputDecoration('Department / Agency'),
                items: departmentItems
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => item.department = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: item.status,
                isExpanded: true,
                decoration: _inputDecoration('Coordination / NOC Status'),
                items: _statuses
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => item.status = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: item.referenceNo,
                decoration: _inputDecoration(
                  'Reference / Application No.',
                  hint: 'If available',
                ),
                onChanged: (value) => item.referenceNo = value,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: item.referenceDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (date != null) {
                    setState(() => item.referenceDate = date);
                  }
                },
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  item.referenceDate == null
                      ? 'SELECT REFERENCE DATE'
                      : '${item.referenceDate!.day.toString().padLeft(2, '0')}-'
                          '${item.referenceDate!.month.toString().padLeft(2, '0')}-'
                          '${item.referenceDate!.year}',
                ),
              ),
              if (item.status == 'NOC / Clearance Received') ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: item.documentReference,
                  decoration: _inputDecoration(
                    'NOC / Clearance Document Reference',
                    hint: 'Document/photo reference',
                  ),
                  onChanged: (value) => item.documentReference = value,
                ),
              ],
              if (item.status == 'Conditional Clearance') ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: item.conditions,
                  maxLines: 3,
                  decoration: _inputDecoration('Conditions'),
                  onChanged: (value) => item.conditions = value,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Conditions Complied?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _yesNo(
                  value: item.conditionsComplied == null
                      ? null
                      : item.conditionsComplied == 'YES',
                  onChanged: (value) {
                    setState(() {
                      item.conditionsComplied = value ? 'YES' : 'NO';
                    });
                  },
                ),
              ],
              if (item.status == 'Rejected') ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: item.rejectionReason,
                  maxLines: 3,
                  decoration: _inputDecoration('Rejection Reason'),
                  onChanged: (value) => item.rejectionReason = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: item.furtherAction,
                  maxLines: 3,
                  decoration: _inputDecoration('Further Action / Remarks'),
                  onChanged: (value) => item.furtherAction = value,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                initialValue: item.remarks,
                maxLines: 3,
                decoration: _inputDecoration('Remarks'),
                onChanged: (value) => item.remarks = value,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _validate() {
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.coordinationRequired == null) {
        _showMessage(
          'Please answer Coordination / NOC Required for Finding ${i + 1}.',
        );
        return false;
      }
      if (item.coordinationRequired == 'NO' &&
          item.noReason.trim().isEmpty) {
        _showMessage(
          'Reason is mandatory when Coordination / NOC is not required.',
        );
        return false;
      }
      if (item.coordinationRequired == 'YES') {
        if (item.department == null || item.department!.trim().isEmpty) {
          _showMessage('Please select Department / Agency for Finding ${i + 1}.');
          return false;
        }
        if (item.status == null) {
          _showMessage('Please select Status for Finding ${i + 1}.');
          return false;
        }
        if (item.status == 'Conditional Clearance') {
          if (item.conditions.trim().isEmpty ||
              item.conditionsComplied == null) {
            _showMessage(
              'Please enter conditions and compliance status for Finding ${i + 1}.',
            );
            return false;
          }
        }
        if (item.status == 'Rejected' &&
            item.rejectionReason.trim().isEmpty) {
          _showMessage('Rejection Reason is mandatory for Finding ${i + 1}.');
          return false;
        }
      }
    }

    if (_additionalRequired) {
      if (_additionalDepartment == null ||
          _additionalReasonController.text.trim().isEmpty ||
          _additionalStatus == null) {
        _showMessage(
          'Please complete Additional Coordination details.',
        );
        return false;
      }
    }

    if (_unresolvedIssue == null) {
      _showMessage('Please answer: Any Unresolved Inter-Departmental Issue?');
      return false;
    }

    if (_unresolvedIssue == true) {
      if (_unresolvedDepartmentController.text.trim().isEmpty ||
          _unresolvedIssueController.text.trim().isEmpty ||
          _unresolvedActionController.text.trim().isEmpty) {
        _showMessage(
          'Department, Pending Issue and Action Required are mandatory.',
        );
        return false;
      }
    }

    if (!_declaration) {
      _showMessage('Field Officer Confirmation is mandatory.');
      return false;
    }

    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Inter-Departmental Verification Confirmation'),
        content: const Text(
          'I hereby confirm that the Inter-Departmental coordination / '
          'NOC requirements arising out of the field verification have '
          'been verified and the status recorded above is correct to the '
          'best of my knowledge.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('CONFIRM & SAVE'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = {
      'applicationId': widget.applicationId,
      'gpid': _selectedGpid,
      'autoIdentifiedRequirements': _items.map((e) => e.toMap()).toList(),
      'additionalCoordinationRequired': _additionalRequired,
      'additionalCoordination': _additionalRequired
          ? {
              'department': _additionalDepartment,
              'reason': _additionalReasonController.text.trim(),
              'status': _additionalStatus,
              'referenceNo': _additionalReferenceController.text.trim(),
              'remarks': _additionalRemarksController.text.trim(),
            }
          : null,
      'unresolvedInterDepartmentalIssue': _unresolvedIssue,
      'unresolvedIssueDetails': _unresolvedIssue == true
          ? {
              'department': _unresolvedDepartmentController.text.trim(),
              'issue': _unresolvedIssueController.text.trim(),
              'actionRequired': _unresolvedActionController.text.trim(),
              'remarks': _unresolvedRemarksController.text.trim(),
            }
          : null,
      'fieldOfficerConfirmation': true,
      'verifiedAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _saving = true;
    });

    try {
      await VerificationApiService.saveModuleResult(
        applicationId: widget.applicationId,
        gpid: _selectedGpid,
        moduleKey: 'interDepartmentalResult',
        result: result,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Unable to save Inter-Departmental Coordination / NOC '
        'verification to the server. Please check the network '
        'and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicant = (widget.ganeshRecord?['name'] ?? '-').toString();
    final association =
        (widget.ganeshRecord?['association'] ?? '-').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
        title: const Text('Inter-Departmental Coordination / NOCs'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SELECTED GPID',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedGpid,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17365D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Applicant: $applicant'),
                    Text('Association: $association'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'AUTO-IDENTIFIED COORDINATION REQUIREMENTS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF17365D),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'These items are generated from the findings recorded in '
              'Verification Modules 1 to 6. The field officer shall decide '
              'whether coordination / NOC is actually required.',
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Text(
                  'No specific coordination requirement was automatically '
                  'identified from the available verification findings.',
                ),
              )
            else
              for (int i = 0; i < _items.length; i++) _buildItem(_items[i], i),
            const SizedBox(height: 16),
            const Text(
              'Additional Coordination Required?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF17365D),
              ),
            ),
            const SizedBox(height: 8),
            _yesNo(
              value: _additionalRequired,
              onChanged: (value) {
                setState(() {
                  _additionalRequired = value;
                  if (!value) {
                    _additionalDepartment = null;
                    _additionalStatus = null;
                    _additionalReasonController.clear();
                    _additionalReferenceController.clear();
                    _additionalRemarksController.clear();
                  }
                });
              },
            ),
            if (_additionalRequired) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _additionalDepartment,
                isExpanded: true,
                decoration: _inputDecoration('Department / Agency'),
                items: _allDepartments
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _additionalDepartment = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _additionalReasonController,
                maxLines: 3,
                decoration: _inputDecoration('Reason for Coordination'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _additionalStatus,
                isExpanded: true,
                decoration: _inputDecoration('Status'),
                items: _statuses
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _additionalStatus = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _additionalReferenceController,
                decoration: _inputDecoration(
                  'Reference / Application No.',
                  hint: 'If available',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _additionalRemarksController,
                maxLines: 3,
                decoration: _inputDecoration('Remarks'),
              ),
            ],
            const SizedBox(height: 22),
            const Text(
              'Any Unresolved Inter-Departmental Issue?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF17365D),
              ),
            ),
            const SizedBox(height: 8),
            _yesNo(
              value: _unresolvedIssue,
              onChanged: (value) {
                setState(() {
                  _unresolvedIssue = value;
                  if (!value) {
                    _unresolvedDepartmentController.clear();
                    _unresolvedIssueController.clear();
                    _unresolvedActionController.clear();
                    _unresolvedRemarksController.clear();
                  }
                });
              },
            ),
            if (_unresolvedIssue == true) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _unresolvedDepartmentController,
                decoration: _inputDecoration('Department / Agency'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _unresolvedIssueController,
                maxLines: 3,
                decoration: _inputDecoration('Issue / Pending Requirement'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _unresolvedActionController,
                maxLines: 3,
                decoration: _inputDecoration('Action Required'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _unresolvedRemarksController,
                maxLines: 3,
                decoration: _inputDecoration('Remarks'),
              ),
            ],
            const SizedBox(height: 22),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _declaration,
              onChanged: (value) =>
                  setState(() => _declaration = value ?? false),
              title: const Text(
                'I hereby confirm that the Inter-Departmental coordination / '
                'NOC requirements arising out of the field verification have '
                'been verified and the status recorded above is correct to '
                'the best of my knowledge.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'CONFIRM & SAVE',
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
