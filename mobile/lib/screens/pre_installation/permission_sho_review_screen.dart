import 'package:flutter/material.dart';

import '../../services/verification_api_service.dart';

class PermissionShoReviewScreen extends StatefulWidget {
  const PermissionShoReviewScreen({
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
    this.interDepartmentalResult,
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
  final Map<String, dynamic>? interDepartmentalResult;

  @override
  State<PermissionShoReviewScreen> createState() =>
      _PermissionShoReviewScreenState();
}

class _PermissionShoReviewScreenState
    extends State<PermissionShoReviewScreen> {
  String? _allVerificationsCompleted;
  String? _allIssuesAddressed;
  String? _coordinationCompleted;
  String? _permissionDecision;

  final TextEditingController _conditionsController =
      TextEditingController();
  final TextEditingController _notRecommendedReasonController =
      TextEditingController();
  final TextEditingController _shoRemarksController =
      TextEditingController();

  bool _shoConfirmation = false;
  bool _saving = false;

  String get _selectedGpid {
    final value = (widget.gpid ?? widget.applicationId).trim();
    return value.isEmpty ? widget.applicationId : value;
  }

  @override
  void dispose() {
    _conditionsController.dispose();
    _notRecommendedReasonController.dispose();
    _shoRemarksController.dispose();
    super.dispose();
  }

  String _text(dynamic value) {
    if (value == null) return '-';

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '-';
    }

    return text;
  }

  bool _yes(dynamic value) =>
      value == true ||
      value?.toString().toUpperCase() == 'YES';

  bool _no(dynamic value) =>
      value == false ||
      value?.toString().toUpperCase() == 'NO';

  Map<String, dynamic>? _map(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  List<dynamic> _list(dynamic value) =>
      value is List ? value : const [];

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _yesNoSelector({
    required String? value,
    required ValueChanged<String> onChanged,
    bool includeNotApplicable = false,
  }) {
    final values = includeNotApplicable
        ? const [
            'YES',
            'NO',
            'NOT APPLICABLE',
          ]
        : const [
            'YES',
            'NO',
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (item) => ChoiceChip(
              label: Text(item),
              selected: value == item,
              onSelected: (_) => onChanged(item),
            ),
          )
          .toList(),
    );
  }

  List<Map<String, String>> _moduleSummary() {
    return [
      {
        'module': '1. Location-Based Verification',
        'status':
            widget.locationResult == null
                ? 'Not Completed'
                : 'Completed',
      },
      {
        'module': '2. Mandap-Based Verification',
        'status':
            widget.mandapResult == null
                ? 'Not Completed'
                : 'Completed',
      },
      {
        'module': '3. Idol-Based Verification',
        'status':
            widget.idolResult == null
                ? 'Not Completed'
                : 'Completed',
      },
      {
        'module': '4. Route-Based Verification',
        'status':
            widget.routeResult == null
                ? 'Not Completed'
                : 'Completed',
      },
      {
        'module': '5. Security-Based Verification',
        'status':
            widget.securityResult == null
                ? 'Not Completed'
                : 'Completed',
      },
      {
        'module': '6. Organizer-Based Verification',
        'status':
            widget.organizerResult == null
                ? 'Not Completed'
                : 'Completed',
      },
      {
        'module':
            '7. Inter-Departmental Coordination / NOCs',
        'status':
            widget.interDepartmentalResult == null
                ? 'Not Completed'
                : 'Completed',
      },
    ];
  }

  List<String> _adverseFindings() {
    final findings = <String>[];

    final location = widget.locationResult;

    if (location != null) {
      if (_no(location['locationVerified'])) {
        findings.add(
          'Location: Installation location was not verified. '
          'Remarks: ${_text(location['remarks'])}',
        );
      }

      if (_yes(location['locationChanged'])) {
        findings.add(
          'Location: Installation location has changed. '
          'Police Station: ${_text(location['policeStation'])}; '
          'Sector: ${_text(location['sector'])}.',
        );
      }

      if (_yes(location['disputedLand'])) {
        findings.add(
          'Location: Disputed land/location issue recorded. '
          'Remarks: ${_text(location['disputedLandRemarks'])}',
        );
      }

      final sensitivity =
          _text(
            location['sensitivity'],
          ).toUpperCase();

      if (sensitivity == 'MEDIUM' ||
          sensitivity == 'HIGH') {
        findings.add(
          'Location: $sensitivity sensitivity location. '
          'Remarks: ${_text(location['sensitivityRemarks'])}',
        );
      }
    }

    final mandap = widget.mandapResult;

    if (mandap != null) {
      if (_no(mandap['mandapInstalled'])) {
        findings.add(
          'Mandap: Mandap was not installed. '
          'Remarks: '
          '${_text(mandap['mandapNotInstalledRemarks'])}',
        );
      } else {
        if (_no(mandap['structuralStability'])) {
          findings.add(
            'Mandap: Structural stability not satisfactory. '
            'Remarks: '
            '${_text(mandap['structuralRemarks'])}',
          );
        }

        if (_yes(mandap['roadObstruction'])) {
          findings.add(
            'Mandap: Road obstruction recorded. '
            'Type: ${_text(mandap['obstructionType'])}; '
            'Traffic impact: '
            '${_text(mandap['trafficImpact'])}.',
          );
        }

        if (_no(mandap['emergencyAccess'])) {
          findings.add(
            'Mandap: Emergency access not satisfactory. '
            'Remarks: '
            '${_text(mandap['emergencyRemarks'])}',
          );
        }

        if (_yes(mandap['overheadWires']) ||
            _yes(mandap['overheadWiresRisk'])) {
          findings.add(
            'Mandap: Overhead wire issue/risk recorded. '
            'Remarks: '
            '${_text(mandap['overheadWiresRemarks'])}',
          );
        }

        if (_yes(mandap['electricalHazard']) ||
            _yes(mandap['electricalHazardRisk'])) {
          findings.add(
            'Mandap: Electrical hazard/risk recorded. '
            'Remarks: '
            '${_text(mandap['electricalHazardRemarks'])}',
          );
        }

        if (_no(mandap['mandapHeightVerified'])) {
          findings.add(
            'Mandap: Height mismatch. Declared: '
            '${_text(mandap['declaredMandapHeight'])}; '
            'Actual: '
            '${_text(mandap['actualMandapHeight'])}.',
          );
        }
      }
    }

    final idol = widget.idolResult;

    if (idol != null) {
      if (_no(idol['idolInstalled'])) {
        findings.add(
          'Idol: Idol was not installed at verification time.',
        );
      }

      if (_no(idol['heightMatches'])) {
        findings.add(
          'Idol: Height mismatch. Declared: '
          '${_text(idol['declaredIdolHeight'])}; '
          'Actual: '
          '${_text(idol['actualHeightFeet'])} ft '
          '${_text(idol['actualHeightInches'])} in.',
        );
      }

      if (_no(idol['basePlatformSafe'])) {
        findings.add(
          'Idol: Base/platform was not found safe. '
          'Remarks: '
          '${_text(idol['baseSafetyRemarks'])}',
        );
      }
    }

    final route = widget.routeResult;

    if (route != null) {
      if (_no(route['installationRouteVerified'])) {
        findings.add(
          'Route: Installation route was not verified. '
          'Remarks: ${_text(route['remarks'])}',
        );
      }

      if (_no(
        route[
            'constructedAtLocationProcessionRouteVerified'],
      )) {
        findings.add(
          'Route: Procession route for Idol constructed at '
          'location was not verified.',
        );
      }

      for (final stretchValue
          in _list(route['routeStretches'])) {
        final stretch = _map(stretchValue);

        if (stretch == null) {
          continue;
        }

        for (final issueValue
            in _list(stretch['issues'])) {
          final issue = _map(issueValue);

          if (issue == null ||
              !_yes(issue['noticed'])) {
            continue;
          }

          findings.add(
            'Route: ${_text(issue['title'])}. '
            'Department: '
            '${_text(issue['department'])}; '
            'Informed: '
            '${_text(issue['informed'])}; '
            'Remarks: '
            '${_text(issue['remarks'])}',
          );
        }
      }
    }

    final security = widget.securityResult;

    if (security != null) {
      if (_no(security['securityVerified'])) {
        findings.add(
          'Security: Security verification was not '
          'satisfactory/completed. '
          'Remarks: '
          '${_text(security['securityVerificationRemarks'])}',
        );
      }

      for (final pointNo in [
        2,
        4,
        6,
        7,
        8,
        9,
        10,
        11,
      ]) {
        final point =
            _map(security['point$pointNo']);

        if (point != null &&
            _no(point['available'])) {
          findings.add(
            'Security Point $pointNo: Required arrangement '
            'not available. '
            'Organiser informed: '
            '${_text(point['organiserInformed'])}; '
            'Remarks: '
            '${_text(point['remarks'])}',
          );
        }
      }

      final cctv = _map(security['point3']);

      if (cctv != null &&
          _no(cctv['cctvAvailable'])) {
        findings.add(
          'Security: CCTV not available. '
          'Remarks: '
          '${_text(cctv['remarks'])}',
        );
      }

      final fire = _map(security['point5']);

      if (fire != null &&
          (_no(fire['fireExtinguisherAvailable']) ||
              _no(
                fire[
                    'waterArrangementAvailable'],
              ) ||
              _no(
                fire[
                    'sandArrangementAvailable'],
              ))) {
        findings.add(
          'Security: One or more fire safety arrangements '
          'are not available. '
          'Remarks: '
          '${_text(fire['remarks'])}',
        );
      }
    }

    final organizer = widget.organizerResult;

    if (organizer != null) {
      if (_no(
        organizer[
            'allOrganizersPersonallyVerified'],
      )) {
        findings.add(
          'Organizer: All organizers were not personally '
          'verified. '
          'Remarks: '
          '${_text(organizer['remarks'])}',
        );
      }

      for (final personValue
          in _list(organizer['organizers'])) {
        final person = _map(personValue);

        if (person == null) {
          continue;
        }

        if (_no(person['contactVerified'])) {
          findings.add(
            'Organizer: Contact verification not completed '
            'for ${_text(person['name'])}.',
          );
        }

        if (_yes(person['adverseInformation'])) {
          findings.add(
            'Organizer: CONFIDENTIAL police-review finding '
            'exists for ${_text(person['name'])}.',
          );
        }
      }
    }

    final coordination =
        widget.interDepartmentalResult;

    if (coordination != null) {
      for (final itemValue
          in _list(
            coordination[
                'autoIdentifiedRequirements'],
          )) {
        final item = _map(itemValue);

        if (item == null) {
          continue;
        }

        if (_yes(item['coordinationRequired'])) {
          final status =
              _text(item['status']);

          if (status !=
                  'NOC / Clearance Received' &&
              status != 'Not Applicable') {
            findings.add(
              'Inter-Departmental: '
              '${_text(item['finding'])} '
              'Department: '
              '${_text(item['department'])}; '
              'Status: $status.',
            );
          }

          if (status ==
                  'Conditional Clearance' &&
              _no(
                item['conditionsComplied'],
              )) {
            findings.add(
              'Inter-Departmental: Conditional clearance '
              'conditions are not yet complied with for '
              '${_text(item['department'])}.',
            );
          }

          if (status == 'Rejected') {
            findings.add(
              'Inter-Departmental: Coordination / clearance '
              'was rejected by '
              '${_text(item['department'])}. '
              'Reason: '
              '${_text(item['rejectionReason'])}.',
            );
          }
        }
      }

      if (_yes(
        coordination[
            'additionalCoordinationRequired'],
      )) {
        final additional =
            _map(
              coordination[
                  'additionalCoordination'],
            );

        if (additional != null) {
          final status =
              _text(additional['status']);

          if (status !=
                  'NOC / Clearance Received' &&
              status != 'Not Applicable') {
            findings.add(
              'Inter-Departmental: Additional coordination '
              'with ${_text(additional['department'])} '
              'is $status. '
              'Reason: '
              '${_text(additional['reason'])}.',
            );
          }
        }
      }

      if (_yes(
        coordination[
            'unresolvedInterDepartmentalIssue'],
      )) {
        final unresolved =
            _map(
              coordination[
                  'unresolvedIssueDetails'],
            );

        findings.add(
          'Inter-Departmental: Unresolved issue with '
          '${_text(unresolved?['department'])}. '
          'Issue: '
          '${_text(unresolved?['issue'])}; '
          'Action required: '
          '${_text(unresolved?['actionRequired'])}.',
        );
      }
    }

    return findings;
  }

  bool _validate() {
    if (_allVerificationsCompleted == null) {
      _showMessage(
        'Please answer whether all required verifications '
        'are completed.',
      );
      return false;
    }

    if (_allIssuesAddressed == null) {
      _showMessage(
        'Please answer whether all observations / '
        'deficiencies are addressed.',
      );
      return false;
    }

    if (_coordinationCompleted == null) {
      _showMessage(
        'Please record the status of required departmental '
        'coordination / NOCs.',
      );
      return false;
    }

    if (_permissionDecision == null) {
      _showMessage(
        'Please select the SHO Permission Recommendation.',
      );
      return false;
    }

    if (_permissionDecision ==
            'Recommended with Conditions' &&
        _conditionsController.text
            .trim()
            .isEmpty) {
      _showMessage(
        'Conditions / Instructions are mandatory.',
      );
      return false;
    }

    if (_permissionDecision ==
            'Not Recommended' &&
        _notRecommendedReasonController.text
            .trim()
            .isEmpty) {
      _showMessage(
        'Reason is mandatory when permission is not '
        'recommended.',
      );
      return false;
    }

    if (!_shoConfirmation) {
      _showMessage(
        'SHO Confirmation is mandatory.',
      );
      return false;
    }

    return true;
  }

  Future<void> _save() async {
    if (!_validate()) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
        title: const Text(
          'SHO Review Confirmation',
        ),
        content: const Text(
          'I have reviewed the Pre-Installation Verification '
          'findings and the status of the required coordination '
          '/ clearances for the selected GPID. The recommendation '
          'recorded above is based on the verification information '
          'available at the time of review.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              false,
            ),
            child: const Text(
              'CANCEL',
            ),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              true,
            ),
            child: const Text(
              'CONFIRM & SUBMIT',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    setState(
      () => _saving = true,
    );

    final shoReviewResult =
        <String, dynamic>{
      'applicationId':
          widget.applicationId,
      'gpid':
          _selectedGpid,
      'allRequiredVerificationsCompleted':
          _allVerificationsCompleted,
      'allObservationsAddressed':
          _allIssuesAddressed,
      'departmentalCoordinationCompleted':
          _coordinationCompleted,
      'permissionRecommendation':
          _permissionDecision,
      'conditions':
          _permissionDecision ==
                  'Recommended with Conditions'
              ? _conditionsController.text
                  .trim()
              : null,
      'notRecommendedReason':
          _permissionDecision ==
                  'Not Recommended'
              ? _notRecommendedReasonController
                  .text
                  .trim()
              : null,
      'shoRemarks':
          _shoRemarksController.text
              .trim(),
      'shoConfirmation':
          true,
      'reviewedAt':
          DateTime.now()
              .toIso8601String(),
    };

    final verificationPayload =
        <String, dynamic>{
      'applicationId':
          widget.applicationId,
      'gpid':
          _selectedGpid,
      'locationResult':
          widget.locationResult,
      'mandapResult':
          widget.mandapResult,
      'idolResult':
          widget.idolResult,
      'routeResult':
          widget.routeResult,
      'securityResult':
          widget.securityResult,
      'organizerResult':
          widget.organizerResult,
      'interDepartmentalResult':
          widget.interDepartmentalResult,
      'permissionShoReviewResult':
          shoReviewResult,
      'verificationStatus':
          'COMPLETED',
    };

    try {
      await VerificationApiService
          .submitVerification(
        verificationPayload,
      );

      if (!mounted) {
        return;
      }

      setState(
        () => _saving = false,
      );

      Navigator.pop(
        context,
        shoReviewResult,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(
        () => _saving = false,
      );

      _showMessage(
        'Unable to submit verification. '
        'Please check the network and try again.',
      );
    }
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        top: 20,
        bottom: 10,
      ),
      child: Text(
        title,
        style:
            const TextStyle(
          fontSize: 16,
          fontWeight:
              FontWeight.bold,
          color:
              Color(
                0xFF17365D,
              ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final summary =
        _moduleSummary();

    final adverseFindings =
        _adverseFindings();

    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF4F6F9,
      ),
      appBar: AppBar(
        backgroundColor:
            const Color(
          0xFF17365D,
        ),
        foregroundColor:
            Colors.white,
        title:
            const Text(
          'Permission / SHO Review',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.all(
            16,
          ),
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      'SELECTED GPID',
                      style:
                          TextStyle(
                        fontSize:
                            11,
                        color:
                            Colors.grey,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      _selectedGpid,
                      style:
                          const TextStyle(
                        fontSize:
                            18,
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
                    Text(
                      'Applicant: '
                      '${_text(widget.ganeshRecord?['name'])}',
                    ),
                    Text(
                      'Association: '
                      '${_text(widget.ganeshRecord?['association'])}',
                    ),
                    Text(
                      'Police Station: '
                      '${_text(widget.ganeshRecord?['ps_name'])}',
                    ),
                  ],
                ),
              ),
            ),

            _sectionTitle(
              'A. Verification Summary',
            ),

            for (final item in summary)
              Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 8,
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    item['status'] ==
                            'Completed'
                        ? Icons
                            .check_circle
                        : Icons
                            .warning_amber_rounded,
                    color:
                        item['status'] ==
                                'Completed'
                            ? Colors.green
                            : Colors.orange,
                  ),
                  title: Text(
                    item['module']!,
                  ),
                  trailing: Text(
                    item['status']!,
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          item['status'] ==
                                  'Completed'
                              ? Colors
                                  .green
                              : Colors
                                  .orange,
                    ),
                  ),
                ),
              ),

            _sectionTitle(
              'B. Pending / Adverse Issues',
            ),

            if (adverseFindings.isEmpty)
              Container(
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.green.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.green.shade200,
                  ),
                ),
                child:
                    const Text(
                  'No pending / adverse issue was automatically '
                  'identified from the available verification '
                  'results.',
                ),
              )
            else
              for (int i = 0;
                  i <
                      adverseFindings
                          .length;
                  i++)
                Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child:
                      ListTile(
                    leading:
                        CircleAvatar(
                      radius:
                          15,
                      child:
                          Text(
                        '${i + 1}',
                      ),
                    ),
                    title:
                        Text(
                      adverseFindings[i],
                    ),
                  ),
                ),

            _sectionTitle(
              'C. SHO Field Review',
            ),

            const Text(
              'All required verifications completed?',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            _yesNoSelector(
              value:
                  _allVerificationsCompleted,
              onChanged:
                  (value) =>
                      setState(
                () =>
                    _allVerificationsCompleted =
                        value,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'All observations / deficiencies satisfactorily addressed?',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            _yesNoSelector(
              value:
                  _allIssuesAddressed,
              onChanged:
                  (value) =>
                      setState(
                () =>
                    _allIssuesAddressed =
                        value,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'Required departmental coordination / NOCs completed?',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            _yesNoSelector(
              value:
                  _coordinationCompleted,
              includeNotApplicable:
                  true,
              onChanged:
                  (value) =>
                      setState(
                () =>
                    _coordinationCompleted =
                        value,
              ),
            ),

            _sectionTitle(
              'D. Permission Decision',
            ),

            DropdownButtonFormField<
                String>(
              initialValue:
                  _permissionDecision,
              isExpanded: true,
              decoration:
                  _inputDecoration(
                'SHO Recommendation',
              ),
              items:
                  const [
                DropdownMenuItem(
                  value:
                      'Recommended for Permission',
                  child:
                      Text(
                    'Recommended for Permission',
                  ),
                ),
                DropdownMenuItem(
                  value:
                      'Recommended with Conditions',
                  child:
                      Text(
                    'Recommended with Conditions',
                  ),
                ),
                DropdownMenuItem(
                  value:
                      'Not Recommended',
                  child:
                      Text(
                    'Not Recommended',
                  ),
                ),
              ],
              onChanged:
                  (value) {
                setState(
                  () {
                    _permissionDecision =
                        value;

                    if (value !=
                        'Recommended with Conditions') {
                      _conditionsController
                          .clear();
                    }

                    if (value !=
                        'Not Recommended') {
                      _notRecommendedReasonController
                          .clear();
                    }
                  },
                );
              },
            ),

            if (_permissionDecision ==
                'Recommended with Conditions') ...[
              const SizedBox(
                height: 12,
              ),
              TextField(
                controller:
                    _conditionsController,
                maxLines: 4,
                decoration:
                    _inputDecoration(
                  'Mandatory Conditions / Instructions',
                ),
              ),
            ],

            if (_permissionDecision ==
                'Not Recommended') ...[
              const SizedBox(
                height: 12,
              ),
              TextField(
                controller:
                    _notRecommendedReasonController,
                maxLines: 4,
                decoration:
                    _inputDecoration(
                  'Mandatory Reason for Not Recommending',
                ),
              ),
            ],

            _sectionTitle(
              'E. SHO Remarks',
            ),

            TextField(
              controller:
                  _shoRemarksController,
              maxLines: 4,
              decoration:
                  _inputDecoration(
                'Final Remarks / Instructions',
              ),
            ),

            _sectionTitle(
              'F. SHO Confirmation',
            ),

            CheckboxListTile(
              contentPadding:
                  EdgeInsets.zero,
              controlAffinity:
                  ListTileControlAffinity
                      .leading,
              value:
                  _shoConfirmation,
              onChanged:
                  (value) =>
                      setState(
                () =>
                    _shoConfirmation =
                        value ?? false,
              ),
              title:
                  const Text(
                'I have reviewed the Pre-Installation Verification '
                'findings and the status of the required coordination '
                '/ clearances for the selected GPID. The recommendation '
                'recorded above is based on the verification information '
                'available at the time of review.',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton(
                    onPressed:
                        _saving
                            ? null
                            : () =>
                                Navigator.pop(
                                  context,
                                ),
                    child:
                        const Text(
                      'CANCEL',
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child:
                      FilledButton(
                    onPressed:
                        _saving
                            ? null
                            : _save,
                    child:
                        _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Text(
                                'CONFIRM & SUBMIT',
                                textAlign:
                                    TextAlign.center,
                              ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}