import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../measurement/ar_measurement_screen.dart';
import '../../models/ar_measurement_result.dart';
import '../../services/verification_api_service.dart';

class IdolVerificationScreen extends StatefulWidget {
  final String applicationId;
  final String? gpid;
  final Map<String, dynamic>? ganeshRecord;

  const IdolVerificationScreen({
    super.key,
    required this.applicationId,
    this.gpid,
    this.ganeshRecord,
  });

  @override
  State<IdolVerificationScreen> createState() =>
      _IdolVerificationScreenState();
}

class _IdolVerificationScreenState extends State<IdolVerificationScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  String idolInstalled = '';
  String idolBroughtFrom = '';
  String idolMaterial = '';
  String heightMatches = '';
  String widthMatches = '';
  String heightRecordMode = '';
  String widthRecordMode = '';
  String basePlatformSafe = '';

  XFile? idolImage;

  ArMeasurementResult? heightMeasurement;
  ArMeasurementResult? widthMeasurement;

  double? idolLatitude;
  double? idolLongitude;
  double? idolGpsAccuracy;
  DateTime? idolPhotoTakenAt;

  final TextEditingController actualHeightFeetController =
      TextEditingController();
  final TextEditingController actualHeightInchesController =
      TextEditingController();

  final TextEditingController idolWidthFeetController =
      TextEditingController();
  final TextEditingController idolWidthInchesController =
      TextEditingController();

  final TextEditingController heightRemarksController =
      TextEditingController();

  final TextEditingController baseSafetyRemarksController =
      TextEditingController();

  bool officerConfirmed = false;
  bool isCapturingPhoto = false;
  bool isSaving = false;

  String errorMessage = '';
  String successMessage = '';

  String get selectedGpid {
    final value = (widget.gpid ?? widget.applicationId).trim();

    if (value.isNotEmpty) {
      return value;
    }

    return widget.applicationId;
  }

  String get applicantName {
    return (widget.ganeshRecord?['name'] ?? '-').toString();
  }

  String get associationName {
    return (widget.ganeshRecord?['association'] ?? '-').toString();
  }

  String get policeStation {
    return (widget.ganeshRecord?['ps_name'] ?? '-').toString();
  }

  String get declaredIdolHeight {
    final value = (widget.ganeshRecord?['idol_height'] ?? '')
        .toString()
        .trim();

    return value.isEmpty ? 'Not Available' : value;
  }

  String get declaredIdolWidth {
    final value = (widget.ganeshRecord?['idol_width'] ??
            widget.ganeshRecord?['width'] ??
            '')
        .toString()
        .trim();

    return value.isEmpty ? 'Not Available' : value;
  }

  bool get idolConstructedAtLocation {
    return idolBroughtFrom == 'CONSTRUCTED_AT_LOCATION';
  }

  @override
  void dispose() {
    actualHeightFeetController.dispose();
    actualHeightInchesController.dispose();
    idolWidthFeetController.dispose();
    idolWidthInchesController.dispose();
    heightRemarksController.dispose();
    baseSafetyRemarksController.dispose();
    super.dispose();
  }

  void _clearMessages() {
    setState(() {
      errorMessage = '';
      successMessage = '';
    });
  }

  Widget _yesNoButtons({
    required String value,
    required void Function(String) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () => onChanged('YES'),
            style: FilledButton.styleFrom(
              backgroundColor:
                  value == 'YES' ? Colors.green : const Color(0xFFE2E8F0),
              foregroundColor:
                  value == 'YES' ? Colors.white : Colors.black87,
            ),
            child: const Text('YES'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => onChanged('NO'),
            style: FilledButton.styleFrom(
              backgroundColor:
                  value == 'NO' ? Colors.red : const Color(0xFFE2E8F0),
              foregroundColor:
                  value == 'NO' ? Colors.white : Colors.black87,
            ),
            child: const Text('NO'),
          ),
        ),
      ],
    );
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        errorMessage =
            'Location service is OFF. Please switch ON GPS and try again.';
      });
      return null;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      setState(() {
        errorMessage =
            'Location permission is required to capture the Idol photograph.';
      });
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        errorMessage =
            'Location permission is permanently denied. Please enable it from App Settings.';
      });
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Unable to capture current GPS location.';
      });
      return null;
    }
  }

  Future<void> _takeIdolPhoto() async {
    _clearMessages();

    setState(() {
      isCapturingPhoto = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) {
        if (mounted) {
          setState(() {
            isCapturingPhoto = false;
          });
        }
        return;
      }

      final position = await _getCurrentPosition();

      if (position == null) {
        if (mounted) {
          setState(() {
            isCapturingPhoto = false;
          });
        }
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        idolImage = image;
        idolLatitude = position.latitude;
        idolLongitude = position.longitude;
        idolGpsAccuracy = position.accuracy;
        idolPhotoTakenAt = DateTime.now();
        isCapturingPhoto = false;

        successMessage =
            'Current Idol photograph and GPS location captured successfully.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isCapturingPhoto = false;
        errorMessage = 'Unable to capture Idol photograph.';
      });
    }
  }

  bool _validFeetInches({
    required String feet,
    required String inches,
  }) {
    final feetValue = double.tryParse(feet.trim());
    final inchesValue = double.tryParse(inches.trim());

    if (feetValue == null || inchesValue == null) {
      return false;
    }

    if (feetValue < 0) {
      return false;
    }

    if (inchesValue < 0 || inchesValue >= 12) {
      return false;
    }

    return true;
  }

  void _fillFeetInches(
    double valueFeet,
    TextEditingController feetController,
    TextEditingController inchesController,
  ) {
    var totalInches = (valueFeet * 12).round();
    var feet = totalInches ~/ 12;
    var inches = totalInches % 12;

    if (inches == 12) {
      feet += 1;
      inches = 0;
    }

    feetController.text = feet.toString();
    inchesController.text = inches.toString();
  }

  Future<void> _measureHeight() async {
    final result = await Navigator.push<ArMeasurementResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ArMeasurementScreen(
          applicationId: selectedGpid,
          measurementType: 'HEIGHT',
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      heightMeasurement = result;
      heightMatches = '';
      heightRecordMode = '';
      heightRemarksController.clear();
      _fillFeetInches(
        result.valueFeet,
        actualHeightFeetController,
        actualHeightInchesController,
      );
      successMessage =
          'Idol Height measurement received successfully.';
      errorMessage = '';
    });
  }

  Future<void> _measureWidth() async {
    final result = await Navigator.push<ArMeasurementResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ArMeasurementScreen(
          applicationId: selectedGpid,
          measurementType: 'WIDTH',
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      widthMeasurement = result;
      widthMatches = '';
      widthRecordMode = '';
      _fillFeetInches(
        result.valueFeet,
        idolWidthFeetController,
        idolWidthInchesController,
      );
      successMessage =
          'Idol Width measurement received successfully.';
      errorMessage = '';
    });
  }

  Map<String, dynamic>? _measurementToMap(
    ArMeasurementResult? measurement,
  ) {
    if (measurement == null) {
      return null;
    }

    return {
      'valueFeet': measurement.valueFeet,
      'valueMeters': measurement.valueMeters,
      'startX': measurement.startX,
      'startY': measurement.startY,
      'startZ': measurement.startZ,
      'endX': measurement.endX,
      'endY': measurement.endY,
      'endZ': measurement.endZ,
      'latitude': measurement.latitude,
      'longitude': measurement.longitude,
      'gpsAccuracy': measurement.gpsAccuracy,
      'measuredAt': measurement.measuredAt.toIso8601String(),
      'measurementType': measurement.measurementType,
      'measurementMethod': measurement.measurementMethod,
      'evidenceImagePath': measurement.evidenceImagePath,
    };
  }

  Map<String, dynamic> _buildResult() {
    return {
      'applicationId': widget.applicationId,
      'gpid': selectedGpid,
      'idolInstalled': idolInstalled,
      'idolBroughtFrom': idolBroughtFrom,
      'idolConstructedAtLocation': idolConstructedAtLocation,
      'idolMaterial': idolMaterial,
      'idolPhotoPath': idolImage?.path,
      'idolLatitude': idolLatitude,
      'idolLongitude': idolLongitude,
      'idolGpsAccuracy': idolGpsAccuracy,
      'idolPhotoTakenAt': idolPhotoTakenAt?.toIso8601String(),
      'declaredIdolHeight': declaredIdolHeight,
      'heightMatches': heightMatches,
      'heightRecordMode': heightRecordMode,
      'actualHeightFeet': actualHeightFeetController.text.trim(),
      'actualHeightInches': actualHeightInchesController.text.trim(),
      'heightRemarks': heightRemarksController.text.trim(),
      'heightMeasurement': _measurementToMap(heightMeasurement),
      'declaredIdolWidth': declaredIdolWidth,
      'widthMatches': widthMatches,
      'widthRecordMode': widthRecordMode,
      'idolWidthFeet': idolWidthFeetController.text.trim(),
      'idolWidthInches': idolWidthInchesController.text.trim(),
      'widthMeasurement': _measurementToMap(widthMeasurement),
      'basePlatformSafe': basePlatformSafe,
      'baseSafetyRemarks': baseSafetyRemarksController.text.trim(),
      'officerConfirmed': officerConfirmed,
      'verifiedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _returnAfterSuccessfulSave() async {
    final result = _buildResult();

    if (!mounted) {
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = '';
      successMessage = '';
    });

    try {
      await VerificationApiService.saveModuleResult(
        applicationId: widget.applicationId,
        gpid: selectedGpid,
        moduleKey: 'idolResult',
        result: result,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
        successMessage = idolInstalled == 'NO'
            ? 'Idol Verification saved successfully. Idol is recorded as Not Installed.'
            : 'Idol-Based Verification saved successfully for GPID $selectedGpid.';
      });

      await Future<void>.delayed(
        const Duration(seconds: 1),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        result,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
        successMessage = '';
        errorMessage =
            'Unable to save Idol Verification to the server. '
            'Please check the network and try again.';
      });
    }
  }

  Future<void> _saveVerification() async {
    _clearMessages();

    if (idolInstalled.isEmpty) {
      setState(() {
        errorMessage = 'Please answer Point 1 - Idol Installed?';
      });
      return;
    }

    if (!officerConfirmed) {
      setState(() {
        errorMessage =
            'Officer Confirmation is mandatory before saving.';
      });
      return;
    }

    if (idolInstalled == 'NO') {
      await _returnAfterSuccessfulSave();
      return;
    }

    if (idolBroughtFrom.isEmpty) {
      setState(() {
        errorMessage = 'Please select Point 2 - Idol Brought From.';
      });
      return;
    }

    if (idolMaterial.isEmpty) {
      setState(() {
        errorMessage = 'Please select Point 3 - Idol Making Material.';
      });
      return;
    }

    if (idolImage == null ||
        idolLatitude == null ||
        idolLongitude == null ||
        idolGpsAccuracy == null ||
        idolPhotoTakenAt == null) {
      setState(() {
        errorMessage =
            'Point 4 - Current Idol photograph with GPS is mandatory.';
      });
      return;
    }

    if (heightMeasurement == null) {
      setState(() {
        errorMessage =
            'Point 5 - Measure the actual Idol Height using the Measurement Tool.';
      });
      return;
    }

    if (heightMatches.isEmpty) {
      setState(() {
        errorMessage =
            'Please answer Point 5 - Idol Height Verification.';
      });
      return;
    }

    if (heightMatches == 'NO') {
      if (heightRecordMode.isEmpty) {
        setState(() {
          errorMessage =
              'Point 5 - Select Automatically or Manually to record the verified Idol Height.';
        });
        return;
      }

      if (!_validFeetInches(
        feet: actualHeightFeetController.text,
        inches: actualHeightInchesController.text,
      )) {
        setState(() {
          errorMessage =
              'Enter valid verified Idol Height in feet and inches. Inches must be below 12.';
        });
        return;
      }

      if (heightRemarksController.text.trim().isEmpty) {
        setState(() {
          errorMessage =
              'Height verification remarks are mandatory when the measured height does not match the declared height.';
        });
        return;
      }
    }

    if (widthMeasurement == null) {
      setState(() {
        errorMessage =
            'Point 6 - Measure the Idol Width using the Measurement Tool.';
      });
      return;
    }

    if (widthMatches.isEmpty) {
      setState(() {
        errorMessage =
            'Please answer Point 6 - Idol Width Verification.';
      });
      return;
    }

    if (widthMatches == 'NO') {
      if (widthRecordMode.isEmpty) {
        setState(() {
          errorMessage =
              'Point 6 - Select Automatically or Manually to record the verified Idol Width.';
        });
        return;
      }

      if (!_validFeetInches(
        feet: idolWidthFeetController.text,
        inches: idolWidthInchesController.text,
      )) {
        setState(() {
          errorMessage =
              'Enter valid verified Idol Width in feet and inches. Inches must be below 12.';
        });
        return;
      }
    }

    if (basePlatformSafe.isEmpty) {
      setState(() {
        errorMessage =
            'Please answer Point 7 - Idol Base / Platform Safety.';
      });
      return;
    }

    if (basePlatformSafe == 'NO' &&
        baseSafetyRemarksController.text.trim().isEmpty) {
      setState(() {
        errorMessage =
            'Base / Platform safety remarks are mandatory when the answer is NO.';
      });
      return;
    }

    await _returnAfterSuccessfulSave();
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF17365D),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Idol-Based Verification',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected GPID',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedGpid,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17365D),
                      ),
                    ),
                    const Divider(height: 24),
                    _detailRow(
                      'Applicant Name',
                      applicantName,
                    ),
                    _detailRow(
                      'Association',
                      associationName,
                    ),
                    _detailRow(
                      'Police Station',
                      policeStation,
                    ),
                    _detailRow(
                      'Declared Height',
                      declaredIdolHeight,
                    ),
                    _detailRow(
                      'Declared Width',
                      declaredIdolWidth,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle(
                      'Point 1 - Idol Installed?',
                    ),
                    const SizedBox(height: 14),
                    _yesNoButtons(
                      value: idolInstalled,
                      onChanged: (value) {
                        setState(() {
                          idolInstalled = value;

                          if (value == 'NO') {
                            idolBroughtFrom = '';
                            idolMaterial = '';
                            idolImage = null;
                            idolLatitude = null;
                            idolLongitude = null;
                            idolGpsAccuracy = null;
                            idolPhotoTakenAt = null;
                            heightMatches = '';
                            widthMatches = '';
                            heightRecordMode = '';
                            widthRecordMode = '';
                            heightMeasurement = null;
                            widthMeasurement = null;
                            actualHeightFeetController.clear();
                            actualHeightInchesController.clear();
                            heightRemarksController.clear();
                            idolWidthFeetController.clear();
                            idolWidthInchesController.clear();
                            basePlatformSafe = '';
                            baseSafetyRemarksController.clear();
                          }
                        });
                      },
                    ),
                    if (idolInstalled == 'NO') ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Idol is not installed. Remaining Idol verification points are not required.',
                          style: TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (idolInstalled == 'YES') ...[
              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle(
                        'Point 2 - Idol Brought From',
                      ),
                      const SizedBox(height: 14),
                      RadioGroup<String>(
                        groupValue: idolBroughtFrom,
                        onChanged: (value) {
                          setState(() {
                            idolBroughtFrom = value ?? '';
                          });
                        },
                        child: const Column(
                          children: [
                            RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Outside'),
                              value: 'OUTSIDE',
                            ),
                            RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Constructed at Location',
                              ),
                              value: 'CONSTRUCTED_AT_LOCATION',
                            ),
                          ],
                        ),
                      ),
                      if (idolConstructedAtLocation) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFED7AA),
                            ),
                          ),
                          child: const Text(
                            'Route-Based Verification will require confirmation whether the procession route has been verified for this Idol.',
                            style: TextStyle(
                              color: Color(0xFF9A3412),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle(
                        'Point 3 - Idol Making Material',
                      ),
                      const SizedBox(height: 14),
                      RadioGroup<String>(
                        groupValue: idolMaterial,
                        onChanged: (value) {
                          setState(() {
                            idolMaterial = value ?? '';
                          });
                        },
                        child: const Column(
                          children: [
                            RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'POP (Plaster of Paris)',
                              ),
                              value: 'POP',
                            ),
                            RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Clay'),
                              value: 'CLAY',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle(
                        'Point 4 - Take Current Photograph of Idol',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Photograph must be taken directly through the mobile camera. Current GPS location, accuracy and date/time will be captured automatically.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 14),

                      FilledButton.icon(
                        onPressed:
                            isCapturingPhoto ? null : _takeIdolPhoto,
                        icon: isCapturingPhoto
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_outlined,
                              ),
                        label: Text(
                          isCapturingPhoto
                              ? 'Capturing...'
                              : idolImage == null
                                  ? 'OPEN CAMERA'
                                  : 'RETAKE IDOL PHOTO',
                        ),
                      ),

                      if (idolImage != null) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(idolImage!.path),
                            height: 280,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _detailRow(
                          'Latitude',
                          idolLatitude?.toStringAsFixed(6) ?? '-',
                        ),
                        _detailRow(
                          'Longitude',
                          idolLongitude?.toStringAsFixed(6) ?? '-',
                        ),
                        _detailRow(
                          'GPS Accuracy',
                          idolGpsAccuracy == null
                              ? '-'
                              : '+/-${idolGpsAccuracy!.toStringAsFixed(1)} m',
                        ),
                        _detailRow(
                          'Date & Time',
                          idolPhotoTakenAt?.toLocal().toString() ?? '-',
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle(
                        'Point 5 - Idol Height Verification',
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Declared Idol Height',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            Text(
                              declaredIdolHeight,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF17365D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _measureHeight,
                        icon: const Icon(Icons.straighten),
                        label: Text(
                          heightMeasurement == null
                              ? 'MEASURE IDOL HEIGHT'
                              : 'RE-MEASURE IDOL HEIGHT',
                        ),
                      ),
                      if (heightMeasurement != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Digitally Measured Idol Height',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF166534),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${actualHeightFeetController.text} ft '
                                '${actualHeightInchesController.text} in',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${heightMeasurement!.valueMeters.toStringAsFixed(3)} metres',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Does the measured height approximately match the declared height?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _yesNoButtons(
                          value: heightMatches,
                          onChanged: (value) {
                            setState(() {
                              heightMatches = value;
                              heightRecordMode = '';
                              heightRemarksController.clear();

                              if (value == 'YES') {
                                actualHeightFeetController.clear();
                                actualHeightInchesController.clear();
                              } else if (heightMeasurement != null) {
                                _fillFeetInches(
                                  heightMeasurement!.valueFeet,
                                  actualHeightFeetController,
                                  actualHeightInchesController,
                                );
                              }
                            });
                          },
                        ),
                        if (heightMatches == 'YES') ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Declared Height ($declaredIdolHeight) will be used as the final Idol Height for further reference.',
                              style: const TextStyle(
                                color: Color(0xFF1D4ED8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (heightMatches == 'NO') ...[
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue:
                                heightRecordMode.isEmpty ? null : heightRecordMode,
                            decoration: const InputDecoration(
                              labelText: 'Record Verified Height *',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'AUTOMATICALLY',
                                child: Text('Automatically'),
                              ),
                              DropdownMenuItem(
                                value: 'MANUALLY',
                                child: Text('Manually'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                heightRecordMode = value ?? '';

                                if (heightRecordMode == 'AUTOMATICALLY' &&
                                    heightMeasurement != null) {
                                  _fillFeetInches(
                                    heightMeasurement!.valueFeet,
                                    actualHeightFeetController,
                                    actualHeightInchesController,
                                  );
                                } else if (heightRecordMode == 'MANUALLY') {
                                  actualHeightFeetController.clear();
                                  actualHeightInchesController.clear();
                                }
                              });
                            },
                          ),
                          if (heightRecordMode.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: actualHeightFeetController,
                                    readOnly:
                                        heightRecordMode == 'AUTOMATICALLY',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Feet',
                                      border: const OutlineInputBorder(),
                                      filled:
                                          heightRecordMode == 'AUTOMATICALLY',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: actualHeightInchesController,
                                    readOnly:
                                        heightRecordMode == 'AUTOMATICALLY',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Inches',
                                      border: const OutlineInputBorder(),
                                      filled:
                                          heightRecordMode == 'AUTOMATICALLY',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          TextField(
                            controller: heightRemarksController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Remarks *',
                              hintText:
                                  'Enter reason / difference in Idol height',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle(
                        'Point 6 - Idol Width Verification',
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Declared Idol Width',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            Text(
                              declaredIdolWidth,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF17365D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _measureWidth,
                        icon: const Icon(Icons.straighten),
                        label: Text(
                          widthMeasurement == null
                              ? 'MEASURE IDOL WIDTH'
                              : 'RE-MEASURE IDOL WIDTH',
                        ),
                      ),
                      if (widthMeasurement != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Digitally Measured Idol Width',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF166534),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${idolWidthFeetController.text} ft '
                                '${idolWidthInchesController.text} in',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widthMeasurement!.valueMeters.toStringAsFixed(3)} metres',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Does the measured width approximately match the declared width?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _yesNoButtons(
                          value: widthMatches,
                          onChanged: (value) {
                            setState(() {
                              widthMatches = value;
                              widthRecordMode = '';

                              if (value == 'YES') {
                                idolWidthFeetController.clear();
                                idolWidthInchesController.clear();
                              } else if (widthMeasurement != null) {
                                _fillFeetInches(
                                  widthMeasurement!.valueFeet,
                                  idolWidthFeetController,
                                  idolWidthInchesController,
                                );
                              }
                            });
                          },
                        ),
                        if (widthMatches == 'YES') ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Declared Width ($declaredIdolWidth) will be used as the final Idol Width for further reference.',
                              style: const TextStyle(
                                color: Color(0xFF1D4ED8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (widthMatches == 'NO') ...[
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue:
                                widthRecordMode.isEmpty ? null : widthRecordMode,
                            decoration: const InputDecoration(
                              labelText: 'Record Verified Width *',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'AUTOMATICALLY',
                                child: Text('Automatically'),
                              ),
                              DropdownMenuItem(
                                value: 'MANUALLY',
                                child: Text('Manually'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                widthRecordMode = value ?? '';

                                if (widthRecordMode == 'AUTOMATICALLY' &&
                                    widthMeasurement != null) {
                                  _fillFeetInches(
                                    widthMeasurement!.valueFeet,
                                    idolWidthFeetController,
                                    idolWidthInchesController,
                                  );
                                } else if (widthRecordMode == 'MANUALLY') {
                                  idolWidthFeetController.clear();
                                  idolWidthInchesController.clear();
                                }
                              });
                            },
                          ),
                          if (widthRecordMode.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: idolWidthFeetController,
                                    readOnly:
                                        widthRecordMode == 'AUTOMATICALLY',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Feet',
                                      border: const OutlineInputBorder(),
                                      filled:
                                          widthRecordMode == 'AUTOMATICALLY',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: idolWidthInchesController,
                                    readOnly:
                                        widthRecordMode == 'AUTOMATICALLY',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Inches',
                                      border: const OutlineInputBorder(),
                                      filled:
                                          widthRecordMode == 'AUTOMATICALLY',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle(
                        'Point 7 - Idol Base / Platform Safety',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Is the Base / Platform on which the Idol is installed stable and safe?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _yesNoButtons(
                        value: basePlatformSafe,
                        onChanged: (value) {
                          setState(() {
                            basePlatformSafe = value;

                            if (value == 'YES') {
                              baseSafetyRemarksController.clear();
                            }
                          });
                        },
                      ),
                      if (basePlatformSafe == 'NO') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: baseSafetyRemarksController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText:
                                'Remarks / Details of Safety Issue *',
                            hintText:
                                'Enter details of the unsafe base / platform',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity:
                      ListTileControlAffinity.leading,
                  value: officerConfirmed,
                  onChanged: (value) {
                    setState(() {
                      officerConfirmed = value ?? false;
                    });
                  },
                  title: Text(
                    idolInstalled == 'NO'
                        ? 'Point 2 - Officer Confirmation'
                        : 'Point 8 - Officer Confirmation',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF17365D),
                    ),
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'I have personally verified the Idol and confirm that the above information is correct.',
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            if (successMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  successMessage,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed:
                        isSaving ? null : _saveVerification,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.verified_outlined,
                          ),
                    label: Text(
                      isSaving
                          ? 'SAVING...'
                          : 'CONFIRM & SAVE',
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