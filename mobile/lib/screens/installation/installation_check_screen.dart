import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

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

class _InstallationCheckScreenState extends State<InstallationCheckScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  bool _loading = true;
  bool _submitting = false;
  String _loadError = '';

  Map<String, dynamic>? _stage1Idol;
  Map<String, dynamic>? _stage1Location;
  Map<String, dynamic>? _stage1Organizer;
  List<dynamic> _previousVisits = <dynamic>[];

  Position? _currentPosition;

  // Module 1 - Idol installation
  bool? _idolInstalledNow;
  DateTime? _installationDate;
  bool? _heightSame;
  final TextEditingController _actualHeightFeet = TextEditingController();
  final TextEditingController _actualHeightInches = TextEditingController();
  bool? _materialSame;
  final TextEditingController _actualMaterial = TextEditingController();
  final TextEditingController _materialRemarks = TextEditingController();
  bool? _idolDeviation;
  final TextEditingController _idolDeviationRemarks = TextEditingController();
  XFile? _idolFreshPhoto;
  XFile? _idolDeviationPhoto;

  // Module 2 - Geo verification
  bool? _installedAtVerifiedLocation;
  final TextEditingController _geoMismatchReason = TextEditingController();
  XFile? _geoPhoto;
  double? _distanceMetres;

  // Module 4 - Documentary setup
  bool? _physicalPointBook;
  bool? _pointBookGeoTagged;
  bool? _qrCode;
  bool? _gpidBoard;
  bool? _policeNoticeBoard;
  bool? _contactDetails;
  bool _documentaryConfirmed = false;
  Position? _documentaryPosition;

  // Module 5 - Pre-planned setup
  bool? _ladduApplicable;
  bool? _hundiApplicable;
  bool? _jewelleryApplicable;
  bool? _cashGarlandApplicable;
  bool? _otherValuablesApplicable;
  final TextEditingController _nightKeepingPlace = TextEditingController();
  bool? _nightKeepingPlaceSafe;
  String? _responsiblePersonType;
  String? _selectedOrganizer;
  final TextEditingController _otherResponsibleName = TextEditingController();
  final TextEditingController _otherResponsibleCell = TextEditingController();
  XFile? _otherResponsiblePhoto;
  final TextEditingController _jewelleryDetails = TextEditingController();
  final TextEditingController _jewelleryValue = TextEditingController();
  final TextEditingController _cashGarlandDetails = TextEditingController();
  final TextEditingController _cashGarlandValue = TextEditingController();
  final TextEditingController _otherValuablesDetails = TextEditingController();
  final TextEditingController _otherValuablesValue = TextEditingController();
  bool _prePlannedConfirmed = false;
  Position? _prePlannedPosition;

  // Module 6 - Spectacular exhibition
  bool? _spectacularPresent;
  final TextEditingController _spectacularDescription = TextEditingController();
  XFile? _spectacularPhoto;
  bool? _spectacularPermission;
  bool? _spectacularViolation;
  bool? _spectacularHarmRisk;
  String? _spectacularType;
  final TextEditingController _spectacularAction = TextEditingController();
  bool _spectacularConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _actualHeightFeet,
      _actualHeightInches,
      _actualMaterial,
      _materialRemarks,
      _idolDeviationRemarks,
      _geoMismatchReason,
      _nightKeepingPlace,
      _otherResponsibleName,
      _otherResponsibleCell,
      _jewelleryDetails,
      _jewelleryValue,
      _cashGarlandDetails,
      _cashGarlandValue,
      _otherValuablesDetails,
      _otherValuablesValue,
      _spectacularDescription,
      _spectacularAction,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<dynamic> _asList(dynamic value) => value is List ? value : <dynamic>[];

  String _text(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty || s.toLowerCase() == 'null' ? fallback : s;
  }

  bool? _boolValue(dynamic value) {
    if (value is bool) return value;
    final s = value?.toString().trim().toUpperCase();
    if (s == 'YES' || s == 'TRUE') return true;
    if (s == 'NO' || s == 'FALSE') return false;
    return null;
  }

  Future<void> _loadContext() async {
    setState(() {
      _loading = true;
      _loadError = '';
    });
    try {
      final data = await InstallationCheckApiService.fetchInstallationContext(
        gpid: widget.applicationId,
      );
      final pre = _asMap(data['preInstallation']);
      if (!mounted) return;
      setState(() {
        _stage1Idol = _asMap(pre?['idolResult']);
        _stage1Location = _asMap(pre?['locationResult']);
        _stage1Organizer = _asMap(pre?['organizerResult']);
        _previousVisits = _asList(data['records']);

        final stage1Installed = _boolValue(_stage1Idol?['idolInstalled']);
        if (stage1Installed == true) {
          _idolInstalledNow = true;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<Position> _capturePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Please enable Location/GPS and try again.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it in App Settings.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<XFile?> _takePhoto() async {
    return _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
  }

  Future<void> _captureGeoVerification() async {
    try {
      final position = await _capturePosition();
      final verified = _asMap(_stage1Location?['currentVerifiedGeoLocation']);
      final lat = _toDouble(verified?['latitude']);
      final lng = _toDouble(verified?['longitude']);
      double? distance;
      if (lat != null && lng != null) {
        distance = Geolocator.distanceBetween(
          lat,
          lng,
          position.latitude,
          position.longitude,
        );
      }
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _distanceMetres = distance;
      });
    } catch (e) {
      _message(e.toString());
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> _captureDocumentaryGeo() async {
    try {
      final p = await _capturePosition();
      if (!mounted) return;
      setState(() => _documentaryPosition = p);
    } catch (e) {
      _message(e.toString());
    }
  }

  Future<void> _capturePrePlannedGeo() async {
    try {
      final p = await _capturePosition();
      if (!mounted) return;
      setState(() => _prePlannedPosition = p);
    } catch (e) {
      _message(e.toString());
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  List<Map<String, dynamic>> get _organizers {
    final list = _asList(_stage1Organizer?['organizers']);
    return list
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  String _organizerLabel(Map<String, dynamic> item) {
    final name = _text(item['name']);
    final mobile = _text(item['mobile'], '');
    final role = _text(
      item['role'] == 'Other' ? item['otherRole'] : item['role'],
      '',
    );
    return [
      name,
      if (role.isNotEmpty) role,
      if (mobile.isNotEmpty) mobile,
    ].join(' • ');
  }

  Map<String, dynamic>? get _verifiedStage1Geo =>
      _asMap(_stage1Location?['currentVerifiedGeoLocation']);

  bool get _stage1IdolWasInstalled =>
      _boolValue(_stage1Idol?['idolInstalled']) == true;

  String? _validate() {
    if (_idolInstalledNow == null) {
      return 'Complete Idol-Based Installation Verification.';
    }
    if (!_stage1IdolWasInstalled && _idolInstalledNow == true) {
      if (_installationDate == null) {
        return 'Select the actual Idol installation date.';
      }
      if (_idolFreshPhoto == null) {
        return 'Take a fresh photo of the newly installed Idol.';
      }
    }
    if (_idolInstalledNow == true) {
      if (_heightSame == null) {
        return 'Confirm whether Idol height is the same.';
      }
      if (_heightSame == false &&
          (_actualHeightFeet.text.trim().isEmpty &&
              _actualHeightInches.text.trim().isEmpty)) {
        return 'Enter actual Idol height.';
      }
      if (_materialSame == null) {
        return 'Confirm whether Idol material is the same.';
      }
      if (_materialSame == false &&
          (_actualMaterial.text.trim().isEmpty ||
              _materialRemarks.text.trim().isEmpty)) {
        return 'Enter actual Idol material and remarks.';
      }
      if (_idolDeviation == null) {
        return 'Confirm whether there is any Idol deviation.';
      }
      if (_idolDeviation == true && _idolDeviationRemarks.text.trim().isEmpty) {
        return 'Enter Idol deviation remarks.';
      }

      if (_currentPosition == null) {
        return 'Capture current GPS for Geo-Tagged Verification.';
      }
      if (_installedAtVerifiedLocation == null) {
        return 'Confirm whether the Idol is installed at the verified location.';
      }
      if (_installedAtVerifiedLocation == false) {
        if (_geoMismatchReason.text.trim().isEmpty) {
          return 'Enter reason/remarks for location mismatch.';
        }
        if (_geoPhoto == null) {
          return 'Take the mandatory geo-tagged photo for location mismatch.';
        }
      }

      final documentaryValues = <bool?>[
        _physicalPointBook,
        _pointBookGeoTagged,
        _qrCode,
        _gpidBoard,
        _policeNoticeBoard,
        _contactDetails,
      ];
      if (documentaryValues.any((e) => e == null)) {
        return 'Complete all Documentary Setup checks.';
      }
      if (_pointBookGeoTagged == true && _documentaryPosition == null) {
        return 'Capture GPS for the geo-tagged Point Book.';
      }
      if (!_documentaryConfirmed) {
        return 'Confirm the Documentary Setup declaration.';
      }

      final plannedValues = <bool?>[
        _ladduApplicable,
        _hundiApplicable,
        _jewelleryApplicable,
        _cashGarlandApplicable,
        _otherValuablesApplicable,
      ];
      if (plannedValues.any((e) => e == null)) {
        return 'Complete applicability of all Pre-Planned Setup valuables.';
      }
      if (_nightKeepingPlace.text.trim().isEmpty) {
        return 'Enter the place where valuables will be kept at night.';
      }
      if (_nightKeepingPlaceSafe == null) {
        return 'Confirm whether the night keeping place is safe.';
      }
      if (_responsiblePersonType == null) {
        return 'Select the responsible person.';
      }
      if (_responsiblePersonType == 'ORGANIZER' &&
          (_selectedOrganizer == null || _selectedOrganizer!.isEmpty)) {
        return 'Select the responsible organizer.';
      }
      if (_responsiblePersonType == 'OTHER' &&
          (_otherResponsibleName.text.trim().isEmpty ||
              _otherResponsibleCell.text.trim().isEmpty ||
              _otherResponsiblePhoto == null)) {
        return 'Enter Other responsible person name, cell number and photo.';
      }
      if (_jewelleryApplicable == true &&
          (_jewelleryDetails.text.trim().isEmpty ||
              _jewelleryValue.text.trim().isEmpty)) {
        return 'Enter Jewellery details and approximate value.';
      }
      if (_cashGarlandApplicable == true &&
          (_cashGarlandDetails.text.trim().isEmpty ||
              _cashGarlandValue.text.trim().isEmpty)) {
        return 'Enter Cash Garland details and approximate value.';
      }
      if (_otherValuablesApplicable == true &&
          (_otherValuablesDetails.text.trim().isEmpty ||
              _otherValuablesValue.text.trim().isEmpty)) {
        return 'Enter Other valuables details and approximate value.';
      }
      if (!_prePlannedConfirmed) {
        return 'Confirm the Pre-Planned Installation Setup.';
      }

      if (_spectacularPresent == null) {
        return 'Confirm whether any Spectacular Exhibition is present.';
      }
      if (_spectacularPresent == true) {
        if (_spectacularDescription.text.trim().isEmpty ||
            _spectacularPhoto == null ||
            _spectacularPermission == null ||
            _spectacularViolation == null ||
            _spectacularHarmRisk == null ||
            _spectacularType == null) {
          return 'Complete all Spectacular Exhibition details and photo.';
        }
        if ((_spectacularType == 'TYPE_2' || _spectacularType == 'TYPE_3') &&
            _spectacularAction.text.trim().isEmpty) {
          return 'Enter action required/taken for the violation.';
        }
      }
      if (!_spectacularConfirmed) {
        return 'Confirm the Spectacular Exhibition verification.';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final error = _validate();
    if (error != null) {
      _message(error);
      return;
    }

    setState(() => _submitting = true);
    final now = DateTime.now();

    final selectedOrganizerMap = _selectedOrganizer == null
        ? null
        : _organizers.cast<Map<String, dynamic>?>().firstWhere(
            (e) => _organizerLabel(e!) == _selectedOrganizer,
            orElse: () => null,
          );

    final payload = <String, dynamic>{
      'gpid': widget.applicationId,
      'applicationId': widget.applicationId,
      'checkSource': 'MOBILE',

      // Final Stage-2 modules.
      'idolInstallationResult': <String, dynamic>{
        'stage1IdolInstalled': _stage1Idol?['idolInstalled'],
        'idolInstalled': _idolInstalledNow,
        'installationDate': _installationDate?.toIso8601String(),
        'stage1DeclaredHeight': _stage1Idol?['declaredIdolHeight'],
        'stage1ActualHeightFeet': _stage1Idol?['actualHeightFeet'],
        'stage1ActualHeightInches': _stage1Idol?['actualHeightInches'],
        'heightSameAsPreInstallation': _heightSame,
        'actualHeightFeet': _heightSame == false
            ? _actualHeightFeet.text.trim()
            : null,
        'actualHeightInches': _heightSame == false
            ? _actualHeightInches.text.trim()
            : null,
        'stage1Material': _stage1Idol?['idolMaterial'],
        'materialSameAsPreInstallation': _materialSame,
        'actualMaterial': _materialSame == false
            ? _actualMaterial.text.trim()
            : null,
        'materialRemarks': _materialSame == false
            ? _materialRemarks.text.trim()
            : null,
        'stage1PhotoPath': _stage1Idol?['idolPhotoPath'],
        'freshInstallationPhotoPath': _idolFreshPhoto?.path,
        'deviation': _idolDeviation,
        'deviationRemarks': _idolDeviation == true
            ? _idolDeviationRemarks.text.trim()
            : null,
        'deviationPhotoPath': _idolDeviationPhoto?.path,
        'verifiedAt': now.toIso8601String(),
      },
      'geoTaggedVerificationResult': _idolInstalledNow == true
          ? <String, dynamic>{
              'stage1VerifiedGeoLocation': _verifiedStage1Geo,
              'currentGeoLocation': _currentPosition == null
                  ? null
                  : <String, dynamic>{
                      'latitude': _currentPosition!.latitude,
                      'longitude': _currentPosition!.longitude,
                      'accuracy': _currentPosition!.accuracy,
                      'capturedAt': now.toIso8601String(),
                    },
              'distanceMetres': _distanceMetres,
              'installedAtVerifiedLocation': _installedAtVerifiedLocation,
              'mismatchReasonOrRemarks': _installedAtVerifiedLocation == false
                  ? _geoMismatchReason.text.trim()
                  : null,
              'mismatchPhotoPath': _installedAtVerifiedLocation == false
                  ? _geoPhoto?.path
                  : null,
              'verifiedAt': now.toIso8601String(),
            }
          : null,
      'clusterSectorResult': <String, dynamic>{
        'status': 'AUTHORITATIVE_DEPLOYMENT_DATA_NOT_AVAILABLE',
        'sector': null,
        'cluster': null,
        'sectorInCharge': null,
        'clusterInCharge': null,
        'note': 'Sector/Cluster deployment details must be populated only from an authoritative deployment master.',
        'recordedAt': now.toIso8601String(),
      },
      'documentarySetupResult': _idolInstalledNow == true
          ? <String, dynamic>{
              'physicalPointBook': _physicalPointBook,
              'pointBookGeoTagged': _pointBookGeoTagged,
              'qrCode': _qrCode,
              'gpidBoard': _gpidBoard,
              'policeNoticeBoard': _policeNoticeBoard,
              'contactDetails': _contactDetails,
              'pointBookGeoLocation': _documentaryPosition == null
                  ? null
                  : <String, dynamic>{
                      'latitude': _documentaryPosition!.latitude,
                      'longitude': _documentaryPosition!.longitude,
                      'accuracy': _documentaryPosition!.accuracy,
                    },
              'confirmed': _documentaryConfirmed,
              'confirmationText': 'I have physically verified the above Documentary Setup at the Ganesh Mandap and confirm that the information recorded above is correct.',
              'verifiedAt': now.toIso8601String(),
            }
          : null,
      'prePlannedSetupResult': _idolInstalledNow == true
          ? <String, dynamic>{
              'ladduApplicable': _ladduApplicable,
              'hundiApplicable': _hundiApplicable,
              'jewelleryApplicable': _jewelleryApplicable,
              'cashGarlandApplicable': _cashGarlandApplicable,
              'otherValuablesApplicable': _otherValuablesApplicable,
              'nightKeepingPlace': _nightKeepingPlace.text.trim(),
              'nightKeepingPlaceSafe': _nightKeepingPlaceSafe,
              'responsiblePersonType': _responsiblePersonType,
              'responsibleOrganizer': selectedOrganizerMap,
              'otherResponsiblePerson': _responsiblePersonType == 'OTHER'
                  ? <String, dynamic>{
                      'name': _otherResponsibleName.text.trim(),
                      'cell': _otherResponsibleCell.text.trim(),
                      'photoPath': _otherResponsiblePhoto?.path,
                    }
                  : null,
              'jewellery': _jewelleryApplicable == true
                  ? <String, dynamic>{
                      'details': _jewelleryDetails.text.trim(),
                      'approximateValue': _jewelleryValue.text.trim(),
                    }
                  : null,
              'cashGarland': _cashGarlandApplicable == true
                  ? <String, dynamic>{
                      'details': _cashGarlandDetails.text.trim(),
                      'approximateValue': _cashGarlandValue.text.trim(),
                    }
                  : null,
              'otherValuables': _otherValuablesApplicable == true
                  ? <String, dynamic>{
                      'details': _otherValuablesDetails.text.trim(),
                      'approximateValue': _otherValuablesValue.text.trim(),
                    }
                  : null,
              'confirmation': _prePlannedConfirmed,
              'geoLocation': _prePlannedPosition == null
                  ? null
                  : <String, dynamic>{
                      'latitude': _prePlannedPosition!.latitude,
                      'longitude': _prePlannedPosition!.longitude,
                      'accuracy': _prePlannedPosition!.accuracy,
                    },
              'verifiedAt': now.toIso8601String(),
            }
          : null,
      'spectacularExhibitionResult': _idolInstalledNow == true
          ? <String, dynamic>{
              'present': _spectacularPresent,
              'description': _spectacularPresent == true
                  ? _spectacularDescription.text.trim()
                  : null,
              'photoPath': _spectacularPresent == true
                  ? _spectacularPhoto?.path
                  : null,
              'permissionAvailable': _spectacularPresent == true
                  ? _spectacularPermission
                  : null,
              'violationObserved': _spectacularPresent == true
                  ? _spectacularViolation
                  : null,
              'harmOrRiskObserved': _spectacularPresent == true
                  ? _spectacularHarmRisk
                  : null,
              'classification': _spectacularPresent == true
                  ? _spectacularType
                  : null,
              'actionRequiredOrTaken': _spectacularPresent == true
                  ? _spectacularAction.text.trim()
                  : null,
              'confirmed': _spectacularConfirmed,
              'verifiedAt': now.toIso8601String(),
            }
          : null,

      // Legacy prototype fields intentionally not reused by the final Stage-2 UI.
      'installationResult': null,
      'volunteerResult': null,
      'lightingResult': null,
      'sanitationResult': null,
      'poojaResult': null,
      'antiDesecrationResult': null,
      'checkedAt': now.toIso8601String(),
      'submittedAt': now.toIso8601String(),
    };

    try {
      await InstallationCheckApiService.submitInstallationCheck(payload);
      if (!mounted) return;
      _message('Stage 2 Installation verification submitted successfully.');
      Navigator.pop(context, true);
    } catch (e) {
      _message('Unable to submit Installation verification: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _sectionTitle(String number, String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $title',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ],
      ),
    );
  }

  Widget _yesNo({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onChanged,
    String yes = 'YES',
    String no = 'NO',
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                value: true,
                label: Text(yes),
                icon: const Icon(Icons.check_circle_outline),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text(no),
                icon: const Icon(Icons.cancel_outlined),
              ),
            ],
            selected: value == null ? <bool>{} : <bool>{value},
            emptySelectionAllowed: true,
            onSelectionChanged: (s) => onChanged(s.isEmpty ? null : s.first),
          ),
        ],
      ),
    );
  }

  Widget _readonly(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 155,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Expanded(child: Text(_text(value))),
        ],
      ),
    );
  }

  Widget _photoButton({
    required String label,
    required XFile? photo,
    required Future<void> Function() onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.camera_alt_outlined),
          label: Text(photo == null ? label : 'Retake Photo'),
        ),
        if (photo != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(photo.path),
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _installationDate ?? now,
      firstDate: DateTime(2026, 9, 1),
      lastDate: now,
    );
    if (date != null && mounted) setState(() => _installationDate = date);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Installation Verification')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Installation Verification')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(_loadError, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadContext,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final verifiedGeo = _verifiedStage1Geo;

    return Scaffold(
      appBar: AppBar(title: const Text('Installation Verification')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card([
              const Text(
                'Stage 2 - Installation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              Text(
                'Stage-1 information is carried forward. Record only the actual installation confirmation, changes and deviations.',
                style: const TextStyle(color: Color(0xFF475569)),
              ),
              if (_previousVisits.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Previous Stage-2 visits: ${_previousVisits.length}'),
              ],
            ]),

            _card([
              _sectionTitle(
                '1',
                'Idol-Based Installation Verification',
                subtitle: 'Pre-Installation Idol details are read-only.',
              ),
              if (_stage1Idol == null)
                const Text(
                  'Stage-1 Idol verification is not available for this GPID.',
                  style: TextStyle(color: Color(0xFFB45309)),
                )
              else ...[
                _readonly('Stage-1 Installed', _stage1Idol?['idolInstalled']),
                _readonly('Material', _stage1Idol?['idolMaterial']),
                _readonly(
                  'Declared Height',
                  _stage1Idol?['declaredIdolHeight'],
                ),
                _readonly(
                  'Actual Height',
                  '${_text(_stage1Idol?['actualHeightFeet'], '0')} ft '
                      '${_text(_stage1Idol?['actualHeightInches'], '0')} in',
                ),
                _readonly('Stage-1 Verified', _stage1Idol?['verifiedAt']),
              ],
              const Divider(height: 28),
              if (_stage1IdolWasInstalled)
                const Text(
                  'Idol was already confirmed as installed in Stage 1. Installation status cannot be altered here.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                )
              else
                _yesNo(
                  label: 'Is the Idol installed now?',
                  value: _idolInstalledNow,
                  onChanged: (v) => setState(() => _idolInstalledNow = v),
                ),
              if (!_stage1IdolWasInstalled && _idolInstalledNow == true) ...[
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    _installationDate == null
                        ? 'Select Actual Installation Date'
                        : 'Installation Date: '
                              '${_installationDate!.day.toString().padLeft(2, '0')}-'
                              '${_installationDate!.month.toString().padLeft(2, '0')}-'
                              '${_installationDate!.year}',
                  ),
                ),
                const SizedBox(height: 12),
                _photoButton(
                  label: 'Take Fresh Installed Idol Photo',
                  photo: _idolFreshPhoto,
                  onPressed: () async {
                    final p = await _takePhoto();
                    if (p != null && mounted) {
                      setState(() => _idolFreshPhoto = p);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (_idolInstalledNow == true) ...[
                _yesNo(
                  label: 'Is actual Idol height the same as Stage 1?',
                  value: _heightSame,
                  onChanged: (v) => setState(() => _heightSame = v),
                ),
                if (_heightSame == false)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _actualHeightFeet,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Actual Feet',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _actualHeightInches,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Actual Inches',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                _yesNo(
                  label: 'Is actual Idol material the same as Stage 1?',
                  value: _materialSame,
                  onChanged: (v) => setState(() => _materialSame = v),
                ),
                if (_materialSame == false) ...[
                  TextField(
                    controller: _actualMaterial,
                    decoration: const InputDecoration(
                      labelText: 'Actual Material',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _materialRemarks,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Reason / Remarks',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _yesNo(
                  label: 'Any deviation from Pre-Installation verification?',
                  value: _idolDeviation,
                  onChanged: (v) => setState(() => _idolDeviation = v),
                ),
                if (_idolDeviation == true) ...[
                  TextField(
                    controller: _idolDeviationRemarks,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mandatory Deviation Remarks',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _photoButton(
                    label: 'Add Supporting Deviation Photo (Optional)',
                    photo: _idolDeviationPhoto,
                    onPressed: () async {
                      final p = await _takePhoto();
                      if (p != null && mounted) {
                        setState(() => _idolDeviationPhoto = p);
                      }
                    },
                  ),
                ],
              ],
            ]),

            if (_idolInstalledNow == true)
              _card([
                _sectionTitle(
                  '2',
                  'Geo-Tagged Verification',
                  subtitle: 'Compare the present installation with the Stage-1 verified location.',
                ),
                _readonly('Stage-1 Latitude', verifiedGeo?['latitude']),
                _readonly('Stage-1 Longitude', verifiedGeo?['longitude']),
                _readonly('Stage-1 Accuracy', verifiedGeo?['accuracy']),
                _readonly('Stage-1 Captured', verifiedGeo?['capturedAt']),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _captureGeoVerification,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    _currentPosition == null
                        ? 'Capture Current GPS'
                        : 'Recapture Current GPS',
                  ),
                ),
                if (_currentPosition != null) ...[
                  const SizedBox(height: 12),
                  _readonly(
                    'Current Latitude',
                    _currentPosition!.latitude.toStringAsFixed(6),
                  ),
                  _readonly(
                    'Current Longitude',
                    _currentPosition!.longitude.toStringAsFixed(6),
                  ),
                  _readonly(
                    'GPS Accuracy',
                    '${_currentPosition!.accuracy.toStringAsFixed(1)} m',
                  ),
                  _readonly(
                    'Distance',
                    _distanceMetres == null
                        ? 'Stage-1 GPS unavailable'
                        : '${_distanceMetres!.toStringAsFixed(1)} m',
                  ),
                  const SizedBox(height: 8),
                  _yesNo(
                    label: 'Idol installed at the Stage-1 verified location?',
                    value: _installedAtVerifiedLocation,
                    onChanged: (v) =>
                        setState(() => _installedAtVerifiedLocation = v),
                  ),
                  if (_installedAtVerifiedLocation == false) ...[
                    TextField(
                      controller: _geoMismatchReason,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Mandatory Reason / Remarks',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _photoButton(
                      label: 'Take Mandatory Geo-Tagged Photo',
                      photo: _geoPhoto,
                      onPressed: () async {
                        try {
                          final p = await _takePhoto();
                          if (p == null) return;
                          final pos = await _capturePosition();
                          if (!mounted) return;
                          setState(() {
                            _geoPhoto = p;
                            _currentPosition = pos;
                          });
                        } catch (e) {
                          _message(e.toString());
                        }
                      },
                    ),
                  ],
                ],
              ]),

            if (_idolInstalledNow == true)
              _card([
                _sectionTitle(
                  '3',
                  'Cluster & Sector',
                  subtitle: 'Only authoritative deployment-master information may be displayed.',
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Authoritative Sector / Cluster deployment data is not presently available to this module. No Sector, Cluster or In-charge details will be invented or manually assumed.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ]),

            if (_idolInstalledNow == true)
              _card([
                _sectionTitle('4', 'Documentary Setup'),
                _yesNo(
                  label: 'Physical Point Book available?',
                  value: _physicalPointBook,
                  onChanged: (v) => setState(() => _physicalPointBook = v),
                ),
                _yesNo(
                  label: 'Point Book Geo-Tagged?',
                  value: _pointBookGeoTagged,
                  onChanged: (v) {
                    setState(() {
                      _pointBookGeoTagged = v;
                      if (v != true) _documentaryPosition = null;
                    });
                  },
                ),
                if (_pointBookGeoTagged == true)
                  OutlinedButton.icon(
                    onPressed: _captureDocumentaryGeo,
                    icon: const Icon(Icons.location_on_outlined),
                    label: Text(
                      _documentaryPosition == null
                          ? 'Capture Point Book GPS'
                          : 'GPS Captured - Recapture',
                    ),
                  ),
                const SizedBox(height: 10),
                _yesNo(
                  label: 'QR Code available?',
                  value: _qrCode,
                  onChanged: (v) => setState(() => _qrCode = v),
                ),
                _yesNo(
                  label: 'GPID Board available?',
                  value: _gpidBoard,
                  onChanged: (v) => setState(() => _gpidBoard = v),
                ),
                _yesNo(
                  label: 'Police Notice Board available?',
                  value: _policeNoticeBoard,
                  onChanged: (v) => setState(() => _policeNoticeBoard = v),
                ),
                _yesNo(
                  label: 'Contact Details displayed/available?',
                  value: _contactDetails,
                  onChanged: (v) => setState(() => _contactDetails = v),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _documentaryConfirmed,
                  onChanged: (v) =>
                      setState(() => _documentaryConfirmed = v == true),
                  title: const Text(
                    'I have physically verified the above Documentary Setup at the Ganesh Mandap and confirm that the information recorded above is correct.',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ]),

            if (_idolInstalledNow == true)
              _card([
                _sectionTitle(
                  '5',
                  'Pre-Planned Installation Setup',
                  subtitle: 'Record the planned night custody and responsibility for valuables.',
                ),
                _yesNo(
                  label: 'Laddu applicable?',
                  value: _ladduApplicable,
                  onChanged: (v) => setState(() => _ladduApplicable = v),
                ),
                _yesNo(
                  label: 'Hundi applicable?',
                  value: _hundiApplicable,
                  onChanged: (v) => setState(() => _hundiApplicable = v),
                ),
                _yesNo(
                  label: 'Jewellery applicable?',
                  value: _jewelleryApplicable,
                  onChanged: (v) => setState(() => _jewelleryApplicable = v),
                ),
                if (_jewelleryApplicable == true) ...[
                  TextField(
                    controller: _jewelleryDetails,
                    decoration: const InputDecoration(
                      labelText: 'Jewellery Details',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _jewelleryValue,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Approximate Value',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _yesNo(
                  label: 'Cash Garland applicable?',
                  value: _cashGarlandApplicable,
                  onChanged: (v) => setState(() => _cashGarlandApplicable = v),
                ),
                if (_cashGarlandApplicable == true) ...[
                  TextField(
                    controller: _cashGarlandDetails,
                    decoration: const InputDecoration(
                      labelText: 'Cash Garland Details',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _cashGarlandValue,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Approximate Value',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _yesNo(
                  label: 'Other valuables applicable?',
                  value: _otherValuablesApplicable,
                  onChanged: (v) =>
                      setState(() => _otherValuablesApplicable = v),
                ),
                if (_otherValuablesApplicable == true) ...[
                  TextField(
                    controller: _otherValuablesDetails,
                    decoration: const InputDecoration(
                      labelText: 'Other Valuables Details',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _otherValuablesValue,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Approximate Value',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _nightKeepingPlace,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Place where valuables will be kept at night',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                _yesNo(
                  label: 'Is the proposed keeping place safe?',
                  value: _nightKeepingPlaceSafe,
                  onChanged: (v) => setState(() => _nightKeepingPlaceSafe = v),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _responsiblePersonType,
                  decoration: const InputDecoration(
                    labelText: 'Responsible Person',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'ORGANIZER',
                      child: Text('Organizer - Stage 1'),
                    ),
                    DropdownMenuItem(
                      value: 'OTHER',
                      child: Text('Other Person'),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _responsiblePersonType = v;
                    _selectedOrganizer = null;
                  }),
                ),
                const SizedBox(height: 12),
                if (_responsiblePersonType == 'ORGANIZER')
                  if (_organizers.isEmpty)
                    const Text(
                      'No Stage-1 Organizer list is available.',
                      style: TextStyle(color: Color(0xFFB45309)),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedOrganizer,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Organizer',
                        border: OutlineInputBorder(),
                      ),
                      items: _organizers
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: _organizerLabel(e),
                              child: Text(
                                _organizerLabel(e),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedOrganizer = v),
                    ),
                if (_responsiblePersonType == 'OTHER') ...[
                  TextField(
                    controller: _otherResponsibleName,
                    decoration: const InputDecoration(
                      labelText: 'Responsible Person Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _otherResponsibleCell,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Cell Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _photoButton(
                    label: 'Take Responsible Person Photo',
                    photo: _otherResponsiblePhoto,
                    onPressed: () async {
                      final p = await _takePhoto();
                      if (p != null && mounted) {
                        setState(() => _otherResponsiblePhoto = p);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _capturePrePlannedGeo,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    _prePlannedPosition == null
                        ? 'Capture Verification GPS'
                        : 'Verification GPS Captured - Recapture',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _prePlannedConfirmed,
                  onChanged: (v) =>
                      setState(() => _prePlannedConfirmed = v == true),
                  title: const Text(
                    'I confirm that the above Pre-Planned Installation Setup has been physically verified and recorded correctly.',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ]),

            if (_idolInstalledNow == true)
              _card([
                _sectionTitle('6', 'Spectacular Exhibition'),
                _yesNo(
                  label: 'Any Spectacular Exhibition present?',
                  value: _spectacularPresent,
                  onChanged: (v) => setState(() => _spectacularPresent = v),
                ),
                if (_spectacularPresent == true) ...[
                  TextField(
                    controller: _spectacularDescription,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _photoButton(
                    label: 'Take Exhibition Photo',
                    photo: _spectacularPhoto,
                    onPressed: () async {
                      final p = await _takePhoto();
                      if (p != null && mounted) {
                        setState(() => _spectacularPhoto = p);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  _yesNo(
                    label: 'Required permission available?',
                    value: _spectacularPermission,
                    onChanged: (v) =>
                        setState(() => _spectacularPermission = v),
                  ),
                  _yesNo(
                    label: 'Any violation observed?',
                    value: _spectacularViolation,
                    onChanged: (v) => setState(() => _spectacularViolation = v),
                  ),
                  _yesNo(
                    label: 'Any harm / public safety risk observed?',
                    value: _spectacularHarmRisk,
                    onChanged: (v) => setState(() => _spectacularHarmRisk = v),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _spectacularType,
                    decoration: const InputDecoration(
                      labelText: 'Classification',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'TYPE_1',
                        child: Text('Type 1 - Observation'),
                      ),
                      DropdownMenuItem(
                        value: 'TYPE_2',
                        child: Text('Type 2 - VIOLATION ACTION REQUIRED'),
                      ),
                      DropdownMenuItem(
                        value: 'TYPE_3',
                        child: Text(
                          'Type 3 - SERIOUS VIOLATION IMMEDIATE ACTION REQUIRED',
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _spectacularType = v),
                  ),
                  if (_spectacularType == 'TYPE_2' ||
                      _spectacularType == 'TYPE_3') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _spectacularAction,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Action Required / Taken',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _spectacularConfirmed,
                  onChanged: (v) =>
                      setState(() => _spectacularConfirmed = v == true),
                  title: const Text(
                    'I confirm that the Spectacular Exhibition status has been physically verified and correctly recorded.',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_spectacularType == 'TYPE_2' ||
                    _spectacularType == 'TYPE_3')
                  const Text(
                    'Confirmation records the verification only. It does not close or resolve the violation.',
                    style: TextStyle(
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ]),

            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                _submitting
                    ? 'Submitting...'
                    : 'Submit Stage 2 Installation Verification',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
