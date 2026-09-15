import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/festivity_check_api_service.dart';

class FestivityCheckScreen extends StatefulWidget {
  final String applicationId;

  const FestivityCheckScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<FestivityCheckScreen> createState() => _FestivityCheckScreenState();
}

class _FestivityCheckScreenState extends State<FestivityCheckScreen> {
  int _festivalDay = 1;
  TimeOfDay _checkingTime = TimeOfDay.now();

  bool _loadingContext = true;
  bool _submitting = false;
  String? _loadError;
  int _previousVisitCount = 0;

  bool? _antiDigressionConducted;
  final TextEditingController _antiDigressionRemarks =
      TextEditingController();

  bool? _volunteersAvailable;
  int _volunteerCount = 1;
  final List<TextEditingController> _volunteerNames =
      List.generate(8, (_) => TextEditingController());
  final TextEditingController _volunteerActionTaken =
      TextEditingController();

  bool? _lightingInside;
  bool? _lightingAround;

  bool? _sanitationInside;
  bool? _sanitationOutside;

  bool? _poojaCompleted;
  bool? _ladduSafe;
  bool? _hundiSafe;
  bool? _jewellerySafe;
  bool? _cashGarlandSafe;
  bool? _otherValuablesSafe;
  final TextEditingController _poojaRemarks = TextEditingController();

  bool? _soundAvailable;
  bool? _soundWithinLimits;
  bool? _soundOperatingAtCheckTime;
  final TextEditingController _soundActionTaken =
      TextEditingController();

  bool? _sandAvailable;
  bool? _waterAvailable;
  bool? _fireExtinguisherAvailable;
  final TextEditingController _fireSafetyRemarks =
      TextEditingController();

  final TextEditingController _generalRemarks = TextEditingController();
  final TextEditingController _generalActionTaken =
      TextEditingController();

  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _antiDigressionRemarks.dispose();
    for (final controller in _volunteerNames) {
      controller.dispose();
    }
    _volunteerActionTaken.dispose();
    _poojaRemarks.dispose();
    _soundActionTaken.dispose();
    _fireSafetyRemarks.dispose();
    _generalRemarks.dispose();
    _generalActionTaken.dispose();
    super.dispose();
  }

  DateTime get _festivalDate {
    return DateTime(2026, 9, 13 + _festivalDay);
  }

  DateTime get _selectedCheckedAt {
    final date = _festivalDate;
    return DateTime(
      date.year,
      date.month,
      date.day,
      _checkingTime.hour,
      _checkingTime.minute,
    );
  }

  bool get _lightingApplicable {
    final minutes = _checkingTime.hour * 60 + _checkingTime.minute;
    return minutes >= 19 * 60 || minutes <= 6 * 60;
  }

  bool get _poojaApplicable {
    final minutes = _checkingTime.hour * 60 + _checkingTime.minute;
    return minutes >= 20 * 60 && minutes <= 23 * 60 + 59;
  }

  bool get _lateNightSoundApplicable {
    final minutes = _checkingTime.hour * 60 + _checkingTime.minute;
    return minutes >= 22 * 60 + 1;
  }

  String get _festivalDateLabel {
    final date = _festivalDate;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}-${two(date.month)}-${date.year}';
  }

  Future<void> _loadContext() async {
    setState(() {
      _loadingContext = true;
      _loadError = null;
    });

    try {
      final result =
          await FestivityCheckApiService.fetchFestivityContext(
        gpid: widget.applicationId,
        festivalDay: _festivalDay,
      );

      final dynamic records = result['records'];

      if (!mounted) return;

      setState(() {
        _previousVisitCount = records is List ? records.length : 0;
        _loadingContext = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingContext = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _selectCheckingTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _checkingTime,
    );

    if (picked == null) return;

    setState(() {
      _checkingTime = picked;
    });
  }

  Future<Position?> _captureLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enable Location Services and try again.',
            ),
          ),
        );
        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is required for Festivity checking.',
            ),
          ),
        );
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      if (!mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to capture GPS: $e'),
        ),
      );

      return null;
    }
  }

  String? _validate() {
    if (_antiDigressionConducted == null) {
      return 'Select Anti-Digression Drill status.';
    }

    if (_antiDigressionConducted == false &&
        _antiDigressionRemarks.text.trim().isEmpty) {
      return 'Enter remarks for Anti-Digression Drill.';
    }

    if (_volunteersAvailable == null) {
      return 'Select Volunteers availability.';
    }

    if (_volunteersAvailable == true) {
      for (int i = 0; i < _volunteerCount; i++) {
        if (_volunteerNames[i].text.trim().isEmpty) {
          return 'Enter Volunteer ${i + 1} name.';
        }
      }
    } else if (_volunteerActionTaken.text.trim().isEmpty) {
      return 'Enter Action Taken when Volunteers are not available.';
    }

    if (_lightingApplicable) {
      if (_lightingInside == null || _lightingAround == null) {
        return 'Complete both Lighting checks.';
      }
    }

    if (_sanitationInside == null || _sanitationOutside == null) {
      return 'Complete both Sanitation checks.';
    }

    if (_poojaApplicable) {
      if (_poojaCompleted == null) {
        return 'Select whether Pooja is completed.';
      }

      if (_poojaCompleted == true) {
        if (_ladduSafe == null ||
            _hundiSafe == null ||
            _jewellerySafe == null ||
            _cashGarlandSafe == null ||
            _otherValuablesSafe == null) {
          return 'Complete all safe-custody checks after Pooja.';
        }
      }
    }

    if (_soundAvailable == null) {
      return 'Select Sound System availability.';
    }

    if (_soundAvailable == true) {
      if (_soundWithinLimits == null) {
        return 'Select whether Sound System is within permissible limits.';
      }

      if (_lateNightSoundApplicable &&
          _soundOperatingAtCheckTime == null) {
        return 'Select whether Sound System is operating after 10:01 PM.';
      }

      if ((_soundWithinLimits == false ||
              (_lateNightSoundApplicable &&
                  _soundOperatingAtCheckTime == true)) &&
          _soundActionTaken.text.trim().isEmpty) {
        return 'Enter action taken for Sound System issue.';
      }
    }

    if (_sandAvailable == null ||
        _waterAvailable == null ||
        _fireExtinguisherAvailable == null) {
      return 'Complete all Fire Safety checks.';
    }

    if (!_confirmed) {
      return 'Officer confirmation is required before submission.';
    }

    return null;
  }

  Future<void> _submit() async {
    final validationError = _validate();

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final position = await _captureLocation();

      if (position == null) {
        if (mounted) {
          setState(() {
            _submitting = false;
          });
        }
        return;
      }

      final now = DateTime.now();

      final volunteerNames = <String>[
        for (int i = 0; i < _volunteerCount; i++)
          _volunteerNames[i].text.trim(),
      ];

      final payload = <String, dynamic>{
        'gpid': widget.applicationId,
        'applicationId': widget.applicationId,
        'festivalDay': _festivalDay,
        'checkSource': 'MOBILE',
        'antiDigressionResult': <String, dynamic>{
          'conducted': _antiDigressionConducted,
          'remarks': _antiDigressionRemarks.text.trim(),
        },
        'volunteerResult': <String, dynamic>{
          'available': _volunteersAvailable,
          'count': _volunteersAvailable == true
              ? _volunteerCount
              : 0,
          'names': _volunteersAvailable == true
              ? volunteerNames
              : <String>[],
          'actionTaken': _volunteersAvailable == false
              ? _volunteerActionTaken.text.trim()
              : '',
        },
        'lightingResult': <String, dynamic>{
          'applicable': _lightingApplicable,
          'insideMandap':
              _lightingApplicable ? _lightingInside : null,
          'aroundMandap':
              _lightingApplicable ? _lightingAround : null,
        },
        'sanitationResult': <String, dynamic>{
          'insideMandap': _sanitationInside,
          'outsideMandap': _sanitationOutside,
        },
        'poojaResult': <String, dynamic>{
          'applicable': _poojaApplicable,
          'poojaCompleted':
              _poojaApplicable ? _poojaCompleted : null,
          'ladduSafe': _poojaApplicable && _poojaCompleted == true
              ? _ladduSafe
              : null,
          'hundiSafe': _poojaApplicable && _poojaCompleted == true
              ? _hundiSafe
              : null,
          'jewellerySafe':
              _poojaApplicable && _poojaCompleted == true
                  ? _jewellerySafe
                  : null,
          'cashGarlandSafe':
              _poojaApplicable && _poojaCompleted == true
                  ? _cashGarlandSafe
                  : null,
          'otherValuablesSafe':
              _poojaApplicable && _poojaCompleted == true
                  ? _otherValuablesSafe
                  : null,
          'remarks': _poojaRemarks.text.trim(),
        },
        'soundSystemResult': <String, dynamic>{
          'available': _soundAvailable,
          'withinPermissibleLimits':
              _soundAvailable == true ? _soundWithinLimits : null,
          'operatingAtCheckTime':
              _soundAvailable == true && _lateNightSoundApplicable
                  ? _soundOperatingAtCheckTime
                  : null,
          'actionTaken': _soundActionTaken.text.trim(),
        },
        'fireSafetyResult': <String, dynamic>{
          'sandAvailable': _sandAvailable,
          'waterAvailable': _waterAvailable,
          'fireExtinguisherAvailable': _fireExtinguisherAvailable,
          'remarks': _fireSafetyRemarks.text.trim(),
        },
        'remarks': _generalRemarks.text.trim(),
        'actionTaken': _generalActionTaken.text.trim(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'checkStartedAt': now.toIso8601String(),
        'checkedAt': _selectedCheckedAt.toIso8601String(),
      };

      await FestivityCheckApiService.submitFestivityCheck(payload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Festivity checking submitted successfully.',
          ),
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Widget _sectionTitle(String number, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(
        '$number. $title',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF17365D),
        ),
      ),
    );
  }

  Widget _yesNo({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('YES'),
                    value: true,
                    groupValue: value,
                    onChanged: onChanged,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('NO'),
                    value: false,
                    groupValue: value,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _goodBad({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('GOOD'),
                    value: true,
                    groupValue: value,
                    onChanged: onChanged,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('BAD'),
                    value: false,
                    groupValue: value,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _availableNotAvailable({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('AVAILABLE'),
                    value: true,
                    groupValue: value,
                    onChanged: onChanged,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('NOT AVAILABLE'),
                    value: false,
                    groupValue: value,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _textBox({
    required TextEditingController controller,
    required String label,
    int maxLines = 2,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stage 3 - Festivity Checking'),
      ),
      body: _loadingContext
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadContext,
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
                            'GPID',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            widget.applicationId,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _festivalDay,
                            decoration: const InputDecoration(
                              labelText: 'Festival Day',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(
                              11,
                              (index) => DropdownMenuItem<int>(
                                value: index + 1,
                                child: Text('Day ${index + 1}'),
                              ),
                            ),
                            onChanged: (value) async {
                              if (value == null) return;

                              setState(() {
                                _festivalDay = value;
                              });

                              await _loadContext();
                            },
                          ),
                          const SizedBox(height: 12),
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Festival Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _festivalDateLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Checking Time'),
                            subtitle: Text(
                              _checkingTime.format(context),
                            ),
                            trailing: const Icon(Icons.schedule),
                            onTap: _selectCheckingTime,
                          ),
                          Text(
                            'Previous checks for this GPID / day: $_previousVisitCount',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (_loadError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _loadError!,
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  _sectionTitle('1', 'Anti-Digression Drill'),
                  _yesNo(
                    label: 'Anti-Digression Drill conducted?',
                    value: _antiDigressionConducted,
                    onChanged: (value) {
                      setState(() {
                        _antiDigressionConducted = value;
                      });
                    },
                  ),
                  if (_antiDigressionConducted == false)
                    _textBox(
                      controller: _antiDigressionRemarks,
                      label: 'Remarks / Action Taken',
                    ),

                  _sectionTitle('2', 'Volunteers'),
                  _yesNo(
                    label: 'Volunteers available?',
                    value: _volunteersAvailable,
                    onChanged: (value) {
                      setState(() {
                        _volunteersAvailable = value;
                      });
                    },
                  ),
                  if (_volunteersAvailable == true) ...[
                    DropdownButtonFormField<int>(
                      value: _volunteerCount,
                      decoration: const InputDecoration(
                        labelText: 'Number of Volunteers',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        8,
                        (index) => DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text('${index + 1}'),
                        ),
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _volunteerCount = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < _volunteerCount; i++)
                      _textBox(
                        controller: _volunteerNames[i],
                        label: 'Volunteer ${i + 1} Name',
                        maxLines: 1,
                      ),
                  ],
                  if (_volunteersAvailable == false)
                    _textBox(
                      controller: _volunteerActionTaken,
                      label: 'Action Taken',
                    ),

                  _sectionTitle('3', 'Lighting'),
                  if (_lightingApplicable) ...[
                    _yesNo(
                      label: 'Lighting available inside Mandap?',
                      value: _lightingInside,
                      onChanged: (value) {
                        setState(() {
                          _lightingInside = value;
                        });
                      },
                    ),
                    _yesNo(
                      label: 'Lighting available around Mandap?',
                      value: _lightingAround,
                      onChanged: (value) {
                        setState(() {
                          _lightingAround = value;
                        });
                      },
                    ),
                  ] else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'Lighting check is applicable only between 7:00 PM and 6:00 AM.',
                        ),
                      ),
                    ),

                  _sectionTitle('4', 'Sanitation'),
                  _goodBad(
                    label: 'Sanitation inside Mandap',
                    value: _sanitationInside,
                    onChanged: (value) {
                      setState(() {
                        _sanitationInside = value;
                      });
                    },
                  ),
                  _goodBad(
                    label: 'Sanitation outside Mandap',
                    value: _sanitationOutside,
                    onChanged: (value) {
                      setState(() {
                        _sanitationOutside = value;
                      });
                    },
                  ),

                  _sectionTitle('5', 'Pooja & Safe Custody'),
                  if (_poojaApplicable) ...[
                    _yesNo(
                      label: 'Pooja completed?',
                      value: _poojaCompleted,
                      onChanged: (value) {
                        setState(() {
                          _poojaCompleted = value;
                        });
                      },
                    ),
                    if (_poojaCompleted == true) ...[
                      _yesNo(
                        label: 'Laddu kept in safe custody?',
                        value: _ladduSafe,
                        onChanged: (value) {
                          setState(() {
                            _ladduSafe = value;
                          });
                        },
                      ),
                      _yesNo(
                        label: 'Hundi kept in safe custody?',
                        value: _hundiSafe,
                        onChanged: (value) {
                          setState(() {
                            _hundiSafe = value;
                          });
                        },
                      ),
                      _yesNo(
                        label: 'Jewellery kept in safe custody?',
                        value: _jewellerySafe,
                        onChanged: (value) {
                          setState(() {
                            _jewellerySafe = value;
                          });
                        },
                      ),
                      _yesNo(
                        label: 'Cash Garland kept in safe custody?',
                        value: _cashGarlandSafe,
                        onChanged: (value) {
                          setState(() {
                            _cashGarlandSafe = value;
                          });
                        },
                      ),
                      _yesNo(
                        label: 'Other valuables kept in safe custody?',
                        value: _otherValuablesSafe,
                        onChanged: (value) {
                          setState(() {
                            _otherValuablesSafe = value;
                          });
                        },
                      ),
                    ],
                    if (_poojaCompleted == true)
                      _textBox(
                        controller: _poojaRemarks,
                        label: 'Pooja / Safe Custody Remarks',
                      ),
                  ] else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'Pooja completion check is applicable only between 8:00 PM and 12:00 AM.',
                        ),
                      ),
                    ),

                  _sectionTitle('6', 'Sound System'),
                  _yesNo(
                    label: 'Sound System available?',
                    value: _soundAvailable,
                    onChanged: (value) {
                      setState(() {
                        _soundAvailable = value;
                      });
                    },
                  ),
                  if (_soundAvailable == true) ...[
                    _yesNo(
                      label:
                          'Sound production is within permissible limits?',
                      value: _soundWithinLimits,
                      onChanged: (value) {
                        setState(() {
                          _soundWithinLimits = value;
                        });
                      },
                    ),
                    if (_lateNightSoundApplicable)
                      _yesNo(
                        label:
                            'Sound System operating at checking time after 10:01 PM?',
                        value: _soundOperatingAtCheckTime,
                        onChanged: (value) {
                          setState(() {
                            _soundOperatingAtCheckTime = value;
                          });
                        },
                      ),
                    if (_soundWithinLimits == false ||
                        (_lateNightSoundApplicable &&
                            _soundOperatingAtCheckTime == true))
                      _textBox(
                        controller: _soundActionTaken,
                        label: 'Action Required / Action Taken',
                      ),
                  ],

                  _sectionTitle('7', 'Fire Safety'),
                  _availableNotAvailable(
                    label: 'Fire Extinguisher',
                    value: _fireExtinguisherAvailable,
                    onChanged: (value) {
                      setState(() {
                        _fireExtinguisherAvailable = value;
                      });
                    },
                  ),
                  _availableNotAvailable(
                    label: 'Sufficient Sand',
                    value: _sandAvailable,
                    onChanged: (value) {
                      setState(() {
                        _sandAvailable = value;
                      });
                    },
                  ),
                  _availableNotAvailable(
                    label: 'Sufficient Water',
                    value: _waterAvailable,
                    onChanged: (value) {
                      setState(() {
                        _waterAvailable = value;
                      });
                    },
                  ),
                  _textBox(
                    controller: _fireSafetyRemarks,
                    label: 'Fire Safety Remarks',
                  ),

                  _sectionTitle('8', 'General Remarks / Action'),
                  _textBox(
                    controller: _generalRemarks,
                    label: 'General Remarks',
                    maxLines: 3,
                  ),
                  _textBox(
                    controller: _generalActionTaken,
                    label: 'General Action Taken',
                    maxLines: 3,
                  ),

                  Card(
                    child: CheckboxListTile(
                      value: _confirmed,
                      onChanged: (value) {
                        setState(() {
                          _confirmed = value ?? false;
                        });
                      },
                      title: const Text(
                        'I have physically verified the above Festivity details and confirm that the information recorded above is correct.',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _submitting
                          ? 'SUBMITTING...'
                          : 'SUBMIT FESTIVITY CHECK',
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
