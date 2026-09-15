import 'package:flutter/material.dart';

import '../../services/verification_api_service.dart';

class OrganizerVerificationScreen extends StatefulWidget {
  final String applicationId;
  final String? gpid;
  final Map<String, dynamic>? ganeshRecord;

  const OrganizerVerificationScreen({
    super.key,
    required this.applicationId,
    this.gpid,
    this.ganeshRecord,
  });

  @override
  State<OrganizerVerificationScreen> createState() =>
      _OrganizerVerificationScreenState();
}

class OrganizerPerson {
  OrganizerPerson({
    required this.name,
    required this.mobile,
    this.isApplicant = false,
    this.manuallyAdded = false,
  });

  String name;
  String mobile;

  bool isApplicant;
  bool manuallyAdded;

  String? role;
  String otherRole = '';

  String? memberOfOtherAssociation;
  String otherAssociationGpid = '';

  String? contactVerified;
  String contactRemarks = '';

  String? adverseInformation;
  final List<AdverseCaseData> adverseCases = [];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mobile': mobile,
      'isApplicant': isApplicant,
      'manuallyAdded': manuallyAdded,
      'role': role,
      'otherRole': otherRole,
      'memberOfOtherAssociation':
          memberOfOtherAssociation,
      'otherAssociationGpid':
          otherAssociationGpid,
      'contactVerified': contactVerified,
      'contactRemarks': contactRemarks,
      'adverseInformation': adverseInformation,
      'adverseCases':
          adverseCases.map((e) => e.toMap()).toList(),
    };
  }
}

class AdverseCaseData {
  String nature = '';
  String policeStation = '';
  String crimeReference = '';
  String remarks = '';

  Map<String, dynamic> toMap() {
    return {
      'nature': nature,
      'policeStation': policeStation,
      'crimeReference': crimeReference,
      'remarks': remarks,
    };
  }
}

class _OrganizerVerificationScreenState
    extends State<OrganizerVerificationScreen> {
  String? _allOrganizersVerified;

  final TextEditingController
      _notVerifiedRemarksController =
      TextEditingController();

  final TextEditingController
      _mainOrganizerNameController =
      TextEditingController();

  final TextEditingController
      _mainOrganizerMobileController =
      TextEditingController();

  final List<OrganizerPerson> _organizers = [];

  String? _mainOrganizerListed;

  String? _newMainOtherAssociation;
  final TextEditingController
      _newMainOtherGpidController =
      TextEditingController();

  bool _fieldOfficerDeclaration = false;
  bool _saving = false;

  static const List<String> _roles = [
    'Main Organiser',
    'President',
    'Vice President',
    'General Secretary',
    'Secretary',
    'Joint Secretary',
    'Treasurer',
    'Executive Member',
    'Volunteer',
    'Other',
  ];

  String get _selectedGpid {
    final value = (widget.gpid ?? widget.applicationId)
        .trim();

    return value.isEmpty
        ? widget.applicationId
        : value;
  }

  @override
  void initState() {
    super.initState();
    _loadOrganizersFromApiRecord();
  }

  @override
  void dispose() {
    _notVerifiedRemarksController.dispose();
    _mainOrganizerNameController.dispose();
    _mainOrganizerMobileController.dispose();
    _newMainOtherGpidController.dispose();
    super.dispose();
  }

  String _clean(dynamic value) {
    if (value == null) {
      return '';
    }

    final text = value.toString().trim();

    if (text.toLowerCase() == 'null') {
      return '';
    }

    return text;
  }

  void _loadOrganizersFromApiRecord() {
    final record = widget.ganeshRecord;

    if (record == null) {
      return;
    }

    final List<OrganizerPerson> persons = [];

    // Applicant
    final applicantName = _clean(record['name']);
    final applicantMobile =
        _clean(record['mobile_no']);

    if (applicantName.isNotEmpty ||
        applicantMobile.isNotEmpty) {
      persons.add(
        OrganizerPerson(
          name: applicantName,
          mobile: applicantMobile,
          isApplicant: true,
        ),
      );
    }

    // Current API contains memb1-memb5.
    // The loop supports up to memb8 automatically
    // if the API is expanded later.
    for (int i = 1; i <= 8; i++) {
      final name = _clean(record['memb$i']);
      final mobile =
          _clean(record['mob_memb$i']);

      if (name.isEmpty && mobile.isEmpty) {
        continue;
      }

      final bool duplicate = persons.any(
        (person) =>
            person.name.toLowerCase() ==
                name.toLowerCase() &&
            person.mobile == mobile,
      );

      if (!duplicate) {
        persons.add(
          OrganizerPerson(
            name: name,
            mobile: mobile,
          ),
        );
      }
    }

    _organizers
      ..clear()
      ..addAll(persons.take(8));
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

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFD8DEE8),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF17365D),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _pointHeader(
    int number,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF17365D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17365D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _yesNoSelector({
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const SizedBox(
              width: double.infinity,
              child: Text(
                'YES',
                textAlign: TextAlign.center,
              ),
            ),
            selected: value == 'YES',
            onSelected: (_) => onChanged('YES'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const SizedBox(
              width: double.infinity,
              child: Text(
                'NO',
                textAlign: TextAlign.center,
              ),
            ),
            selected: value == 'NO',
            onSelected: (_) => onChanged('NO'),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerCard(
    OrganizerPerson organizer,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD8DEE8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    const Color(0xFFE8EEF7),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF17365D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  organizer.isApplicant
                      ? 'Applicant / Organizer'
                      : 'Organizer / Member ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17365D),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _displayField(
            'Name',
            organizer.name,
          ),

          const SizedBox(height: 8),

          _displayField(
            'Cell No.',
            organizer.mobile,
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            initialValue: organizer.role,
            isExpanded: true,
            decoration: _inputDecoration(
              'Role in this Association',
            ),
            items: _roles
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                organizer.role = value;

                if (value != 'Other') {
                  organizer.otherRole = '';
                }
              });
            },
          ),

          if (organizer.role == 'Other') ...[
            const SizedBox(height: 10),
            TextFormField(
              initialValue: organizer.otherRole,
              decoration: _inputDecoration(
                'Specify Role',
              ),
              onChanged: (value) {
                organizer.otherRole = value;
              },
            ),
          ],

          const SizedBox(height: 14),

          const Text(
            'Is this person a member of any other Association?',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          _yesNoSelector(
            value:
                organizer.memberOfOtherAssociation,
            onChanged: (value) {
              setState(() {
                organizer.memberOfOtherAssociation =
                    value;

                if (value == 'NO') {
                  organizer.otherAssociationGpid = '';
                }
              });
            },
          ),

          if (organizer.memberOfOtherAssociation ==
              'YES') ...[
            const SizedBox(height: 10),
            TextFormField(
              initialValue:
                  organizer.otherAssociationGpid,
              textCapitalization:
                  TextCapitalization.characters,
              decoration: _inputDecoration(
                'Other Association GPID',
                hint: 'Enter GPID',
              ),
              onChanged: (value) {
                organizer.otherAssociationGpid =
                    value.trim();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _displayField(
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  OrganizerPerson? _manualMainOrganizer() {
    for (final organizer in _organizers) {
      if (organizer.manuallyAdded) {
        return organizer;
      }
    }

    return null;
  }

  void _createOrUpdateManualMainOrganizer() {
    final name =
        _mainOrganizerNameController.text.trim();

    final mobile =
        _mainOrganizerMobileController.text.trim();

    OrganizerPerson? main =
        _manualMainOrganizer();

    if (main == null) {
      main = OrganizerPerson(
        name: name,
        mobile: mobile,
        manuallyAdded: true,
      );

      main.role = 'Main Organiser';

      _organizers.add(main);
    } else {
      main.name = name;
      main.mobile = mobile;
      main.role = 'Main Organiser';
    }

    main.memberOfOtherAssociation =
        _newMainOtherAssociation;

    main.otherAssociationGpid =
        _newMainOtherGpidController.text.trim();
  }

  void _syncManualMainOrganizer() {
    if (_mainOrganizerListed != 'NO') {
      return;
    }

    final name =
        _mainOrganizerNameController.text.trim();

    final mobile =
        _mainOrganizerMobileController.text.trim();

    if (name.isEmpty && mobile.isEmpty) {
      _organizers.removeWhere(
        (organizer) => organizer.manuallyAdded,
      );
      return;
    }

    _createOrUpdateManualMainOrganizer();
  }

  void _removeManualMainOrganizer() {
    _organizers.removeWhere(
      (organizer) => organizer.manuallyAdded,
    );
  }

  Widget _buildContactCard(
    OrganizerPerson organizer,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD8DEE8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${index + 1}. ${organizer.name}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF17365D),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Cell No.: ${organizer.mobile}',
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Was the Organizer contacted and identity confirmed '
            'through the given Cell No.?',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _yesNoSelector(
            value: organizer.contactVerified,
            onChanged: (value) {
              setState(() {
                organizer.contactVerified = value;

                if (value == 'YES') {
                  organizer.contactRemarks = '';
                }
              });
            },
          ),
          if (organizer.contactVerified == 'NO') ...[
            const SizedBox(height: 10),
            TextFormField(
              initialValue:
                  organizer.contactRemarks,
              maxLines: 3,
              decoration: _inputDecoration(
                'Mandatory Remarks / Reason',
              ),
              onChanged: (value) {
                organizer.contactRemarks = value;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidentialCard(
    OrganizerPerson organizer,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE4B84D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${index + 1}. ${organizer.name}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF17365D),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            'Cell No.: ${organizer.mobile}',
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Any Adverse Information / Previous Cases?',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          _yesNoSelector(
            value: organizer.adverseInformation,
            onChanged: (value) {
              setState(() {
                organizer.adverseInformation =
                    value;

                if (value == 'YES' &&
                    organizer.adverseCases.isEmpty) {
                  organizer.adverseCases.add(
                    AdverseCaseData(),
                  );
                }

                if (value == 'NO') {
                  organizer.adverseCases.clear();
                }
              });
            },
          ),

          if (organizer.adverseInformation ==
              'YES') ...[
            for (int caseIndex = 0;
                caseIndex <
                    organizer.adverseCases.length;
                caseIndex++)
              _buildAdverseCase(
                organizer,
                caseIndex,
              ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  organizer.adverseCases.add(
                    AdverseCaseData(),
                  );
                });
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'ADD ANOTHER CASE',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdverseCase(
    OrganizerPerson organizer,
    int caseIndex,
  ) {
    final adverseCase =
        organizer.adverseCases[caseIndex];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Case / Adverse Record ${caseIndex + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (organizer.adverseCases.length > 1)
                IconButton(
                  onPressed: () {
                    setState(() {
                      organizer.adverseCases
                          .removeAt(caseIndex);
                    });
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
            ],
          ),

          TextFormField(
            initialValue: adverseCase.nature,
            decoration: _inputDecoration(
              'Nature of Adverse Information / Case',
            ),
            onChanged: (value) {
              adverseCase.nature = value;
            },
          ),

          const SizedBox(height: 10),

          TextFormField(
            initialValue:
                adverseCase.policeStation,
            decoration: _inputDecoration(
              'Police Station',
            ),
            onChanged: (value) {
              adverseCase.policeStation = value;
            },
          ),

          const SizedBox(height: 10),

          TextFormField(
            initialValue:
                adverseCase.crimeReference,
            decoration: _inputDecoration(
              'Crime No. / Reference',
              hint: 'If available',
            ),
            onChanged: (value) {
              adverseCase.crimeReference = value;
            },
          ),

          const SizedBox(height: 10),

          TextFormField(
            initialValue: adverseCase.remarks,
            maxLines: 3,
            decoration: _inputDecoration(
              'Remarks',
            ),
            onChanged: (value) {
              adverseCase.remarks = value;
            },
          ),
        ],
      ),
    );
  }

  bool _validateOrganizerDetails() {
    if (_organizers.isEmpty) {
      _showMessage(
        'No Organizer / Member details are available for this GPID.',
      );
      return false;
    }

    for (int i = 0; i < _organizers.length; i++) {
      final organizer = _organizers[i];

      if (organizer.role == null) {
        _showMessage(
          'Please select Role for ${organizer.name}.',
        );
        return false;
      }

      if (organizer.role == 'Other' &&
          organizer.otherRole.trim().isEmpty) {
        _showMessage(
          'Please specify Role for ${organizer.name}.',
        );
        return false;
      }

      if (organizer.memberOfOtherAssociation ==
          null) {
        _showMessage(
          'Please answer other Association membership '
          'for ${organizer.name}.',
        );
        return false;
      }

      if (organizer.memberOfOtherAssociation ==
              'YES' &&
          organizer.otherAssociationGpid
              .trim()
              .isEmpty) {
        _showMessage(
          'Other Association GPID is mandatory '
          'for ${organizer.name}.',
        );
        return false;
      }
    }

    return true;
  }

  bool _validateMainOrganizer() {
    if (_mainOrganizerListed == null) {
      _showMessage(
        'Please answer: Is Main Organiser Listed Above?',
      );
      return false;
    }

    if (_mainOrganizerListed == 'YES') {
      final exists = _organizers.any(
        (organizer) =>
            organizer.role == 'Main Organiser',
      );

      if (!exists) {
        _showMessage(
          'Please select Main Organiser as the Role '
          'for one of the listed organizers.',
        );
        return false;
      }

      return true;
    }

    final name =
        _mainOrganizerNameController.text.trim();

    final mobile =
        _mainOrganizerMobileController.text.trim();

    if (name.isEmpty || mobile.isEmpty) {
      _showMessage(
        'Main Organiser Name and Cell No. are mandatory.',
      );
      return false;
    }

    if (_newMainOtherAssociation == null) {
      _showMessage(
        'Please answer whether Main Organiser is '
        'a member of any other Association.',
      );
      return false;
    }

    if (_newMainOtherAssociation == 'YES' &&
        _newMainOtherGpidController.text
            .trim()
            .isEmpty) {
      _showMessage(
        'Other Association GPID is mandatory '
        'for Main Organiser.',
      );
      return false;
    }

    _createOrUpdateManualMainOrganizer();

    return true;
  }

  bool _validateContacts() {
    for (final organizer in _organizers) {
      if (organizer.contactVerified == null) {
        _showMessage(
          'Please complete Contact Verification '
          'for ${organizer.name}.',
        );
        return false;
      }

      if (organizer.contactVerified == 'NO' &&
          organizer.contactRemarks
              .trim()
              .isEmpty) {
        _showMessage(
          'Remarks are mandatory for ${organizer.name} '
          'when Contact Verification is NO.',
        );
        return false;
      }
    }

    return true;
  }

  bool _validateConfidentialInformation() {
    for (final organizer in _organizers) {
      if (organizer.adverseInformation == null) {
        _showMessage(
          'Please complete Confidential Verification '
          'for ${organizer.name}.',
        );
        return false;
      }

      if (organizer.adverseInformation == 'YES') {
        if (organizer.adverseCases.isEmpty) {
          _showMessage(
            'Please enter adverse information '
            'for ${organizer.name}.',
          );
          return false;
        }

        for (final adverseCase
            in organizer.adverseCases) {
          if (adverseCase.nature.trim().isEmpty ||
              adverseCase.policeStation
                  .trim()
                  .isEmpty) {
            _showMessage(
              'Nature of Case and Police Station '
              'are mandatory for ${organizer.name}.',
            );
            return false;
          }
        }
      }
    }

    return true;
  }

  Future<bool> _showConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Organizer Verification Confirmation',
          ),
          content: const Text(
            'I hereby confirm that I have personally '
            'verified the Organizer / Member details '
            'recorded above and that the information '
            'entered during verification is true and '
            'correct to the best of my knowledge.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'CONFIRM & SAVE',
              ),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _saveVerification() async {
    Map<String, dynamic> result;

    if (_allOrganizersVerified == null) {
      _showMessage(
        'Please answer whether all Organizers\' '
        'details were personally verified.',
      );
      return;
    }

    if (_allOrganizersVerified == 'NO') {
      if (_notVerifiedRemarksController.text.trim().isEmpty) {
        _showMessage(
          'Remarks / Reason is mandatory.',
        );
        return;
      }

      if (!_fieldOfficerDeclaration) {
        _showMessage(
          'Field Officer Declaration is mandatory.',
        );
        return;
      }

      final confirmed = await _showConfirmation();

      if (!confirmed || !mounted) {
        return;
      }

      result = {
        'applicationId': widget.applicationId,
        'gpid': _selectedGpid,
        'allOrganizersPersonallyVerified': 'NO',
        'remarks': _notVerifiedRemarksController.text.trim(),
        'fieldOfficerDeclaration': true,
        'verifiedAt': DateTime.now().toIso8601String(),
      };
    } else {
      if (!_validateOrganizerDetails()) {
        return;
      }

      if (!_validateMainOrganizer()) {
        return;
      }

      if (!_validateContacts()) {
        return;
      }

      if (!_validateConfidentialInformation()) {
        return;
      }

      if (!_fieldOfficerDeclaration) {
        _showMessage(
          'Field Officer Declaration is mandatory.',
        );
        return;
      }

      final confirmed = await _showConfirmation();

      if (!confirmed || !mounted) {
        return;
      }

      result = {
        'applicationId': widget.applicationId,
        'gpid': _selectedGpid,
        'allOrganizersPersonallyVerified': 'YES',
        'mainOrganizerListed': _mainOrganizerListed,
        'organizers': _organizers.map((e) => e.toMap()).toList(),
        'fieldOfficerDeclaration': true,
        'verifiedAt': DateTime.now().toIso8601String(),
      };
    }

    setState(() {
      _saving = true;
    });

    try {
      await VerificationApiService.saveModuleResult(
        applicationId: widget.applicationId,
        gpid: _selectedGpid,
        moduleKey: 'organizerResult',
        result: result,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            'Organizer-Based Verification saved '
            'successfully for GPID $_selectedGpid.',
          ),
        ),
      );

      Navigator.pop(
        context,
        result,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Unable to save Organizer-Based Verification to the server. '
        'Please check the network and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicantName =
        _clean(widget.ganeshRecord?['name']);

    final association =
        _clean(widget.ganeshRecord?['association']);

    final policeStation =
        _clean(widget.ganeshRecord?['ps_name']);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF17365D),
        foregroundColor: Colors.white,
        title: const Text(
          'Organizer-Based Verification',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SELECTED GPID',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 12),
                  _displayField(
                    'Applicant Name',
                    applicantName,
                  ),
                  const SizedBox(height: 8),
                  _displayField(
                    'Association / Organisation',
                    association,
                  ),
                  const SizedBox(height: 8),
                  _displayField(
                    'Police Station',
                    policeStation,
                  ),
                ],
              ),
            ),

            _pointHeader(
              1,
              'All Organizers\' Details Personally Verified?',
            ),

            const Text(
              'Organizer details available against the '
              'selected GPID will be displayed for '
              'individual verification.',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 10),

            _yesNoSelector(
              value: _allOrganizersVerified,
              onChanged: (value) {
                setState(() {
                  _allOrganizersVerified = value;
                });
              },
            ),

            if (_allOrganizersVerified == 'NO') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller:
                    _notVerifiedRemarksController,
                maxLines: 4,
                decoration: _inputDecoration(
                  'Mandatory Remarks / Reason',
                ),
              ),
            ],

            if (_allOrganizersVerified == 'YES') ...[
              _pointHeader(
                2,
                'Organizer / Member Details',
              ),

              if (_organizers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'No Organizer / Member details '
                    'are available in the selected '
                    'GPID API record.',
                  ),
                ),

              for (int i = 0;
                  i < _organizers.length;
                  i++)
                if (!_organizers[i].manuallyAdded)
                  _buildOrganizerCard(
                    _organizers[i],
                    i,
                  ),

              _pointHeader(
                3,
                'Is Main Organiser Listed Above?',
              ),

              _yesNoSelector(
                value: _mainOrganizerListed,
                onChanged: (value) {
                  setState(() {
                    _mainOrganizerListed = value;

                    if (value == 'YES') {
                      _removeManualMainOrganizer();
                      _mainOrganizerNameController.clear();
                      _mainOrganizerMobileController.clear();
                      _newMainOtherAssociation = null;
                      _newMainOtherGpidController.clear();
                    } else {
                      _syncManualMainOrganizer();
                    }
                  });
                },
              ),

              if (_mainOrganizerListed == 'NO') ...[
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          const Color(0xFFD8DEE8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Main Organiser Details',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Color(0xFF17365D),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller:
                            _mainOrganizerNameController,
                        decoration:
                            _inputDecoration(
                          'Name',
                        ),
                        onChanged: (_) {
                          setState(() {
                            _syncManualMainOrganizer();
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        controller:
                            _mainOrganizerMobileController,
                        keyboardType:
                            TextInputType.phone,
                        decoration:
                            _inputDecoration(
                          'Cell No.',
                        ),
                        onChanged: (_) {
                          setState(() {
                            _syncManualMainOrganizer();
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      _displayField(
                        'Role',
                        'Main Organiser',
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Is this person a member of '
                        'any other Association?',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      _yesNoSelector(
                        value:
                            _newMainOtherAssociation,
                        onChanged: (value) {
                          setState(() {
                            _newMainOtherAssociation =
                                value;

                            if (value == 'NO') {
                              _newMainOtherGpidController
                                  .clear();
                            }

                            _syncManualMainOrganizer();
                          });
                        },
                      ),

                      if (_newMainOtherAssociation ==
                          'YES') ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller:
                              _newMainOtherGpidController,
                          textCapitalization:
                              TextCapitalization
                                  .characters,
                          decoration:
                              _inputDecoration(
                            'Other Association GPID',
                            hint: 'Enter GPID',
                          ),
                          onChanged: (_) {
                            setState(() {
                              _syncManualMainOrganizer();
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              _pointHeader(
                4,
                'Individual Organizer Contact Verification',
              ),

              const Text(
                'Verify each Organizer / Member '
                'through the given Cell No.',
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),

              for (int i = 0;
                  i < _organizers.length;
                  i++)
                _buildContactCard(
                  _organizers[i],
                  i,
                ),

              _pointHeader(
                5,
                'Adverse Information / Previous Cases',
              ),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFE9E9),
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        const Color(0xFFD85C5C),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock,
                      color: Color(0xFFB42318),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'CONFIDENTIAL FIELD\n'
                        'For official verification '
                        'purposes only. This information '
                        'shall not be disclosed to the '
                        'organizer or displayed in any '
                        'public-facing view.',
                        style: TextStyle(
                          color:
                              Color(0xFF8A1C1C),
                          fontWeight:
                              FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              for (int i = 0;
                  i < _organizers.length;
                  i++)
                _buildConfidentialCard(
                  _organizers[i],
                  i,
                ),
            ],

            _pointHeader(
              6,
              'Field Officer Declaration',
            ),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity:
                  ListTileControlAffinity.leading,
              value: _fieldOfficerDeclaration,
              onChanged: (value) {
                setState(() {
                  _fieldOfficerDeclaration =
                      value ?? false;
                });
              },
              title: const Text(
                'I hereby confirm that I have '
                'personally verified the Organizer / '
                'Member details recorded above and '
                'that the information entered during '
                'verification is true and correct to '
                'the best of my knowledge.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving
                        ? null
                        : _saveVerification,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF17365D),
                      foregroundColor:
                          Colors.white,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'CONFIRM & SAVE',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
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