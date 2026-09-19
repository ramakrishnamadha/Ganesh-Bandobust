import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/verification_api_service.dart';

class MandapVerificationScreen extends StatefulWidget {
  final String applicationId;
  final String? gpid;
  final Map<String, dynamic>? ganeshRecord;

  const MandapVerificationScreen({
    super.key,
    required this.applicationId,
    this.gpid,
    this.ganeshRecord,
  });

  @override
  State<MandapVerificationScreen> createState() =>
      _MandapVerificationScreenState();
}

class _MandapVerificationScreenState
    extends State<MandapVerificationScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  // Point 1
  String mandapInstalled = '';
  String mandapNotInstalledRemarks = '';

  // Point 2
  String structuralStability = '';
  String structuralRemarks = '';

  // Point 3
  String roadObstruction = '';

  // Point 4
  String obstructionType = '';
  String otherObstruction = '';
  String trafficImpact = '';
  String roadWidth = '';

  // Point 5
  String emergencyAccess = '';
  String emergencyRemarks = '';

  // Point 6
  String overheadWires = '';
  String overheadWiresRisk = '';
  String overheadWiresRemarks = '';
  XFile? overheadWiresPhoto;

  // Point 7
  String electricalHazard = '';
  String electricalHazardType = '';
  String otherElectricalHazard = '';
  String electricalHazardRisk = '';
  String electricalHazardRemarks = '';
  XFile? electricalHazardPhoto;

  // Point 8
  String mandapHeightVerified = '';
  String actualMandapHeight = '';
  String mandapHeightRemarks = '';

  // Point 9
  XFile? mandapPhoto;
  double? mandapPhotoLatitude;
  double? mandapPhotoLongitude;
  double? mandapPhotoAccuracy;
  DateTime? mandapPhotoDateTime;

  // Point 10
  bool officerConfirmation = false;

  String errorMessage = '';
  String successMessage = '';
  bool capturingLocation = false;
  bool saving = false;

  String _recordText(String key) {
    final value = widget.ganeshRecord?[key];

    if (value == null) return '-';

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '-';
    }

    return text;
  }

  String get selectedGpid {
    final gpid = widget.gpid?.trim() ?? '';

    if (gpid.isNotEmpty) {
      return gpid;
    }

    final apiGpid = _recordText('unique_id');

    if (apiGpid != '-') {
      return apiGpid;
    }

    return widget.applicationId;
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        errorMessage =
            'Please enable Location / GPS on the mobile and try again.';
      });
      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      setState(() {
        errorMessage =
            'Location permission is required.';
      });
      return false;
    }

    if (permission ==
        LocationPermission.deniedForever) {
      setState(() {
        errorMessage =
            'Location permission is permanently denied. Please enable it from App Settings.';
      });
      return false;
    }

    return true;
  }

  Future<void> _takeOverheadWiresPhoto() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 80,
    );

    if (photo == null) return;

    setState(() {
      overheadWiresPhoto = photo;
      errorMessage = '';
    });
  }

  Future<void> _takeElectricalHazardPhoto() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 80,
    );

    if (photo == null) return;

    setState(() {
      electricalHazardPhoto = photo;
      errorMessage = '';
    });
  }

  Future<void> _takeMandapPhoto() async {
    setState(() {
      errorMessage = '';
      successMessage = '';
    });

    final permissionGranted =
        await _ensureLocationPermission();

    if (!permissionGranted) return;

    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 80,
    );

    if (photo == null) return;

    setState(() {
      capturingLocation = true;
    });

    try {
      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        mandapPhoto = photo;
        mandapPhotoLatitude = position.latitude;
        mandapPhotoLongitude = position.longitude;
        mandapPhotoAccuracy = position.accuracy;
        mandapPhotoDateTime = DateTime.now();
        capturingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        capturingLocation = false;
        errorMessage =
            'Unable to capture GPS location. Please try again.';
      });
    }
  }

  void _clearAfterMandapInstalledNo() {
    structuralStability = '';
    structuralRemarks = '';

    roadObstruction = '';
    obstructionType = '';
    otherObstruction = '';
    trafficImpact = '';
    roadWidth = '';

    emergencyAccess = '';
    emergencyRemarks = '';

    overheadWires = '';
    overheadWiresRisk = '';
    overheadWiresRemarks = '';
    overheadWiresPhoto = null;

    electricalHazard = '';
    electricalHazardType = '';
    otherElectricalHazard = '';
    electricalHazardRisk = '';
    electricalHazardRemarks = '';
    electricalHazardPhoto = null;

    mandapHeightVerified = '';
    actualMandapHeight = '';
    mandapHeightRemarks = '';

    mandapPhoto = null;
    mandapPhotoLatitude = null;
    mandapPhotoLongitude = null;
    mandapPhotoAccuracy = null;
    mandapPhotoDateTime = null;

    officerConfirmation = false;
  }

  Future<void> _returnAfterSuccessfulSave(
    Map<String, dynamic> result,
  ) async {
    if (!mounted) return;

    setState(() {
      saving = true;
      errorMessage = '';
      successMessage = '';
    });

    try {
      await VerificationApiService.saveModuleResult(
        applicationId: widget.applicationId,
        gpid: selectedGpid,
        moduleKey: 'mandapResult',
        result: result,
      );

      if (!mounted) return;

      setState(() {
        saving = false;
        successMessage =
            'Mandap-Based Verification saved successfully for GPID $selectedGpid.';
      });

      await Future<void>.delayed(
        const Duration(seconds: 1),
      );

      if (!mounted) return;

      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
        successMessage = '';
        errorMessage =
            'Unable to save Mandap Verification to the server. '
            'Please check the network and try again.';
      });
    }
  }

  Future<void> _saveVerification() async {
    setState(() {
      errorMessage = '';
      successMessage = '';
    });

    // Point 1
    if (mandapInstalled.isEmpty) {
      _showError(
        'Please answer Point 1: Mandap Installed?',
      );
      return;
    }

    if (mandapInstalled == 'NO') {
      if (mandapNotInstalledRemarks.trim().isEmpty) {
        _showError(
          'Remarks / Reason are mandatory when Mandap Installed is NO.',
        );
        return;
      }

      final result = <String, dynamic>{
        'applicationId': widget.applicationId,
        'gpid': selectedGpid,
        'mandapInstalled': 'NO',
        'mandapNotInstalledRemarks':
            mandapNotInstalledRemarks.trim(),
        'verifiedAt': DateTime.now().toIso8601String(),
      };

      await _returnAfterSuccessfulSave(result);
      return;
    }

    // Point 2
    if (structuralStability.isEmpty) {
      _showError(
        'Please answer Point 2: Structural Stability of Mandap Verified?',
      );
      return;
    }

    if (structuralStability == 'NO' &&
        structuralRemarks.trim().isEmpty) {
      _showError(
        'Remarks / Reason are mandatory when Structural Stability is NO.',
      );
      return;
    }

    // Point 3
    if (roadObstruction.isEmpty) {
      _showError(
        'Please answer Point 3: Does the Mandap Cause Any Road Block / Obstruction from Traffic Point of View?',
      );
      return;
    }

    // Point 4
    if (roadObstruction == 'YES') {
      if (obstructionType.isEmpty) {
        _showError(
          'Please select Nature of Road Block / Obstruction.',
        );
        return;
      }

      if (obstructionType == 'OTHER' &&
          otherObstruction.trim().isEmpty) {
        _showError(
          'Please specify the Other Obstruction.',
        );
        return;
      }

      if (trafficImpact.isEmpty) {
        _showError(
          'Please select Impact on Traffic.',
        );
        return;
      }

      if (roadWidth.trim().isEmpty) {
        _showError(
          'Please enter Available Road Width in feet.',
        );
        return;
      }
    }

    // Point 5
    if (emergencyAccess.isEmpty) {
      _showError(
        'Please answer Point 5: Access for Emergency Vehicles Available?',
      );
      return;
    }

    if (emergencyAccess == 'NO' &&
        emergencyRemarks.trim().isEmpty) {
      _showError(
        'Remarks / Reason are mandatory when Emergency Vehicle Access is NO.',
      );
      return;
    }

    // Point 6
    if (overheadWires.isEmpty) {
      _showError(
        'Please answer Point 6: Are Overhead Electrical Wires Present Above / Near the Mandap?',
      );
      return;
    }

    if (overheadWires == 'YES') {
      if (overheadWiresRisk.isEmpty) {
        _showError(
          'Please answer whether the Overhead Electrical Wires pose a safety risk.',
        );
        return;
      }

      if (overheadWiresRisk == 'YES') {
        if (overheadWiresPhoto == null) {
          _showError(
            'Photo is mandatory when Overhead Electrical Wires pose a safety risk.',
          );
          return;
        }

        if (overheadWiresRemarks.trim().isEmpty) {
          _showError(
            'Remarks / Risk Details are mandatory for risky Overhead Electrical Wires.',
          );
          return;
        }
      }
    }

    // Point 7
    if (electricalHazard.isEmpty) {
      _showError(
        'Please answer Point 7: Is there any Electrical Hazard near the Mandap?',
      );
      return;
    }

    if (electricalHazard == 'YES') {
      if (electricalHazardType.isEmpty) {
        _showError(
          'Please select the Type of Electrical Hazard.',
        );
        return;
      }

      if (electricalHazardType == 'OTHER' &&
          otherElectricalHazard.trim().isEmpty) {
        _showError(
          'Please specify the Other Electrical Hazard.',
        );
        return;
      }

      if (electricalHazardRisk.isEmpty) {
        _showError(
          'Please answer whether the Electrical Hazard poses a safety risk to the Mandap / Public.',
        );
        return;
      }

      if (electricalHazardRisk == 'YES') {
        if (electricalHazardPhoto == null) {
          _showError(
            'Photo is mandatory when the Electrical Hazard poses a safety risk.',
          );
          return;
        }

        if (electricalHazardRemarks.trim().isEmpty) {
          _showError(
            'Remarks / Risk Details are mandatory for the Electrical Hazard.',
          );
          return;
        }
      }
    }

    // Point 8
    if (mandapHeightVerified.isEmpty) {
      _showError(
        'Please answer Point 8: Is the Actual Mandap Height approximately as declared in the Application?',
      );
      return;
    }

    if (mandapHeightVerified == 'NO') {
      if (actualMandapHeight.trim().isEmpty) {
        _showError(
          'Please enter Actual Approximate Mandap Height.',
        );
        return;
      }

      if (mandapHeightRemarks.trim().isEmpty) {
        _showError(
          'Remarks are mandatory when the Mandap Height does not match the declared height.',
        );
        return;
      }
    }

    // Point 9
    if (mandapPhoto == null ||
        mandapPhotoLatitude == null ||
        mandapPhotoLongitude == null ||
        mandapPhotoDateTime == null) {
      _showError(
        'Point 9: Current Mandap Photograph with GPS location is mandatory.',
      );
      return;
    }

    // Point 10
    if (!officerConfirmation) {
      _showError(
        'Please confirm that you have personally verified the Mandap.',
      );
      return;
    }

    final result = <String, dynamic>{
      'applicationId': widget.applicationId,
      'gpid': selectedGpid,
      'mandapInstalled': mandapInstalled,
      'mandapNotInstalledRemarks':
          mandapNotInstalledRemarks.trim(),
      'structuralStability': structuralStability,
      'structuralRemarks': structuralRemarks.trim(),
      'roadObstruction': roadObstruction,
      'obstructionType':
          roadObstruction == 'YES' ? obstructionType : null,
      'otherObstruction':
          roadObstruction == 'YES' && obstructionType == 'OTHER'
              ? otherObstruction.trim()
              : null,
      'trafficImpact':
          roadObstruction == 'YES' ? trafficImpact : null,
      'roadWidth':
          roadObstruction == 'YES' ? roadWidth.trim() : null,
      'emergencyAccess': emergencyAccess,
      'emergencyRemarks': emergencyRemarks.trim(),
      'overheadWires': overheadWires,
      'overheadWiresRisk':
          overheadWires == 'YES' ? overheadWiresRisk : null,
      'overheadWiresRemarks': overheadWiresRemarks.trim(),
      'overheadWiresPhotoPath': overheadWiresPhoto?.path,
      'electricalHazard': electricalHazard,
      'electricalHazardType':
          electricalHazard == 'YES' ? electricalHazardType : null,
      'otherElectricalHazard':
          electricalHazard == 'YES' && electricalHazardType == 'OTHER'
              ? otherElectricalHazard.trim()
              : null,
      'electricalHazardRisk':
          electricalHazard == 'YES' ? electricalHazardRisk : null,
      'electricalHazardRemarks': electricalHazardRemarks.trim(),
      'electricalHazardPhotoPath': electricalHazardPhoto?.path,
      'mandapHeightVerified': mandapHeightVerified,
      'declaredMandapHeight': _recordText('pendal_height'),
      'actualMandapHeight':
          mandapHeightVerified == 'NO' ? actualMandapHeight.trim() : null,
      'mandapHeightRemarks': mandapHeightRemarks.trim(),
      'mandapPhotoPath': mandapPhoto?.path,
      'mandapPhotoEvidence': {
        'latitude': mandapPhotoLatitude,
        'longitude': mandapPhotoLongitude,
        'accuracy': mandapPhotoAccuracy,
        'capturedAt': mandapPhotoDateTime?.toIso8601String(),
      },
      'officerConfirmation': officerConfirmation,
      'verifiedAt': DateTime.now().toIso8601String(),
    };

    await _returnAfterSuccessfulSave(result);
  }

  void _showError(String message) {
    setState(() {
      errorMessage = message;
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
              backgroundColor: value == 'YES'
                  ? Colors.green
                  : const Color(0xFFE2E8F0),
              foregroundColor: value == 'YES'
                  ? Colors.white
                  : Colors.black87,
            ),
            child: const Text('YES'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => onChanged('NO'),
            style: FilledButton.styleFrom(
              backgroundColor: value == 'NO'
                  ? Colors.red
                  : const Color(0xFFE2E8F0),
              foregroundColor: value == 'NO'
                  ? Colors.white
                  : Colors.black87,
            ),
            child: const Text('NO'),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String point,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              point,
              style: const TextStyle(
                color: Color(0xFF17365D),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _remarksField({
    required String label,
    required void Function(String) onChanged,
  }) {
    return TextField(
      maxLines: 3,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _photoPreview(XFile photo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        File(photo.path),
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final declaredMandapHeight =
        _recordText('pendal_height');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mandap-Based Verification',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected GPID',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      selectedGpid,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17365D),
                      ),
                    ),
                    const Divider(height: 26),
                    _detailRow(
                      'Applicant Name',
                      _recordText('name'),
                    ),
                    const SizedBox(height: 10),
                    _detailRow(
                      'Association / Organisation',
                      _recordText('association'),
                    ),
                    const SizedBox(height: 10),
                    _detailRow(
                      'Police Station',
                      _recordText('ps_name'),
                    ),
                    const SizedBox(height: 10),
                    _detailRow(
                      'Declared Mandap Height',
                      declaredMandapHeight == '-'
                          ? '-'
                          : '$declaredMandapHeight ft.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            _sectionCard(
              point: 'Point 1',
              title: 'Mandap Installed?',
              children: [
                _yesNoButtons(
                  value: mandapInstalled,
                  onChanged: (value) {
                    setState(() {
                      mandapInstalled = value;
                      errorMessage = '';
                      successMessage = '';

                      if (value == 'NO') {
                        _clearAfterMandapInstalledNo();
                      } else {
                        mandapNotInstalledRemarks = '';
                      }
                    });
                  },
                ),
                if (mandapInstalled == 'NO') ...[
                  const SizedBox(height: 16),
                  _remarksField(
                    label: 'Remarks / Reason *',
                    onChanged: (value) {
                      mandapNotInstalledRemarks =
                          value;
                    },
                  ),
                ],
              ],
            ),

            if (mandapInstalled == 'YES') ...[
              const SizedBox(height: 14),

              _sectionCard(
                point: 'Point 2',
                title:
                    'Structural Stability of Mandap Verified?',
                children: [
                  _yesNoButtons(
                    value: structuralStability,
                    onChanged: (value) {
                      setState(() {
                        structuralStability =
                            value;

                        if (value == 'YES') {
                          structuralRemarks = '';
                        }
                      });
                    },
                  ),
                  if (structuralStability ==
                      'NO') ...[
                    const SizedBox(height: 16),
                    _remarksField(
                      label:
                          'Remarks / Reason *',
                      onChanged: (value) {
                        structuralRemarks =
                            value;
                      },
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                point: 'Point 3',
                title:
                    'Does the Mandap Cause Any Road Block / Obstruction from Traffic Point of View?',
                children: [
                  _yesNoButtons(
                    value: roadObstruction,
                    onChanged: (value) {
                      setState(() {
                        roadObstruction = value;

                        if (value == 'NO') {
                          obstructionType = '';
                          otherObstruction = '';
                          trafficImpact = '';
                          roadWidth = '';
                        }
                      });
                    },
                  ),
                ],
              ),

              if (roadObstruction == 'YES') ...[
                const SizedBox(height: 14),

                _sectionCard(
                  point: 'Point 4',
                  title:
                      'Nature of Road Obstruction',
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue:
                          obstructionType.isEmpty
                              ? null
                              : obstructionType,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Nature of Road Block / Obstruction *',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'PART_ROAD',
                          child: Text(
                            'Mandap occupying part of road',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'FULL_ROAD',
                          child: Text(
                            'Mandap occupying full road',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'BARRICADING',
                          child:
                              Text('Barricading'),
                        ),
                        DropdownMenuItem(
                          value: 'PARKING',
                          child: Text(
                            'Parking-related obstruction',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ENTRY_EXIT',
                          child: Text(
                            'Entry / Exit arrangement causing obstruction',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'OTHER',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          obstructionType =
                              value ?? '';

                          if (obstructionType !=
                              'OTHER') {
                            otherObstruction =
                                '';
                          }
                        });
                      },
                    ),

                    if (obstructionType ==
                        'OTHER') ...[
                      const SizedBox(height: 16),

                      TextField(
                        onChanged: (value) {
                          otherObstruction =
                              value;
                        },
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Specify Obstruction *',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue:
                          trafficImpact.isEmpty
                              ? null
                              : trafficImpact,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Impact on Traffic *',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'LOW',
                          child: Text('Low'),
                        ),
                        DropdownMenuItem(
                          value: 'MODERATE',
                          child:
                              Text('Moderate'),
                        ),
                        DropdownMenuItem(
                          value: 'HIGH',
                          child: Text('High'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          trafficImpact =
                              value ?? '';
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        roadWidth = value;
                      },
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Available Road Width (ft.) *',
                        hintText: 'Example: 20',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              _sectionCard(
                point: 'Point 5',
                title:
                    'Access for Emergency Vehicles Available?',
                children: [
                  _yesNoButtons(
                    value: emergencyAccess,
                    onChanged: (value) {
                      setState(() {
                        emergencyAccess = value;

                        if (value == 'YES') {
                          emergencyRemarks = '';
                        }
                      });
                    },
                  ),
                  if (emergencyAccess == 'NO') ...[
                    const SizedBox(height: 16),
                    _remarksField(
                      label:
                          'Remarks / Reason *',
                      onChanged: (value) {
                        emergencyRemarks =
                            value;
                      },
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                point: 'Point 6',
                title:
                    'Are Overhead Electrical Wires Present Above / Near the Mandap?',
                children: [
                  _yesNoButtons(
                    value: overheadWires,
                    onChanged: (value) {
                      setState(() {
                        overheadWires = value;

                        if (value == 'NO') {
                          overheadWiresRisk = '';
                          overheadWiresRemarks =
                              '';
                          overheadWiresPhoto =
                              null;
                        }
                      });
                    },
                  ),

                  if (overheadWires == 'YES') ...[
                    const SizedBox(height: 20),

                    const Text(
                      'Do the Overhead Electrical Wires Pose a Safety Risk to the Mandap?',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _yesNoButtons(
                      value: overheadWiresRisk,
                      onChanged: (value) {
                        setState(() {
                          overheadWiresRisk =
                              value;

                          if (value == 'NO') {
                            overheadWiresRemarks =
                                '';
                            overheadWiresPhoto =
                                null;
                          }
                        });
                      },
                    ),

                    if (overheadWiresRisk ==
                        'YES') ...[
                      const SizedBox(height: 16),

                      OutlinedButton.icon(
                        onPressed:
                            _takeOverheadWiresPhoto,
                        icon: const Icon(
                          Icons
                              .camera_alt_outlined,
                        ),
                        label: Text(
                          overheadWiresPhoto ==
                                  null
                              ? 'Take Risk Photo *'
                              : 'Retake Risk Photo',
                        ),
                      ),

                      if (overheadWiresPhoto !=
                          null) ...[
                        const SizedBox(height: 12),
                        _photoPreview(
                          overheadWiresPhoto!,
                        ),
                      ],

                      const SizedBox(height: 16),

                      _remarksField(
                        label:
                            'Remarks / Risk Details *',
                        onChanged: (value) {
                          overheadWiresRemarks =
                              value;
                        },
                      ),
                    ],
                  ],
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                point: 'Point 7',
                title:
                    'Is there any Electrical Hazard near the Mandap?',
                children: [
                  const Text(
                    'Transformer / Electrical Pole / Distribution Box / High-Tension Equipment / Other Electrical Hazard',
                    style: TextStyle(
                      color:
                          Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 14),

                  _yesNoButtons(
                    value: electricalHazard,
                    onChanged: (value) {
                      setState(() {
                        electricalHazard =
                            value;

                        if (value == 'NO') {
                          electricalHazardType =
                              '';
                          otherElectricalHazard =
                              '';
                          electricalHazardRisk =
                              '';
                          electricalHazardRemarks =
                              '';
                          electricalHazardPhoto =
                              null;
                        }
                      });
                    },
                  ),

                  if (electricalHazard ==
                      'YES') ...[
                    const SizedBox(height: 18),

                    DropdownButtonFormField<String>(
                      initialValue:
                          electricalHazardType
                                  .isEmpty
                              ? null
                              : electricalHazardType,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Type of Electrical Hazard *',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'TRANSFORMER',
                          child: Text(
                            'Transformer',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'ELECTRICAL_POLE',
                          child: Text(
                            'Electrical Pole',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'DISTRIBUTION_BOX',
                          child: Text(
                            'Distribution Box',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'HT_EQUIPMENT',
                          child: Text(
                            'High-Tension Electrical Equipment',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'OTHER',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          electricalHazardType =
                              value ?? '';

                          if (electricalHazardType !=
                              'OTHER') {
                            otherElectricalHazard =
                                '';
                          }
                        });
                      },
                    ),

                    if (electricalHazardType ==
                        'OTHER') ...[
                      const SizedBox(height: 16),

                      TextField(
                        onChanged: (value) {
                          otherElectricalHazard =
                              value;
                        },
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Specify Hazard *',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    const Text(
                      'Does it Pose a Safety Risk to the Mandap / Public?',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _yesNoButtons(
                      value:
                          electricalHazardRisk,
                      onChanged: (value) {
                        setState(() {
                          electricalHazardRisk =
                              value;

                          if (value == 'NO') {
                            electricalHazardRemarks =
                                '';
                            electricalHazardPhoto =
                                null;
                          }
                        });
                      },
                    ),

                    if (electricalHazardRisk ==
                        'YES') ...[
                      const SizedBox(height: 16),

                      OutlinedButton.icon(
                        onPressed:
                            _takeElectricalHazardPhoto,
                        icon: const Icon(
                          Icons
                              .camera_alt_outlined,
                        ),
                        label: Text(
                          electricalHazardPhoto ==
                                  null
                              ? 'Take Hazard Photo *'
                              : 'Retake Hazard Photo',
                        ),
                      ),

                      if (electricalHazardPhoto !=
                          null) ...[
                        const SizedBox(height: 12),
                        _photoPreview(
                          electricalHazardPhoto!,
                        ),
                      ],

                      const SizedBox(height: 16),

                      _remarksField(
                        label:
                            'Remarks / Risk Details *',
                        onChanged: (value) {
                          electricalHazardRemarks =
                              value;
                        },
                      ),
                    ],
                  ],
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                point: 'Point 8',
                title:
                    'Mandap Height Verification',
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFF1F5F9),
                      borderRadius:
                          BorderRadius.circular(
                              10),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Declared Mandap Height',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                        Text(
                          declaredMandapHeight ==
                                  '-'
                              ? '-'
                              : '$declaredMandapHeight ft.',
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: Color(
                              0xFF17365D,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Is the Actual Mandap Height approximately as declared in the Application?',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _yesNoButtons(
                    value:
                        mandapHeightVerified,
                    onChanged: (value) {
                      setState(() {
                        mandapHeightVerified =
                            value;

                        if (value == 'YES') {
                          actualMandapHeight =
                              '';
                          mandapHeightRemarks =
                              '';
                        }
                      });
                    },
                  ),

                  if (mandapHeightVerified ==
                      'NO') ...[
                    const SizedBox(height: 16),

                    TextField(
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        actualMandapHeight =
                            value;
                      },
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Actual Approximate Mandap Height (ft.) *',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _remarksField(
                      label: 'Remarks *',
                      onChanged: (value) {
                        mandapHeightRemarks =
                            value;
                      },
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                point: 'Point 9',
                title:
                    'Take Current Photograph of Mandap',
                children: [
                  const Text(
                    'Photograph, current GPS coordinates and date/time will be recorded as field-verification evidence.',
                    style: TextStyle(
                      color:
                          Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 14),

                  FilledButton.icon(
                    onPressed: capturingLocation
                        ? null
                        : _takeMandapPhoto,
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                    ),
                    label: Text(
                      capturingLocation
                          ? 'Capturing GPS...'
                          : mandapPhoto == null
                              ? 'Take Mandap Photograph *'
                              : 'Retake Mandap Photograph',
                    ),
                  ),

                  if (mandapPhoto != null) ...[
                    const SizedBox(height: 14),

                    _photoPreview(mandapPhoto!),

                    const SizedBox(height: 14),

                    Container(
                      padding:
                          const EdgeInsets.all(
                              12),
                      decoration: BoxDecoration(
                        color:
                            const Color(
                                0xFFF1F5F9),
                        borderRadius:
                            BorderRadius.circular(
                                10),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Latitude: ${mandapPhotoLatitude?.toStringAsFixed(6) ?? '-'}',
                          ),
                          const SizedBox(
                              height: 5),
                          Text(
                            'Longitude: ${mandapPhotoLongitude?.toStringAsFixed(6) ?? '-'}',
                          ),
                          const SizedBox(
                              height: 5),
                          Text(
                            'Accuracy: ${mandapPhotoAccuracy?.toStringAsFixed(1) ?? '-'} m',
                          ),
                          const SizedBox(
                              height: 5),
                          Text(
                            'Date & Time: ${mandapPhotoDateTime?.toLocal().toString() ?? '-'}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                point: 'Point 10',
                title:
                    'Officer Confirmation',
                children: [
                  CheckboxListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    controlAffinity:
                        ListTileControlAffinity
                            .leading,
                    value:
                        officerConfirmation,
                    onChanged: (value) {
                      setState(() {
                        officerConfirmation =
                            value ?? false;
                      });
                    },
                    title: const Text(
                      'I have personally verified the Mandap and confirm that the above information is correct.',
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            if (errorMessage.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.all(12),
                margin:
                    const EdgeInsets.only(
                        bottom: 12),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFEE2E2),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

            if (successMessage.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.all(12),
                margin:
                    const EdgeInsets.only(
                        bottom: 12),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFDCFCE7),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Text(
                  successMessage,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child:
                        const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: saving
                        ? null
                        : _saveVerification,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.save_outlined,
                          ),
                    label: Text(
                      saving
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

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}