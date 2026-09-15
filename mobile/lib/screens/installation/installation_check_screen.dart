import 'package:flutter/material.dart';

import '../../services/installation_check_api_service.dart';

class InstallationCheckScreen extends StatefulWidget {
  final String applicationId;
  final Map<String, dynamic>? ganeshRecord;

  const InstallationCheckScreen({
    super.key,
    required this.applicationId,
    this.ganeshRecord,
  });

  @override
  State<InstallationCheckScreen> createState() =>
      _InstallationCheckScreenState();
}

class _InstallationCheckScreenState
    extends State<InstallationCheckScreen> {
  bool? _idolInstalled;
  bool? _volunteersAvailable;
  int? _numberOfVolunteers;
  bool? _lightingInsideAvailable;
  bool? _lightingAroundAvailable;
  bool? _sanitationInsideSatisfactory;
  bool? _sanitationOutsideSatisfactory;
  bool? _poojaCompleted;
  bool? _hundiSafe;
  bool? _ladduSafe;
  bool? _deepamSafe;

  bool? _antiIdolOk;
  bool? _antiMandapOk;
  bool? _antiLadduOk;
  bool? _antiHundiOk;
  bool? _antiJewelleryOk;
  bool? _antiInsideMandapOk;
  bool? _antiAroundMandapOk;

  bool _isSubmitting = false;

  bool get _isPoojaApplicable {
    final now = DateTime.now();
    return now.hour >= 21;
  }
  bool get _isLightingApplicable {
    final now = DateTime.now();
    final hour = now.hour;

    return hour >= 18 || hour < 7;
  }

  final List<String?> _selectedVolunteerNames =
      List<String?>.filled(8, null);

  final List<TextEditingController> _otherVolunteerNameControllers =
      List<TextEditingController>.generate(
    8,
    (_) => TextEditingController(),
  );

  List<String> get _availableVolunteerNames {
    final record = widget.ganeshRecord;

    if (record == null) {
      return <String>[];
    }

    final names = <String>[];

    void addName(dynamic value) {
      if (value == null) {
        return;
      }

      final name = value.toString().trim();

      if (name.isEmpty || name.toLowerCase() == 'null') {
        return;
      }

      final alreadyExists = names.any(
        (existing) => existing.toLowerCase() == name.toLowerCase(),
      );

      if (!alreadyExists) {
        names.add(name);
      }
    }

    addName(record['name']);

    for (int i = 1; i <= 8; i++) {
      addName(record['memb$i']);
    }

    return names;
  }

  final TextEditingController _idolNotInstalledRemarksController =
      TextEditingController();
  final TextEditingController _volunteersNotAvailableActionController =
      TextEditingController();
  final TextEditingController _lightingInsideRemarksController =
      TextEditingController();
  final TextEditingController _lightingAroundRemarksController =
      TextEditingController();
  final TextEditingController _sanitationInsideRemarksController =
      TextEditingController();
  final TextEditingController _sanitationOutsideRemarksController =
      TextEditingController();
  final TextEditingController _hundiRemarksController =
      TextEditingController();
  final TextEditingController _ladduRemarksController =
      TextEditingController();
  final TextEditingController _deepamRemarksController =
      TextEditingController();

  final TextEditingController _antiIdolRemarksController =
      TextEditingController();
  final TextEditingController _antiMandapRemarksController =
      TextEditingController();
  final TextEditingController _antiLadduRemarksController =
      TextEditingController();
  final TextEditingController _antiHundiRemarksController =
      TextEditingController();
  final TextEditingController _antiJewelleryRemarksController =
      TextEditingController();
  final TextEditingController _antiInsideMandapRemarksController =
      TextEditingController();
  final TextEditingController _antiAroundMandapRemarksController =
      TextEditingController();
  final TextEditingController _antiDesecrationGeneralRemarksController =
      TextEditingController();

  void _clearVolunteerSelections() {
    for (int i = 0; i < 8; i++) {
      _selectedVolunteerNames[i] = null;
      _otherVolunteerNameControllers[i].clear();
    }
  }

  void _adjustVolunteerSelections(int? count) {
    if (count == null) {
      _clearVolunteerSelections();
      return;
    }

    for (int i = count; i < 8; i++) {
      _selectedVolunteerNames[i] = null;
      _otherVolunteerNameControllers[i].clear();
    }
  }

  Widget _buildAntiDesecrationCheck({
    required String title,
    required bool? value,
    required ValueChanged<bool?> onChanged,
    required TextEditingController remarksController,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD8DEE8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: true,
                label: Text('Checked - No Issue'),
                icon: Icon(Icons.check_circle_outline),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text('Issue Found'),
                icon: Icon(Icons.warning_amber_outlined),
              ),
            ],
            selected: value == null ? <bool>{} : <bool>{value},
            emptySelectionAllowed: true,
            onSelectionChanged: (selection) {
              final selectedValue =
                  selection.isEmpty ? null : selection.first;

              onChanged(selectedValue);

              if (selectedValue == true) {
                remarksController.clear();
              }
            },
          ),
          if (value == false) ...[
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Action Taken / Remarks',
                hintText: 'Describe the issue found and action taken...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _idolNotInstalledRemarksController.dispose();
    _volunteersNotAvailableActionController.dispose();
    _lightingInsideRemarksController.dispose();
    _lightingAroundRemarksController.dispose();
    _sanitationInsideRemarksController.dispose();
    _sanitationOutsideRemarksController.dispose();
    _hundiRemarksController.dispose();
    _ladduRemarksController.dispose();
    _deepamRemarksController.dispose();
    _antiIdolRemarksController.dispose();
    _antiMandapRemarksController.dispose();
    _antiLadduRemarksController.dispose();
    _antiHundiRemarksController.dispose();
    _antiJewelleryRemarksController.dispose();
    _antiInsideMandapRemarksController.dispose();
    _antiAroundMandapRemarksController.dispose();
    _antiDesecrationGeneralRemarksController.dispose();

    for (final controller in _otherVolunteerNameControllers) {
      controller.dispose();
    }

    super.dispose();
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

  String? _validateInstallationCheck() {
    if (_idolInstalled == null) {
      return 'Please select whether the idol is installed.';
    }

    if (_idolInstalled == false) {
      if (_idolNotInstalledRemarksController.text.trim().isEmpty) {
        return 'Please enter Reason / Action Taken for idol not installed.';
      }
      return null;
    }

    if (_volunteersAvailable == null) {
      return 'Please complete Volunteer Availability.';
    }

    if (_volunteersAvailable == false &&
        _volunteersNotAvailableActionController.text.trim().isEmpty) {
      return 'Please enter Action Taken / Remarks for volunteers not available.';
    }

    if (_volunteersAvailable == true) {
      if (_numberOfVolunteers == null) {
        return 'Please select the number of volunteers available.';
      }

      for (int i = 0; i < _numberOfVolunteers!; i++) {
        final selected = _selectedVolunteerNames[i];

        if (selected == null || selected.trim().isEmpty) {
          return 'Please select Volunteer ${i + 1}.';
        }

        if (selected == 'Other' &&
            _otherVolunteerNameControllers[i].text.trim().isEmpty) {
          return 'Please enter the name of Volunteer ${i + 1}.';
        }
      }
    }

    if (_sanitationInsideSatisfactory == null ||
        _sanitationOutsideSatisfactory == null) {
      return 'Please complete both Sanitation checks.';
    }

    if (_sanitationInsideSatisfactory == false &&
        _sanitationInsideRemarksController.text.trim().isEmpty) {
      return 'Please enter Action Taken / Remarks for sanitation inside Mandap.';
    }

    if (_sanitationOutsideSatisfactory == false &&
        _sanitationOutsideRemarksController.text.trim().isEmpty) {
      return 'Please enter Action Taken / Remarks for sanitation outside/around Mandap.';
    }

    if (_isLightingApplicable) {
      if (_lightingInsideAvailable == null ||
          _lightingAroundAvailable == null) {
        return 'Please complete both Lighting checks.';
      }

      if (_lightingInsideAvailable == false &&
          _lightingInsideRemarksController.text.trim().isEmpty) {
        return 'Please enter Action Taken / Remarks for lighting inside Mandap.';
      }

      if (_lightingAroundAvailable == false &&
          _lightingAroundRemarksController.text.trim().isEmpty) {
        return 'Please enter Action Taken / Remarks for lighting around Mandap.';
      }
    }

    if (_isPoojaApplicable) {
      if (_poojaCompleted == null) {
        return 'Please select whether Pooja is completed.';
      }

      if (_poojaCompleted == true) {
        if (_hundiSafe == null || _ladduSafe == null || _deepamSafe == null) {
          return 'Please complete all Post-Pooja Safety checks.';
        }

        if (_hundiSafe == false &&
            _hundiRemarksController.text.trim().isEmpty) {
          return 'Please enter Action Taken / Remarks for Hundi safety.';
        }

        if (_ladduSafe == false &&
            _ladduRemarksController.text.trim().isEmpty) {
          return 'Please enter Action Taken / Remarks for Laddu safety.';
        }

        if (_deepamSafe == false &&
            _deepamRemarksController.text.trim().isEmpty) {
          return 'Please enter Action Taken / Remarks for Deepam safety.';
        }
      }
    }

    final antiChecks = <MapEntry<bool?, TextEditingController>>[
      MapEntry(_antiIdolOk, _antiIdolRemarksController),
      MapEntry(_antiMandapOk, _antiMandapRemarksController),
      MapEntry(_antiLadduOk, _antiLadduRemarksController),
      MapEntry(_antiHundiOk, _antiHundiRemarksController),
      MapEntry(_antiJewelleryOk, _antiJewelleryRemarksController),
      MapEntry(_antiInsideMandapOk, _antiInsideMandapRemarksController),
      MapEntry(_antiAroundMandapOk, _antiAroundMandapRemarksController),
    ];

    if (antiChecks.any((entry) => entry.key == null)) {
      return 'Please complete all Anti-Desecration Drill checks.';
    }

    if (antiChecks.any(
      (entry) => entry.key == false && entry.value.text.trim().isEmpty,
    )) {
      return 'Please enter Action Taken / Remarks for every Anti-Desecration issue found.';
    }

    return null;
  }

  List<Map<String, dynamic>> _buildVolunteersPresent() {
    if (_volunteersAvailable != true || _numberOfVolunteers == null) {
      return <Map<String, dynamic>>[];
    }

    return List<Map<String, dynamic>>.generate(
      _numberOfVolunteers!,
      (index) {
        final selected = _selectedVolunteerNames[index];
        final isOther = selected == 'Other';

        return <String, dynamic>{
          'sequence': index + 1,
          'source': isOther ? 'OTHER' : 'LISTED',
          'name': isOther
              ? _otherVolunteerNameControllers[index].text.trim()
              : selected,
        };
      },
    );
  }

  bool get _hasDeficiency {
    if (_idolInstalled == false ||
        _volunteersAvailable == false ||
        _sanitationInsideSatisfactory == false ||
        _sanitationOutsideSatisfactory == false ||
        (_isLightingApplicable &&
            (_lightingInsideAvailable == false ||
                _lightingAroundAvailable == false)) ||
        (_isPoojaApplicable && _poojaCompleted == false) ||
        (_isPoojaApplicable &&
            _poojaCompleted == true &&
            (_hundiSafe == false ||
                _ladduSafe == false ||
                _deepamSafe == false)) ||
        _antiIdolOk == false ||
        _antiMandapOk == false ||
        _antiLadduOk == false ||
        _antiHundiOk == false ||
        _antiJewelleryOk == false ||
        _antiInsideMandapOk == false ||
        _antiAroundMandapOk == false) {
      return true;
    }

    return false;
  }

  Future<void> _submitInstallationCheck() async {
    if (_isSubmitting) {
      return;
    }

    final validationMessage = _validateInstallationCheck();

    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final now = DateTime.now();

    final payload = <String, dynamic>{
      'gpid': widget.applicationId,
      'applicationId': widget.applicationId,
      'checkSource': 'MOBILE',
      'installationResult': <String, dynamic>{
        'idolInstalled': _idolInstalled,
        'reasonOrActionTaken': _idolInstalled == false
            ? _idolNotInstalledRemarksController.text.trim()
            : null,
      },
      'volunteerResult': _idolInstalled == true
          ? <String, dynamic>{
              'volunteersAvailable': _volunteersAvailable,
              'numberOfVolunteers':
                  _volunteersAvailable == true ? _numberOfVolunteers : 0,
              'volunteersPresent': _buildVolunteersPresent(),
              'actionTakenOrRemarks': _volunteersAvailable == false
                  ? _volunteersNotAvailableActionController.text.trim()
                  : null,
            }
          : null,
      'lightingResult': _idolInstalled == true
          ? <String, dynamic>{
              'applicable': _isLightingApplicable,
              'insideMandapAvailable':
                  _isLightingApplicable ? _lightingInsideAvailable : null,
              'insideActionTakenOrRemarks':
                  _isLightingApplicable && _lightingInsideAvailable == false
                      ? _lightingInsideRemarksController.text.trim()
                      : null,
              'aroundMandapAvailable':
                  _isLightingApplicable ? _lightingAroundAvailable : null,
              'aroundActionTakenOrRemarks':
                  _isLightingApplicable && _lightingAroundAvailable == false
                      ? _lightingAroundRemarksController.text.trim()
                      : null,
            }
          : null,
      'sanitationResult': _idolInstalled == true
          ? <String, dynamic>{
              'insideMandapSatisfactory':
                  _sanitationInsideSatisfactory,
              'insideActionTakenOrRemarks':
                  _sanitationInsideSatisfactory == false
                      ? _sanitationInsideRemarksController.text.trim()
                      : null,
              'outsideAroundMandapSatisfactory':
                  _sanitationOutsideSatisfactory,
              'outsideActionTakenOrRemarks':
                  _sanitationOutsideSatisfactory == false
                      ? _sanitationOutsideRemarksController.text.trim()
                      : null,
            }
          : null,
      'poojaResult': _idolInstalled == true
          ? <String, dynamic>{
              'applicable': _isPoojaApplicable,
              'poojaCompleted':
                  _isPoojaApplicable ? _poojaCompleted : null,
              'pending': _isPoojaApplicable && _poojaCompleted != true,
              'hundiSafe': _isPoojaApplicable && _poojaCompleted == true
                  ? _hundiSafe
                  : null,
              'hundiActionTakenOrRemarks':
                  _isPoojaApplicable &&
                          _poojaCompleted == true &&
                          _hundiSafe == false
                      ? _hundiRemarksController.text.trim()
                      : null,
              'ladduSafe': _isPoojaApplicable && _poojaCompleted == true
                  ? _ladduSafe
                  : null,
              'ladduActionTakenOrRemarks':
                  _isPoojaApplicable &&
                          _poojaCompleted == true &&
                          _ladduSafe == false
                      ? _ladduRemarksController.text.trim()
                      : null,
              'deepamSafe': _isPoojaApplicable && _poojaCompleted == true
                  ? _deepamSafe
                  : null,
              'deepamActionTakenOrRemarks':
                  _isPoojaApplicable &&
                          _poojaCompleted == true &&
                          _deepamSafe == false
                      ? _deepamRemarksController.text.trim()
                      : null,
            }
          : null,
      'antiDesecrationResult': _idolInstalled == true
          ? <String, dynamic>{
              'idol': <String, dynamic>{
                'checkedNoIssue': _antiIdolOk,
                'actionTakenOrRemarks': _antiIdolOk == false
                    ? _antiIdolRemarksController.text.trim()
                    : null,
              },
              'mandap': <String, dynamic>{
                'checkedNoIssue': _antiMandapOk,
                'actionTakenOrRemarks': _antiMandapOk == false
                    ? _antiMandapRemarksController.text.trim()
                    : null,
              },
              'laddu': <String, dynamic>{
                'checkedNoIssue': _antiLadduOk,
                'actionTakenOrRemarks': _antiLadduOk == false
                    ? _antiLadduRemarksController.text.trim()
                    : null,
              },
              'hundi': <String, dynamic>{
                'checkedNoIssue': _antiHundiOk,
                'actionTakenOrRemarks': _antiHundiOk == false
                    ? _antiHundiRemarksController.text.trim()
                    : null,
              },
              'jewelleryValuables': <String, dynamic>{
                'checkedNoIssue': _antiJewelleryOk,
                'actionTakenOrRemarks': _antiJewelleryOk == false
                    ? _antiJewelleryRemarksController.text.trim()
                    : null,
              },
              'insideMandap': <String, dynamic>{
                'checkedNoIssue': _antiInsideMandapOk,
                'actionTakenOrRemarks': _antiInsideMandapOk == false
                    ? _antiInsideMandapRemarksController.text.trim()
                    : null,
              },
              'aroundMandap': <String, dynamic>{
                'checkedNoIssue': _antiAroundMandapOk,
                'actionTakenOrRemarks': _antiAroundMandapOk == false
                    ? _antiAroundMandapRemarksController.text.trim()
                    : null,
              },
              'remarks':
                  _antiDesecrationGeneralRemarksController.text.trim(),
            }
          : null,
      'hasDeficiency': _hasDeficiency,
      'requiresFollowUp': _hasDeficiency,
      'poojaApplicable': _idolInstalled == true && _isPoojaApplicable,
      'poojaCompleted':
          _idolInstalled == true && _isPoojaApplicable
              ? _poojaCompleted
              : null,
      'poojaPending':
          _idolInstalled == true &&
          _isPoojaApplicable &&
          _poojaCompleted != true,
      'status': _hasDeficiency ? 'FOLLOW_UP_REQUIRED' : 'SAVED',
      'checkedAt': now.toIso8601String(),
      'submittedAt': now.toIso8601String(),
    };

    try {
      await InstallationCheckApiService.submitInstallationCheck(payload);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Installation check submitted successfully.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      _showMessage(
        'Unable to submit Installation Check: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final volunteerOptions = <String>[
      ..._availableVolunteerNames,
      'Other',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Installation Checking'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stage 2 - Installation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'GPID: ${widget.applicationId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Installation checking modules will be recorded as a new officer visit without overwriting previous checks.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Idol Installed?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('YES'),
                          icon: Icon(
                            Icons.check_circle_outline,
                          ),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('NO'),
                          icon: Icon(
                            Icons.cancel_outlined,
                          ),
                        ),
                      ],
                      selected: _idolInstalled == null
                          ? <bool>{}
                          : <bool>{_idolInstalled!},
                      emptySelectionAllowed: true,
                      onSelectionChanged: (selection) {
                        setState(() {
                          _idolInstalled = selection.isEmpty
                              ? null
                              : selection.first;

                          if (_idolInstalled == true) {
                            _idolNotInstalledRemarksController.clear();
                          } else {
                            _volunteersAvailable = null;
                            _numberOfVolunteers = null;
                            _clearVolunteerSelections();

                            _antiIdolOk = null;
                            _antiMandapOk = null;
                            _antiLadduOk = null;
                            _antiHundiOk = null;
                            _antiJewelleryOk = null;
                            _antiInsideMandapOk = null;
                            _antiAroundMandapOk = null;

                            _antiIdolRemarksController.clear();
                            _antiMandapRemarksController.clear();
                            _antiLadduRemarksController.clear();
                            _antiHundiRemarksController.clear();
                            _antiJewelleryRemarksController.clear();
                            _antiInsideMandapRemarksController.clear();
                            _antiAroundMandapRemarksController.clear();
                            _antiDesecrationGeneralRemarksController.clear();
                          }
                        });
                      },
                    ),

                    if (_idolInstalled == false) ...[
                      const SizedBox(height: 16),

                      const Text(
                        'Reason / Action Taken',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller:
                            _idolNotInstalledRemarksController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'Enter reason for non-installation and action taken...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_idolInstalled == true) ...[
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Volunteer Availability',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Volunteers Available?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('YES'),
                            icon: Icon(
                              Icons.check_circle_outline,
                            ),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('NO'),
                            icon: Icon(
                              Icons.cancel_outlined,
                            ),
                          ),
                        ],
                        selected: _volunteersAvailable == null
                            ? <bool>{}
                            : <bool>{_volunteersAvailable!},
                        emptySelectionAllowed: true,
                        onSelectionChanged: (selection) {
                          setState(() {
                            _volunteersAvailable = selection.isEmpty
                                ? null
                                : selection.first;

                            if (_volunteersAvailable != true) {
                              _numberOfVolunteers = null;
                              _clearVolunteerSelections();
                            }
                          });
                        },
                      ),
if (_volunteersAvailable == false) ...[
  const SizedBox(height: 16),
  const Text(
    'Action Taken / Remarks',
    style: TextStyle(
      fontWeight: FontWeight.w600,
    ),
  ),
  const SizedBox(height: 8),
  TextField(
    controller: _volunteersNotAvailableActionController,
    maxLines: 3,
    decoration: const InputDecoration(
      hintText:
          'Enter action taken due to non-availability of volunteers...',
      border: OutlineInputBorder(),
    ),
  ),
],
                      if (_volunteersAvailable == true) ...[
                        const SizedBox(height: 16),

                        const Text(
                          'Number of Volunteers Available',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        DropdownButtonFormField<int>(
                          initialValue: _numberOfVolunteers,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText:
                                'Select number of volunteers',
                          ),
                          items: List.generate(
                            8,
                            (index) {
                              final number = index + 1;

                              return DropdownMenuItem<int>(
                                value: number,
                                child: Text('$number'),
                              );
                            },
                          ),
                          onChanged: (value) {
                            setState(() {
                              _numberOfVolunteers = value;
                              _adjustVolunteerSelections(value);
                            });
                          },
                        ),

                        if (_numberOfVolunteers != null) ...[
                          const SizedBox(height: 18),

                          const Text(
                            'Volunteers Present',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          for (int i = 0;
                              i < _numberOfVolunteers!;
                              i++) ...[
                            Container(
                              margin:
                                  const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFD8DEE8),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Volunteer ${i + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  DropdownButtonFormField<String>(
                                    initialValue:
                                        _selectedVolunteerNames[i],
                                    isExpanded: true,
                                    decoration:
                                        const InputDecoration(
                                      border:
                                          OutlineInputBorder(),
                                      hintText:
                                          'Select volunteer',
                                    ),
                                    items: volunteerOptions
                                        .map(
                                          (name) =>
                                              DropdownMenuItem<String>(
                                            value: name,
                                            child: Text(name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedVolunteerNames[i] =
                                            value;

                                        if (value != 'Other') {
                                          _otherVolunteerNameControllers[
                                                  i]
                                              .clear();
                                        }
                                      });
                                    },
                                  ),

                                  if (_selectedVolunteerNames[i] ==
                                      'Other') ...[
                                    const SizedBox(height: 10),

                                    TextField(
                                      controller:
                                          _otherVolunteerNameControllers[
                                              i],
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration:
                                          const InputDecoration(
                                        border:
                                            OutlineInputBorder(),
                                        labelText:
                                            'Volunteer Name',
                                        hintText:
                                            'Enter volunteer name',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],


            if (_idolInstalled == true) ...[
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sanitation',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Inside Mandap',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Satisfactory'),
                            icon: Icon(Icons.check_circle_outline),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Unsatisfactory'),
                            icon: Icon(Icons.cancel_outlined),
                          ),
                        ],
                        selected: _sanitationInsideSatisfactory == null
                            ? <bool>{}
                            : <bool>{_sanitationInsideSatisfactory!},
                        emptySelectionAllowed: true,
                        onSelectionChanged: (selection) {
                          setState(() {
                            _sanitationInsideSatisfactory =
                                selection.isEmpty ? null : selection.first;

                            if (_sanitationInsideSatisfactory == true) {
                              _sanitationInsideRemarksController.clear();
                            }
                          });
                        },
                      ),

                      if (_sanitationInsideSatisfactory == false) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _sanitationInsideRemarksController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Action Taken / Remarks',
                            hintText:
                                'Enter sanitation issue inside Mandap and action taken...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),
                      const Text(
                        'Outside / Around Mandap',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Satisfactory'),
                            icon: Icon(Icons.check_circle_outline),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Unsatisfactory'),
                            icon: Icon(Icons.cancel_outlined),
                          ),
                        ],
                        selected: _sanitationOutsideSatisfactory == null
                            ? <bool>{}
                            : <bool>{_sanitationOutsideSatisfactory!},
                        emptySelectionAllowed: true,
                        onSelectionChanged: (selection) {
                          setState(() {
                            _sanitationOutsideSatisfactory =
                                selection.isEmpty ? null : selection.first;

                            if (_sanitationOutsideSatisfactory == true) {
                              _sanitationOutsideRemarksController.clear();
                            }
                          });
                        },
                      ),

                      if (_sanitationOutsideSatisfactory == false) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _sanitationOutsideRemarksController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Action Taken / Remarks',
                            hintText:
                                'Enter sanitation issue outside/around Mandap and action taken...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            if (_idolInstalled == true && _isLightingApplicable) ...[
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lighting',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Applicable during night checking hours: 6:00 PM to 7:00 AM',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Inside Mandap',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Available'),
                            icon: Icon(Icons.lightbulb_outline),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Not Available'),
                            icon: Icon(Icons.lightbulb_outline),
                          ),
                        ],
                        selected: _lightingInsideAvailable == null
                            ? <bool>{}
                            : <bool>{_lightingInsideAvailable!},
                        emptySelectionAllowed: true,
                        onSelectionChanged: (selection) {
                          setState(() {
                            _lightingInsideAvailable =
                                selection.isEmpty ? null : selection.first;

                            if (_lightingInsideAvailable == true) {
                              _lightingInsideRemarksController.clear();
                            }
                          });
                        },
                      ),

                      if (_lightingInsideAvailable == false) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _lightingInsideRemarksController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Action Taken / Remarks',
                            hintText:
                                'Enter action taken for non-availability of lighting inside Mandap...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),
                      const Text(
                        'Around the Mandap',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Available'),
                            icon: Icon(Icons.lightbulb_outline),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Not Available'),
                            icon: Icon(Icons.lightbulb_outline),
                          ),
                        ],
                        selected: _lightingAroundAvailable == null
                            ? <bool>{}
                            : <bool>{_lightingAroundAvailable!},
                        emptySelectionAllowed: true,
                        onSelectionChanged: (selection) {
                          setState(() {
                            _lightingAroundAvailable =
                                selection.isEmpty ? null : selection.first;

                            if (_lightingAroundAvailable == true) {
                              _lightingAroundRemarksController.clear();
                            }
                          });
                        },
                      ),

                      if (_lightingAroundAvailable == false) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _lightingAroundRemarksController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Action Taken / Remarks',
                            hintText:
                                'Enter action taken for non-availability of lighting around Mandap...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            if (_idolInstalled == true && _isPoojaApplicable) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pooja & Post-Pooja Safety',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Applicable after 9:00 PM. If Pooja is not completed, this remains pending for re-check.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pooja Completed?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('YES'),
                            icon: Icon(Icons.check_circle_outline),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('NO'),
                            icon: Icon(Icons.pending_actions_outlined),
                          ),
                        ],
                        selected: _poojaCompleted == null
                            ? <bool>{}
                            : <bool>{_poojaCompleted!},
                        emptySelectionAllowed: true,
                        onSelectionChanged: (selection) {
                          setState(() {
                            _poojaCompleted =
                                selection.isEmpty ? null : selection.first;

                            if (_poojaCompleted != true) {
                              _hundiSafe = null;
                              _ladduSafe = null;
                              _deepamSafe = null;
                              _hundiRemarksController.clear();
                              _ladduRemarksController.clear();
                              _deepamRemarksController.clear();
                            }
                          });
                        },
                      ),
                      if (_poojaCompleted == false) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFED7AA),
                            ),
                          ),
                          child: const Text(
                            'Pooja not completed. This item will remain pending and must be checked again.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (_poojaCompleted == true) ...[
                        const SizedBox(height: 18),
                        const Text(
                          '1. Hundi kept in safe custody?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('YES'),
                              icon: Icon(Icons.check_circle_outline),
                            ),
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('NO'),
                              icon: Icon(Icons.cancel_outlined),
                            ),
                          ],
                          selected: _hundiSafe == null
                              ? <bool>{}
                              : <bool>{_hundiSafe!},
                          emptySelectionAllowed: true,
                          onSelectionChanged: (selection) {
                            setState(() {
                              _hundiSafe =
                                  selection.isEmpty ? null : selection.first;
                              if (_hundiSafe == true) {
                                _hundiRemarksController.clear();
                              }
                            });
                          },
                        ),
                        if (_hundiSafe == false) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _hundiRemarksController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Action Taken / Remarks',
                              hintText:
                                  'Enter issue regarding Hundi safe custody and action taken...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        const Text(
                          '2. Laddu kept safely / safety ensured?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('YES'),
                              icon: Icon(Icons.check_circle_outline),
                            ),
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('NO'),
                              icon: Icon(Icons.cancel_outlined),
                            ),
                          ],
                          selected: _ladduSafe == null
                              ? <bool>{}
                              : <bool>{_ladduSafe!},
                          emptySelectionAllowed: true,
                          onSelectionChanged: (selection) {
                            setState(() {
                              _ladduSafe =
                                  selection.isEmpty ? null : selection.first;
                              if (_ladduSafe == true) {
                                _ladduRemarksController.clear();
                              }
                            });
                          },
                        ),
                        if (_ladduSafe == false) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _ladduRemarksController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Action Taken / Remarks',
                              hintText:
                                  'Enter Laddu safety issue and action taken...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        const Text(
                          '3. Deepam safety ensured?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('YES'),
                              icon: Icon(Icons.check_circle_outline),
                            ),
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('NO'),
                              icon: Icon(Icons.cancel_outlined),
                            ),
                          ],
                          selected: _deepamSafe == null
                              ? <bool>{}
                              : <bool>{_deepamSafe!},
                          emptySelectionAllowed: true,
                          onSelectionChanged: (selection) {
                            setState(() {
                              _deepamSafe =
                                  selection.isEmpty ? null : selection.first;
                              if (_deepamSafe == true) {
                                _deepamRemarksController.clear();
                              }
                            });
                          },
                        ),
                        if (_deepamSafe == false) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _deepamRemarksController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Action Taken / Remarks',
                              hintText:
                                  'Enter Deepam safety issue and action taken...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],

            if (_idolInstalled == true) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Anti-Desecration Drill',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Check each security point individually. If any issue is found, record the action taken.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildAntiDesecrationCheck(
                        title: '1. Check Idol',
                        value: _antiIdolOk,
                        onChanged: (value) {
                          setState(() {
                            _antiIdolOk = value;
                          });
                        },
                        remarksController: _antiIdolRemarksController,
                      ),

                      _buildAntiDesecrationCheck(
                        title: '2. Check Mandap',
                        value: _antiMandapOk,
                        onChanged: (value) {
                          setState(() {
                            _antiMandapOk = value;
                          });
                        },
                        remarksController: _antiMandapRemarksController,
                      ),

                      _buildAntiDesecrationCheck(
                        title: '3. Check Laddu',
                        value: _antiLadduOk,
                        onChanged: (value) {
                          setState(() {
                            _antiLadduOk = value;
                          });
                        },
                        remarksController: _antiLadduRemarksController,
                      ),

                      _buildAntiDesecrationCheck(
                        title: '4. Check Hundi',
                        value: _antiHundiOk,
                        onChanged: (value) {
                          setState(() {
                            _antiHundiOk = value;
                          });
                        },
                        remarksController: _antiHundiRemarksController,
                      ),

                      _buildAntiDesecrationCheck(
                        title: '5. Check Jewellery / Valuables',
                        value: _antiJewelleryOk,
                        onChanged: (value) {
                          setState(() {
                            _antiJewelleryOk = value;
                          });
                        },
                        remarksController: _antiJewelleryRemarksController,
                      ),

                      _buildAntiDesecrationCheck(
                        title: '6. Check Inside Mandap',
                        value: _antiInsideMandapOk,
                        onChanged: (value) {
                          setState(() {
                            _antiInsideMandapOk = value;
                          });
                        },
                        remarksController:
                            _antiInsideMandapRemarksController,
                      ),

                      _buildAntiDesecrationCheck(
                        title: '7. Check Around Mandap',
                        value: _antiAroundMandapOk,
                        onChanged: (value) {
                          setState(() {
                            _antiAroundMandapOk = value;
                          });
                        },
                        remarksController:
                            _antiAroundMandapRemarksController,
                      ),

                      const Text(
                        '8. Remarks',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller:
                            _antiDesecrationGeneralRemarksController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText:
                              'Enter overall Anti-Desecration Drill remarks...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _isSubmitting ? null : _submitInstallationCheck,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _isSubmitting
                      ? 'Submitting...'
                      : 'Submit Installation Check',
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}