import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/immersion_api_service.dart';
import '../../services/live_tracking_service.dart';

class ImmersionWorkflowScreen extends StatefulWidget {
  final String applicationId;
  final Map<String, dynamic> ganeshRecord;

  const ImmersionWorkflowScreen({
    Key? key,
    required this.applicationId,
    required this.ganeshRecord,
  }) : super(key: key);

  @override
  State<ImmersionWorkflowScreen> createState() =>
      _ImmersionWorkflowScreenState();
}

class _ImmersionWorkflowScreenState extends State<ImmersionWorkflowScreen> {
  int _currentStep = 0;
  bool _submitting = false;

  final ImagePicker _imagePicker = ImagePicker();

  // Module 1: Pre-Verification
  bool? _immersionPermission;
  final TextEditingController _noPermissionReasonCtrl = TextEditingController();
  final TextEditingController _noPermissionActionCtrl = TextEditingController();
  final TextEditingController _noPermissionRemarksCtrl = TextEditingController();
  DateTime? _immersionDate;
  TimeOfDay? _expectedDeparture;
  TimeOfDay? _expectedImmersion;

  // Module 2: Procession Formation
  bool? _idolLoaded;
  File? _loadedIdolPhoto;
  String? _vehicleType;
  final TextEditingController _vehicleNumberCtrl = TextEditingController();
  final TextEditingController _driverNameCtrl = TextEditingController();
  final TextEditingController _driverMobileCtrl = TextEditingController();
  bool? _soundSystemVerified;
  bool? _soundPermission;
  bool? _soundAwareness;
  final TextEditingController _soundRemarksCtrl = TextEditingController();
  bool? _volunteersVerified;
  int _volunteerCount = 1;
  final List<TextEditingController> _volunteerNameCtrls = [];
  final List<TextEditingController> _volunteerMobileCtrls = [];
  final List<TextEditingController> _volunteerIdCtrls = [];

  // Module 3: Route Management
  String? _routeType;
  bool? _roadClearance;
  bool? _trafficArrangement;
  bool? _barricading;
  bool? _electricitySafety;
  bool? _treeBranchClearance;
  bool? _emergencyAccess;
  bool? _reachedPoint;
  File? _routePhoto;
  final TextEditingController _routeRemarksCtrl = TextEditingController();

  // Module 4: Tracking handled directly via Service

  // Module 5: Immersion Point Verification
  bool? _crowdManagement;
  bool? _barricadesAvailable;
  bool? _queueArrangement;
  bool? _policeDeployment;
  bool? _volunteersAvailable;
  bool? _safety;
  bool? _lighting;
  bool? _medicalFacility;
  bool? _ptEmergencyAccess;
  bool? _disasterResponse;
  bool? _environment;
  bool? _waterBodyAccess;
  bool? _craneAvailability;
  bool? _rescueTeamAvailability;
  File? _immersionPointPhoto;

  // Module 6: Final Confirmation
  bool? _immersionCompleted;
  File? _finalPhoto;
  final TextEditingController _notCompletedReasonCtrl = TextEditingController();
  final TextEditingController _notCompletedActionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncVolunteerControllers();
  }

  void _syncVolunteerControllers() {
    while (_volunteerNameCtrls.length < _volunteerCount) {
      _volunteerNameCtrls.add(TextEditingController());
      _volunteerMobileCtrls.add(TextEditingController());
      _volunteerIdCtrls.add(TextEditingController());
    }
    while (_volunteerNameCtrls.length > _volunteerCount) {
      _volunteerNameCtrls.last.dispose();
      _volunteerNameCtrls.removeLast();
      _volunteerMobileCtrls.last.dispose();
      _volunteerMobileCtrls.removeLast();
      _volunteerIdCtrls.last.dispose();
      _volunteerIdCtrls.removeLast();
    }
  }

  @override
  void dispose() {
    _noPermissionReasonCtrl.dispose();
    _noPermissionActionCtrl.dispose();
    _noPermissionRemarksCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverMobileCtrl.dispose();
    _soundRemarksCtrl.dispose();
    _routeRemarksCtrl.dispose();
    _notCompletedReasonCtrl.dispose();
    _notCompletedActionCtrl.dispose();
    for (var c in _volunteerNameCtrls) {
      c.dispose();
    }
    for (var c in _volunteerMobileCtrls) {
      c.dispose();
    }
    for (var c in _volunteerIdCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  String _text(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  Future<void> _capturePhoto(Function(File) onCaptured) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (picked != null) {
        onCaptured(File(picked.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture photo: $e')),
      );
    }
  }

  Future<Position?> _getGps() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitCurrentStep() async {
    setState(() {
      _submitting = true;
    });

    try {
      Map<String, dynamic> data = {};
      if (_currentStep == 0) {
        data = {
          'immersionPermission': _immersionPermission,
          'noPermissionReason': _noPermissionReasonCtrl.text,
          'noPermissionAction': _noPermissionActionCtrl.text,
          'noPermissionRemarks': _noPermissionRemarksCtrl.text,
          'immersionDate': _immersionDate?.toIso8601String(),
          'expectedDeparture': _expectedDeparture?.format(context),
          'expectedImmersion': _expectedImmersion?.format(context),
        };
      } else if (_currentStep == 1) {
        data = {
          'idolLoaded': _idolLoaded,
          'vehicleType': _vehicleType,
          'vehicleNumber': _vehicleNumberCtrl.text,
          'driverName': _driverNameCtrl.text,
          'driverMobile': _driverMobileCtrl.text,
          'soundSystemVerified': _soundSystemVerified,
          'soundPermission': _soundPermission,
          'soundAwareness': _soundAwareness,
          'soundRemarks': _soundRemarksCtrl.text,
          'volunteersVerified': _volunteersVerified,
          'volunteerCount': _volunteersVerified == true ? _volunteerCount : 0,
        };
      } else if (_currentStep == 2) {
        data = {
          'routeType': _routeType,
          'roadClearance': _roadClearance,
          'trafficArrangement': _trafficArrangement,
          'barricading': _barricading,
          'electricitySafety': _electricitySafety,
          'treeBranchClearance': _treeBranchClearance,
          'emergencyAccess': _emergencyAccess,
          'reachedPoint': _reachedPoint,
          'routeRemarks': _routeRemarksCtrl.text,
        };
      } else if (_currentStep == 3) {
        data = {'liveTrackingStarted': true};
      } else if (_currentStep == 4) {
        data = {
          'crowdManagement': _crowdManagement,
          'barricadesAvailable': _barricadesAvailable,
          'queueArrangement': _queueArrangement,
          'policeDeployment': _policeDeployment,
          'volunteersAvailable': _volunteersAvailable,
          'safety': _safety,
          'lighting': _lighting,
          'medicalFacility': _medicalFacility,
          'ptEmergencyAccess': _ptEmergencyAccess,
          'disasterResponse': _disasterResponse,
          'environment': _environment,
          'waterBodyAccess': _waterBodyAccess,
          'craneAvailability': _craneAvailability,
          'rescueTeamAvailability': _rescueTeamAvailability,
        };
      } else if (_currentStep == 5) {
        final pos = await _getGps();
        data = {
          'immersionCompleted': _immersionCompleted,
          'notCompletedReason': _notCompletedReasonCtrl.text,
          'notCompletedAction': _notCompletedActionCtrl.text,
          'completedTime': DateTime.now().toIso8601String(),
          'latitude': pos?.latitude,
          'longitude': pos?.longitude,
        };
        await ImmersionApiService.submitFinalImmersion(widget.applicationId, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Immersion completely recorded!')),
          );
          Navigator.pop(context);
        }
        return;
      }

      await ImmersionApiService.submitImmersionStep(
        widget.applicationId,
        _currentStep + 1,
        data,
      );

      setState(() {
        if (_currentStep < 5) {
          _currentStep++;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Widget _buildYesNo(String label, bool? value, Function(bool?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Radio<bool>(
            value: true,
            groupValue: value,
            onChanged: onChanged,
          ),
          const Text('YES'),
          Radio<bool>(
            value: false,
            groupValue: value,
            onChanged: onChanged,
          ),
          const Text('NO'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF17365D),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Immersion: ${widget.applicationId}'),
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _submitting ? null : _submitCurrentStep,
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep--;
            });
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF17365D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(_currentStep == 5 ? 'COMPLETE IMMERSION' : 'SAVE & CONTINUE'),
                  ),
                ),
                if (_currentStep > 0) const SizedBox(width: 12),
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('BACK'),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
          _buildStep4(),
          _buildStep5(),
          _buildStep6(),
        ],
      ),
    );
  }

  Step _buildStep1() {
    return Step(
      title: const Text('Pre-Verification'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: const Color(0xFFF8FAFC),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GPID: ${widget.applicationId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Mandap: ${_text(widget.ganeshRecord['mandapam_name'])}'),
                  Text('Organiser: ${_text(widget.ganeshRecord['applicant_name'])}'),
                  Text('Contact: ${_text(widget.ganeshRecord['applicant_mobile'])}'),
                  Text('Height: ${_text(widget.ganeshRecord['height_in_feet'])} ft'),
                  Text('Material: ${_text(widget.ganeshRecord['material_type'])}'),
                  Text('Sensitivity: ${_text(widget.ganeshRecord['sensitivity_category'])}'),
                  Text('PS: ${_text(widget.ganeshRecord['ps_name'])}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildYesNo('Immersion Permission available?', _immersionPermission, (v) => setState(() => _immersionPermission = v)),
          if (_immersionPermission == false) ...[
            TextField(controller: _noPermissionReasonCtrl, decoration: const InputDecoration(labelText: 'Reason')),
            TextField(controller: _noPermissionActionCtrl, decoration: const InputDecoration(labelText: 'Action Taken')),
            TextField(controller: _noPermissionRemarksCtrl, decoration: const InputDecoration(labelText: 'Remarks')),
          ],
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Immersion Date'),
            subtitle: Text(_immersionDate?.toLocal().toString().split(' ')[0] ?? 'Select Date'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (d != null) setState(() => _immersionDate = d);
            },
          ),
          ListTile(
            title: const Text('Expected Departure Time'),
            subtitle: Text(_expectedDeparture?.format(context) ?? 'Select Time'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
              if (t != null) setState(() => _expectedDeparture = t);
            },
          ),
          ListTile(
            title: const Text('Expected Immersion Time'),
            subtitle: Text(_expectedImmersion?.format(context) ?? 'Select Time'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
              if (t != null) setState(() => _expectedImmersion = t);
            },
          ),
        ],
      ),
    );
  }

  Step _buildStep2() {
    return Step(
      title: const Text('Procession Formation'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('Idol Loading'),
          _buildYesNo('Is the idol loaded?', _idolLoaded, (v) => setState(() => _idolLoaded = v)),
          if (_idolLoaded == true) ...[
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Vehicle Type'),
              value: _vehicleType,
              items: ['Tractor', 'Lorry', 'Crane', 'Other']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _vehicleType = v),
            ),
            TextField(controller: _vehicleNumberCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            TextField(controller: _driverNameCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
            TextField(controller: _driverMobileCtrl, decoration: const InputDecoration(labelText: 'Driver Mobile'), keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _capturePhoto((f) => setState(() => _loadedIdolPhoto = f)),
              icon: const Icon(Icons.camera_alt),
              label: Text(_loadedIdolPhoto == null ? 'Capture Vehicle Photo' : 'Photo Captured'),
            ),
          ],
          _buildSectionHeader('Sound System'),
          _buildYesNo('Sound System present?', _soundSystemVerified, (v) => setState(() => _soundSystemVerified = v)),
          if (_soundSystemVerified == true) ...[
            _buildYesNo('Permission available?', _soundPermission, (v) => setState(() => _soundPermission = v)),
            _buildYesNo('Sound limit awareness?', _soundAwareness, (v) => setState(() => _soundAwareness = v)),
            TextField(controller: _soundRemarksCtrl, decoration: const InputDecoration(labelText: 'Remarks')),
          ],
          _buildSectionHeader('Volunteers'),
          _buildYesNo('Volunteers present?', _volunteersVerified, (v) => setState(() => _volunteersVerified = v)),
          if (_volunteersVerified == true) ...[
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Number of Volunteers'),
              value: _volunteerCount,
              items: List.generate(50, (i) => i + 1)
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _volunteerCount = v;
                    _syncVolunteerControllers();
                  });
                }
              },
            ),
            ...List.generate(_volunteerCount, (i) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text('Volunteer ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextField(controller: _volunteerNameCtrls[i], decoration: const InputDecoration(labelText: 'Name')),
                      TextField(controller: _volunteerMobileCtrls[i], decoration: const InputDecoration(labelText: 'Mobile')),
                      TextField(controller: _volunteerIdCtrls[i], decoration: const InputDecoration(labelText: 'ID / Aadhaar')),
                    ],
                  ),
                ),
              );
            }),
          ]
        ],
      ),
    );
  }

  Step _buildStep3() {
    return Step(
      title: const Text('Route Management'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Route Type'),
            value: _routeType,
            items: ['Main Route', 'Tributary Route', 'Alternative Route']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _routeType = v),
          ),
          _buildSectionHeader('Route Checklist'),
          _buildYesNo('Road Clearance verified?', _roadClearance, (v) => setState(() => _roadClearance = v)),
          _buildYesNo('Traffic Arrangement ready?', _trafficArrangement, (v) => setState(() => _trafficArrangement = v)),
          _buildYesNo('Barricading in place?', _barricading, (v) => setState(() => _barricading = v)),
          _buildYesNo('Electricity Safety checked?', _electricitySafety, (v) => setState(() => _electricitySafety = v)),
          _buildYesNo('Tree Branch Clearance done?', _treeBranchClearance, (v) => setState(() => _treeBranchClearance = v)),
          _buildYesNo('Emergency Vehicle Access?', _emergencyAccess, (v) => setState(() => _emergencyAccess = v)),
          _buildSectionHeader('Route Points'),
          _buildYesNo('Reached Next Point?', _reachedPoint, (v) => setState(() => _reachedPoint = v)),
          ElevatedButton.icon(
            onPressed: () => _capturePhoto((f) => setState(() => _routePhoto = f)),
            icon: const Icon(Icons.camera_alt),
            label: Text(_routePhoto == null ? 'Capture Location Photo' : 'Photo Captured'),
          ),
          TextField(controller: _routeRemarksCtrl, decoration: const InputDecoration(labelText: 'Route Remarks')),
        ],
      ),
    );
  }

  Step _buildStep4() {
    return Step(
      title: const Text('Live Procession Tracking'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Press the button below to start sending live GPS coordinates for this procession.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              setState(() => _submitting = true);
              final service = LiveTrackingService.instance;
              bool success = await service.startTracking();
              if (success) {
                await service.startVerification(widget.applicationId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Live tracking started successfully!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to start tracking.')),
                );
              }
              setState(() => _submitting = false);
            },
            icon: const Icon(Icons.gps_fixed),
            label: const Text('START IMMERSION MOVEMENT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildStep5() {
    return Step(
      title: const Text('Immersion Point Verification'),
      isActive: _currentStep >= 4,
      state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildYesNo('Crowd Management in place?', _crowdManagement, (v) => setState(() => _crowdManagement = v)),
          _buildYesNo('Barricades Available?', _barricadesAvailable, (v) => setState(() => _barricadesAvailable = v)),
          _buildYesNo('Queue Arrangement done?', _queueArrangement, (v) => setState(() => _queueArrangement = v)),
          _buildYesNo('Police Deployment adequate?', _policeDeployment, (v) => setState(() => _policeDeployment = v)),
          _buildYesNo('Volunteers Available?', _volunteersAvailable, (v) => setState(() => _volunteersAvailable = v)),
          _buildYesNo('Overall Safety verified?', _safety, (v) => setState(() => _safety = v)),
          _buildYesNo('Proper Lighting present?', _lighting, (v) => setState(() => _lighting = v)),
          _buildYesNo('Medical Facility available?', _medicalFacility, (v) => setState(() => _medicalFacility = v)),
          _buildYesNo('Emergency Access clear?', _ptEmergencyAccess, (v) => setState(() => _ptEmergencyAccess = v)),
          _buildYesNo('Disaster Response ready?', _disasterResponse, (v) => setState(() => _disasterResponse = v)),
          _buildYesNo('Environment protocols followed?', _environment, (v) => setState(() => _environment = v)),
          _buildYesNo('Water Body Access safe?', _waterBodyAccess, (v) => setState(() => _waterBodyAccess = v)),
          _buildYesNo('Crane Availability confirmed?', _craneAvailability, (v) => setState(() => _craneAvailability = v)),
          _buildYesNo('Rescue Team Availability?', _rescueTeamAvailability, (v) => setState(() => _rescueTeamAvailability = v)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _capturePhoto((f) => setState(() => _immersionPointPhoto = f)),
            icon: const Icon(Icons.camera_alt),
            label: Text(_immersionPointPhoto == null ? 'Capture Point Photo (Mandatory)' : 'Photo Captured'),
          ),
        ],
      ),
    );
  }

  Step _buildStep6() {
    return Step(
      title: const Text('Final Confirmation'),
      isActive: _currentStep >= 5,
      state: StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildYesNo('Is Immersion Completed?', _immersionCompleted, (v) => setState(() => _immersionCompleted = v)),
          if (_immersionCompleted == true) ...[
            ElevatedButton.icon(
              onPressed: () => _capturePhoto((f) => setState(() => _finalPhoto = f)),
              icon: const Icon(Icons.camera_alt),
              label: Text(_finalPhoto == null ? 'Capture Final Immersion Photo' : 'Final Photo Captured'),
            ),
          ] else if (_immersionCompleted == false) ...[
            TextField(controller: _notCompletedReasonCtrl, decoration: const InputDecoration(labelText: 'Reason for not completing')),
            TextField(controller: _notCompletedActionCtrl, decoration: const InputDecoration(labelText: 'Follow-up action')),
          ],
        ],
      ),
    );
  }
}
