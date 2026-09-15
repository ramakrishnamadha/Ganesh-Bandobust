import 'package:flutter/material.dart';

import '../../services/verification_api_service.dart';

class SecurityVerificationScreen extends StatefulWidget {
  final String applicationId;
  final String? gpid;

  const SecurityVerificationScreen({
    super.key,
    required this.applicationId,
    this.gpid,
  });

  @override
  State<SecurityVerificationScreen> createState() =>
      _SecurityVerificationScreenState();
}

class _CommonIssueData {
  bool? available;
  bool? adviseRequired;
  bool? organiserInformed;
  final TextEditingController remarksController = TextEditingController();

  void dispose() {
    remarksController.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'available': available,
      'adviseRequired': adviseRequired,
      'organiserInformed': organiserInformed,
      'remarks': remarksController.text.trim(),
    };
  }
}

class _SecurityVerificationScreenState extends State<SecurityVerificationScreen> {
  bool _saving = false;

  String get _selectedGpid {
    final value = (widget.gpid ?? widget.applicationId).trim();
    return value.isEmpty ? widget.applicationId : value;
  }

  bool? _securityVerified;
  final TextEditingController _point1RemarksController = TextEditingController();

  final Map<int, _CommonIssueData> _common = {
    2: _CommonIssueData(),
    4: _CommonIssueData(),
    6: _CommonIssueData(),
    7: _CommonIssueData(),
    8: _CommonIssueData(),
    9: _CommonIssueData(),
    10: _CommonIssueData(),
    11: _CommonIssueData(),
  };

  bool? _cctvAvailable;
  int? _cctvCount;
  bool? _cctvGeoTagged;
  bool? _cctvAdviseRequired;
  bool? _cctvOrganiserInformed;
  final TextEditingController _cctvRemarksController = TextEditingController();

  bool? _fireExtinguisher;
  bool? _fireWater;
  bool? _fireSand;
  bool? _fireAdviseRequired;
  bool? _fireOrganiserInformed;
  final TextEditingController _fireRemarksController = TextEditingController();

  bool? _shoEmergencyNumbersDisplayed;

  @override
  void dispose() {
    _point1RemarksController.dispose();
    _cctvRemarksController.dispose();
    _fireRemarksController.dispose();
    for (final item in _common.values) {
      item.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _yesNo({
    required bool? value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onChanged(true),
            icon: Icon(value == true
                ? Icons.radio_button_checked
                : Icons.radio_button_off),
            label: const Text('YES'),
            style: OutlinedButton.styleFrom(
              foregroundColor: value == true ? Colors.green.shade800 : null,
              side: BorderSide(
                color: value == true
                    ? Colors.green.shade700
                    : Theme.of(context).dividerColor,
                width: value == true ? 2 : 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onChanged(false),
            icon: Icon(value == false
                ? Icons.radio_button_checked
                : Icons.radio_button_off),
            label: const Text('NO'),
            style: OutlinedButton.styleFrom(
              foregroundColor: value == false ? Colors.red.shade800 : null,
              side: BorderSide(
                color: value == false
                    ? Colors.red.shade700
                    : Theme.of(context).dividerColor,
                width: value == false ? 2 : 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pointCard({
    required int number,
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$number. $title',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _mandatoryLabel(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 6),
        Text('*',
            style: TextStyle(
                color: Colors.red.shade700, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _remarksField(TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Remarks / Reason *',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCommonPoint({
    required int number,
    required String title,
    required String adviseQuestion,
  }) {
    final data = _common[number]!;

    return _pointCard(
      number: number,
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _mandatoryLabel('Select YES / NO'),
          const SizedBox(height: 8),
          _yesNo(
            value: data.available,
            onChanged: (value) {
              setState(() {
                data.available = value;
                if (value) {
                  data.adviseRequired = null;
                  data.organiserInformed = null;
                  data.remarksController.clear();
                }
              });
            },
          ),
          if (data.available == false) ...[
            const SizedBox(height: 16),
            _mandatoryLabel(adviseQuestion),
            const SizedBox(height: 8),
            _yesNo(
              value: data.adviseRequired,
              onChanged: (value) {
                setState(() {
                  data.adviseRequired = value;
                  if (!value) {
                    data.organiserInformed = null;
                    data.remarksController.clear();
                  }
                });
              },
            ),
            if (data.adviseRequired == true) ...[
              const SizedBox(height: 16),
              _mandatoryLabel('Organiser Informed?'),
              const SizedBox(height: 8),
              _yesNo(
                value: data.organiserInformed,
                onChanged: (value) {
                  setState(() {
                    data.organiserInformed = value;
                    if (value) data.remarksController.clear();
                  });
                },
              ),
              if (data.organiserInformed == false) ...[
                const SizedBox(height: 14),
                _remarksField(data.remarksController),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPoint1() {
    return _pointCard(
      number: 1,
      title: 'Security Arrangements Verified?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _mandatoryLabel('Select YES / NO'),
          const SizedBox(height: 8),
          _yesNo(
            value: _securityVerified,
            onChanged: (value) {
              setState(() {
                _securityVerified = value;
                if (value) _point1RemarksController.clear();
              });
            },
          ),
          if (_securityVerified == false) ...[
            const SizedBox(height: 14),
            _remarksField(_point1RemarksController),
          ],
        ],
      ),
    );
  }

  Widget _buildPoint3() {
    return _pointCard(
      number: 3,
      title: 'CCTV Surveillance Available at the Mandap?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _mandatoryLabel('Select YES / NO'),
          const SizedBox(height: 8),
          _yesNo(
            value: _cctvAvailable,
            onChanged: (value) {
              setState(() {
                _cctvAvailable = value;
                if (value) {
                  _cctvAdviseRequired = null;
                  _cctvOrganiserInformed = null;
                  _cctvRemarksController.clear();
                } else {
                  _cctvCount = null;
                  _cctvGeoTagged = null;
                }
              });
            },
          ),
          if (_cctvAvailable == true) ...[
            const SizedBox(height: 16),
            _mandatoryLabel('No. of CCTV Cameras covering the Mandap'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _cctvCount,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select number of CCTV Cameras',
              ),
              items: List.generate(
                9,
                (index) => DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text('${index + 1}'),
                ),
              ),
              onChanged: (value) => setState(() => _cctvCount = value),
            ),
            const SizedBox(height: 16),
            _mandatoryLabel('Are these CCTV Cameras Geo-Tagged in TG-Cop?'),
            const SizedBox(height: 8),
            _yesNo(
              value: _cctvGeoTagged,
              onChanged: (value) => setState(() => _cctvGeoTagged = value),
            ),
          ],
          if (_cctvAvailable == false) ...[
            const SizedBox(height: 16),
            _mandatoryLabel(
                'Required to advise the Organiser to arrange CCTV Surveillance?'),
            const SizedBox(height: 8),
            _yesNo(
              value: _cctvAdviseRequired,
              onChanged: (value) {
                setState(() {
                  _cctvAdviseRequired = value;
                  if (!value) {
                    _cctvOrganiserInformed = null;
                    _cctvRemarksController.clear();
                  }
                });
              },
            ),
            if (_cctvAdviseRequired == true) ...[
              const SizedBox(height: 16),
              _mandatoryLabel('Organiser Informed?'),
              const SizedBox(height: 8),
              _yesNo(
                value: _cctvOrganiserInformed,
                onChanged: (value) {
                  setState(() {
                    _cctvOrganiserInformed = value;
                    if (value) _cctvRemarksController.clear();
                  });
                },
              ),
              if (_cctvOrganiserInformed == false) ...[
                const SizedBox(height: 14),
                _remarksField(_cctvRemarksController),
              ],
            ],
          ],
        ],
      ),
    );
  }

  void _clearFireFollowUpIfNotRequired() {
    final allAnswered =
        _fireExtinguisher != null && _fireWater != null && _fireSand != null;
    final allYes =
        _fireExtinguisher == true && _fireWater == true && _fireSand == true;
    if (allAnswered && allYes) {
      _fireAdviseRequired = null;
      _fireOrganiserInformed = null;
      _fireRemarksController.clear();
    }
  }

  Widget _buildPoint5() {
    final hasAnyNo = _fireExtinguisher == false ||
        _fireWater == false ||
        _fireSand == false;

    return _pointCard(
      number: 5,
      title: 'Fire Safety Arrangements Available at the Mandap?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _mandatoryLabel('A. Fire Extinguisher Available?'),
          const SizedBox(height: 8),
          _yesNo(
            value: _fireExtinguisher,
            onChanged: (value) {
              setState(() {
                _fireExtinguisher = value;
                _clearFireFollowUpIfNotRequired();
              });
            },
          ),
          const SizedBox(height: 16),
          _mandatoryLabel('B. Water Arrangement for Fire Emergency Available?'),
          const SizedBox(height: 8),
          _yesNo(
            value: _fireWater,
            onChanged: (value) {
              setState(() {
                _fireWater = value;
                _clearFireFollowUpIfNotRequired();
              });
            },
          ),
          const SizedBox(height: 16),
          _mandatoryLabel('C. Sand Arrangement for Fire Emergency Available?'),
          const SizedBox(height: 8),
          _yesNo(
            value: _fireSand,
            onChanged: (value) {
              setState(() {
                _fireSand = value;
                _clearFireFollowUpIfNotRequired();
              });
            },
          ),
          if (hasAnyNo) ...[
            const SizedBox(height: 16),
            _mandatoryLabel(
                'Required to advise the Organiser to arrange the missing Fire Safety Measures?'),
            const SizedBox(height: 8),
            _yesNo(
              value: _fireAdviseRequired,
              onChanged: (value) {
                setState(() {
                  _fireAdviseRequired = value;
                  if (!value) {
                    _fireOrganiserInformed = null;
                    _fireRemarksController.clear();
                  }
                });
              },
            ),
            if (_fireAdviseRequired == true) ...[
              const SizedBox(height: 16),
              _mandatoryLabel('Organiser Informed?'),
              const SizedBox(height: 8),
              _yesNo(
                value: _fireOrganiserInformed,
                onChanged: (value) {
                  setState(() {
                    _fireOrganiserInformed = value;
                    if (value) _fireRemarksController.clear();
                  });
                },
              ),
              if (_fireOrganiserInformed == false) ...[
                const SizedBox(height: 14),
                _remarksField(_fireRemarksController),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPoint12() {
    return _pointCard(
      number: 12,
      title: 'Emergency Contact Numbers (Given by SHO) Displayed at the Mandap?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _mandatoryLabel('Select YES / NO'),
          const SizedBox(height: 8),
          _yesNo(
            value: _shoEmergencyNumbersDisplayed,
            onChanged: (value) =>
                setState(() => _shoEmergencyNumbersDisplayed = value),
          ),
        ],
      ),
    );
  }

  bool _validateCommonPoint(int number, String pointName) {
    final data = _common[number]!;
    if (data.available == null) {
      _showMessage('Please answer Point $number: $pointName');
      return false;
    }
    if (data.available == false) {
      if (data.adviseRequired == null) {
        _showMessage(
            'Please answer whether the Organiser is required to be advised in Point $number.');
        return false;
      }
      if (data.adviseRequired == true) {
        if (data.organiserInformed == null) {
          _showMessage('Please answer "Organiser Informed?" in Point $number.');
          return false;
        }
        if (data.organiserInformed == false &&
            data.remarksController.text.trim().isEmpty) {
          _showMessage('Remarks / Reason is mandatory in Point $number.');
          return false;
        }
      }
    }
    return true;
  }

  bool _validateForm() {
    if (_securityVerified == null) {
      _showMessage('Please answer Point 1: Security Arrangements Verified?');
      return false;
    }
    if (_securityVerified == false) {
      if (_point1RemarksController.text.trim().isEmpty) {
        _showMessage('Remarks / Reason is mandatory when Point 1 is NO.');
        return false;
      }
      return true;
    }

    if (!_validateCommonPoint(2,
        'Organiser / Volunteer Security Arrangements Available?')) return false;

    if (_cctvAvailable == null) {
      _showMessage('Please answer Point 3: CCTV Surveillance Available?');
      return false;
    }
    if (_cctvAvailable == true) {
      if (_cctvCount == null) {
        _showMessage('Please select the number of CCTV Cameras in Point 3.');
        return false;
      }
      if (_cctvGeoTagged == null) {
        _showMessage('Please answer whether CCTV Cameras are Geo-Tagged in TG-Cop.');
        return false;
      }
    } else {
      if (_cctvAdviseRequired == null) {
        _showMessage('Please answer whether the Organiser is required to arrange CCTV Surveillance.');
        return false;
      }
      if (_cctvAdviseRequired == true) {
        if (_cctvOrganiserInformed == null) {
          _showMessage('Please answer "Organiser Informed?" in Point 3.');
          return false;
        }
        if (_cctvOrganiserInformed == false &&
            _cctvRemarksController.text.trim().isEmpty) {
          _showMessage('Remarks / Reason is mandatory in Point 3.');
          return false;
        }
      }
    }

    if (!_validateCommonPoint(4,
        'Barricading / Access Control Arrangements Available?')) return false;

    if (_fireExtinguisher == null || _fireWater == null || _fireSand == null) {
      _showMessage('Please answer all three Fire Safety items in Point 5.');
      return false;
    }
    final fireHasNo =
        _fireExtinguisher == false || _fireWater == false || _fireSand == false;
    if (fireHasNo) {
      if (_fireAdviseRequired == null) {
        _showMessage('Please answer whether the Organiser is required to arrange the missing Fire Safety Measures.');
        return false;
      }
      if (_fireAdviseRequired == true) {
        if (_fireOrganiserInformed == null) {
          _showMessage('Please answer "Organiser Informed?" in Point 5.');
          return false;
        }
        if (_fireOrganiserInformed == false &&
            _fireRemarksController.text.trim().isEmpty) {
          _showMessage('Remarks / Reason is mandatory in Point 5.');
          return false;
        }
      }
    }

    if (!_validateCommonPoint(6, 'Electrical Safety Arrangements Proper?')) return false;
    if (!_validateCommonPoint(7, 'Emergency Vehicle Access Available up to the Mandap?')) return false;
    if (!_validateCommonPoint(8, 'Adequate Crowd Management Arrangements Available?')) return false;
    if (!_validateCommonPoint(9, 'Safe Entry and Exit Arrangements Available?')) return false;
    if (!_validateCommonPoint(10, 'Adequate Lighting Arrangements Available at and around the Mandap?')) return false;
    if (!_validateCommonPoint(11, 'Public Address / Announcement System Available?')) return false;

    if (_shoEmergencyNumbersDisplayed == null) {
      _showMessage('Please answer Point 12: Emergency Contact Numbers Displayed?');
      return false;
    }
    return true;
  }

  Map<String, dynamic> _buildResult() {
    return {
      'applicationId': widget.applicationId,
      'gpid': _selectedGpid,
      'securityVerified': _securityVerified,
      'securityVerificationRemarks': _point1RemarksController.text.trim(),
      'point2': _common[2]!.toMap(),
      'point3': {
        'cctvAvailable': _cctvAvailable,
        'cctvCameraCount': _cctvCount,
        'cctvGeoTaggedInTGCop': _cctvGeoTagged,
        'adviseRequired': _cctvAdviseRequired,
        'organiserInformed': _cctvOrganiserInformed,
        'remarks': _cctvRemarksController.text.trim(),
      },
      'point4': _common[4]!.toMap(),
      'point5': {
        'fireExtinguisherAvailable': _fireExtinguisher,
        'waterArrangementAvailable': _fireWater,
        'sandArrangementAvailable': _fireSand,
        'adviseRequired': _fireAdviseRequired,
        'organiserInformed': _fireOrganiserInformed,
        'remarks': _fireRemarksController.text.trim(),
      },
      'point6': _common[6]!.toMap(),
      'point7': _common[7]!.toMap(),
      'point8': _common[8]!.toMap(),
      'point9': _common[9]!.toMap(),
      'point10': _common[10]!.toMap(),
      'point11': _common[11]!.toMap(),
      'point12': {
        'shoEmergencyContactNumbersDisplayed': _shoEmergencyNumbersDisplayed,
      },
    };
  }

  Future<void> _save() async {
    if (!_validateForm()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Security Verification'),
          content: const Text(
            'I have personally verified the above details and confirm that the information entered is correct.',
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
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final result = _buildResult();

    setState(() {
      _saving = true;
    });

    try {
      await VerificationApiService.saveModuleResult(
        applicationId: widget.applicationId,
        gpid: _selectedGpid,
        moduleKey: 'securityResult',
        result: result,
      );

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Unable to save Security Verification to the server. '
        'Please check the network and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security-Based Verification')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _buildPoint1(),
            if (_securityVerified == true) ...[
              _buildCommonPoint(
                number: 2,
                title: 'Organiser / Volunteer Security Arrangements Available?',
                adviseQuestion: 'Required to advise the Organiser to arrange volunteers?',
              ),
              _buildPoint3(),
              _buildCommonPoint(
                number: 4,
                title: 'Barricading / Access Control Arrangements Available at the Mandap?',
                adviseQuestion: 'Required to advise the Organiser to arrange Barricading / Access Control?',
              ),
              _buildPoint5(),
              _buildCommonPoint(
                number: 6,
                title: 'Electrical Safety Arrangements Proper at the Mandap?',
                adviseQuestion: 'Required to advise the Organiser to rectify the Electrical Safety issue?',
              ),
              _buildCommonPoint(
                number: 7,
                title: 'Emergency Vehicle Access Available up to the Mandap?',
                adviseQuestion: 'Required to advise the Organiser to clear / provide Emergency Vehicle Access?',
              ),
              _buildCommonPoint(
                number: 8,
                title: 'Adequate Crowd Management Arrangements Available at the Mandap?',
                adviseQuestion: 'Required to advise the Organiser to make adequate Crowd Management Arrangements?',
              ),
              _buildCommonPoint(
                number: 9,
                title: 'Safe Entry and Exit Arrangements Available at the Mandap?',
                adviseQuestion: 'Required to advise the Organiser to make proper Entry / Exit Arrangements?',
              ),
              _buildCommonPoint(
                number: 10,
                title: 'Adequate Lighting Arrangements Available at and around the Mandap?',
                adviseQuestion: 'Required to advise the Organiser to provide adequate Lighting Arrangements?',
              ),
              _buildCommonPoint(
                number: 11,
                title: 'Public Address (PA) / Announcement System Available at the Mandap?',
                adviseQuestion: 'Required to advise the Organiser to arrange a PA / Announcement System?',
              ),
              _buildPoint12(),
            ],
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  _saving ? 'SAVING...' : 'SAVE SECURITY VERIFICATION',
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
