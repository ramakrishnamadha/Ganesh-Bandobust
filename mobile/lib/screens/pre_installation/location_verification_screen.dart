import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/verification_api_service.dart';

class LocationVerificationScreen extends StatefulWidget {
  final String applicationId;
  final String? gpid;
  final Map<String, dynamic>? ganeshRecord;
  final double? originalLatitude;
  final double? originalLongitude;

  const LocationVerificationScreen({
    super.key,
    required this.applicationId,
    this.gpid,
    this.ganeshRecord,
    this.originalLatitude,
    this.originalLongitude,
  });

  @override
  State<LocationVerificationScreen> createState() =>
      _LocationVerificationScreenState();
}

class _LocationVerificationScreenState
    extends State<LocationVerificationScreen> {
  // ============================================================
  // VERIFICATION VALUES
  // ============================================================

  String locationVerified = '';
  String locationChanged = '';
  String samePoliceStation = '';

  String sector = '';
  String commissionerate = '';
  String policeStation = '';

  String disputedLand = '';
  String sensitivity = '';

  String notVerifiedRemarks = '';
  String disputedLandRemarks = '';
  String sensitivityRemarks = '';

  // ============================================================
  // CURRENT VERIFIED GEO LOCATION
  // ============================================================

  double? currentLatitude;
  double? currentLongitude;
  double? gpsAccuracy;
  DateTime? capturedAt;

  bool gpsLoading = false;
  bool saving = false;

  String errorMessage = '';
  String successMessage = '';

  // ============================================================
  // SECTOR MASTER
  // Temporary until actual Sector Master is connected
  // ============================================================

  static const List<String> sectors = [
    '01',
    '02',
    '03',
    '04',
    '05',
  ];

  // ============================================================
  // COMMISSIONERATE MASTER
  // ============================================================

  static const List<String> commissionerates = [
    'Hyderabad Commissionerate',
    'Cyberabad Commissionerate',
    'Malkajgiri Commissionerate',
    'Future Commissionerate',
  ];

  // ============================================================
  // POLICE STATION MASTER
  // ============================================================

  static const Map<String, List<String>>
      policeStationsByCommissionerate = {
    // ----------------------------------------------------------
    // HYDERABAD COMMISSIONERATE
    // ----------------------------------------------------------

    'Hyderabad Commissionerate': [
      'Charminar PS',
      'Hussainialam PS',
      'Moghalpura PS',
      'Shalibanda PS',
      'Malakpet PS',
      'Chaderghat PS',
      'Dabeerpura PS',
      'Mirchowk PS',
      'Bhavani Nagar PS',
      'Rein Bazar PS',
      'Saidabad PS',
      'Madannapet PS',
      'Santoshnagar PS',
      'IS Sadan PS',
      'Chatrinaka PS',
      'Adibatla PS',
      'Balapur PS',
      'Meerpet PS',
      'RGIA PS',
      'RGIA OP',
      'Pahadi Shareef PS',
      'Asif Nagar PS',
      'Mehdipatnam PS',
      'Habeeb Nagar PS',
      'Masab Tank PS',
      'Goshamahal PS',
      'Begumbazar PS',
      'Afzalgunj PS',
      'Kulsumpura PS',
      'Tappachabutra PS',
      'Gudimalkapur PS',
      'Mangalhat PS',
      'Tolichowki PS',
      'Golconda PS',
      'Langar House PS',
      'Chandrayangutta PS',
      'Bandlaguda PS',
      'Kanchanbagh PS',
      'Mailardevpally PS',
      'Falaknuma PS',
      'Kamatipura PS',
      'Bahadurpura PS',
      'Kalapathar PS',
      'Rajendra Nagar PS',
      'Attapur PS',
      'Chikkadpally PS',
      'Musheerabad PS',
      'Kachiguda PS',
      'Chilkalguda PS',
      'Lalaguda PS',
      'Warasiguda PS',
      'Gandhi Nagar PS',
      'Domalguda PS',
      'Mahankali PS',
      'Ramgopalpet PS',
      'OU Sity PS',
      'Nallakunta PS',
      'Amberpet PS',
      'Banjara Hills PS',
      'Madhura Nagar PS',
      'Jubilee Hills PS',
      'Film Nagar PS',
      'S.R. Nagar PS',
      'Borabanda PS',
      'Sanath Nagar PS',
      'Abids PS',
      'Nampally PS',
      'Panjagutta PS',
      'Khairatabad PS',
      'Saifabad PS',
      'Lake PS',
      'Sultan Bazar PS',
      'Narayanaguda PS',
    ],

    // ----------------------------------------------------------
    // CYBERABAD COMMISSIONERATE
    // ----------------------------------------------------------

    'Cyberabad Commissionerate': [
      'Chandanagar PS',
      'RC Puram PS',
      'Patancheru PS',
      'Ameenpur PS',
      'IDA Bollaram PS',
      'Narsingi PS',
      'Gachibowli PS',
      'Kollur PS',
      'KPHB PS',
      'Miyapur PS',
      'Balanagar PS',
      'Kukatpally PS',
      'Allapur PS',
      'Madhapur PS',
      'Raidurgam PS',
    ],

    // ----------------------------------------------------------
    // MALKAJGIRI COMMISSIONERATE
    // ----------------------------------------------------------

    'Malkajgiri Commissionerate': [
      'Malkajgiri PS',
      'Neredmet PS',
      'Gopalapuram PS',
      'Market PS',
      'Tukaramgate PS',
      'Jawaharnagar PS',
      'Keesara PS',
      'Shamirpet PS',
      'Begumpet PS',
      'Bowenpally PS',
      'Maredpally PS',
      'Alwal PS',
      'Kharkhana PS',
      'Trimulgherry PS',
      'Bollarum PS',
      'Uppal PS',
      'Nacharam PS',
      'Kushaiguda PS',
      'Medipally PS',
      'Pocharam IT Corridor PS',
      'Ghatkesar PS',
      'Cherlapally PS',
      'L B Nagar PS',
      'Nagole PS',
      'Chaitanyapuri PS',
      'Saroornagar PS',
      'Vanasthalipuram PS',
      'Hayathnagar PS',
      'Abdullapurmet PS',
    ],

    // ----------------------------------------------------------
    // FUTURE COMMISSIONERATE
    // ----------------------------------------------------------

    'Future Commissionerate': [
      'Shadnagar PS',
      'Kondurg PS',
      'Jilled Chowdarigudem PS',
      'Kothur PS',
      'Nandigama PS',
      'Keshampet PS',
      'Maheshwaram PS',
      'Kandukur PS',
      'Ibrahimpatnam PS',
      'Yacharam PS',
      'Manchal PS',
      'Hyderabad Green Pharma City PS',
      'Talakondapally PS',
      'Madgula PS',
      'Kadthal PS',
      'Amangal PS',
      'Chevella PS',
      'Shankarpally PS',
      'Mokila PS',
      'Moinabad PS',
      'Shabad PS',
      'Shamshabad PS',
    ],
  };

  static const List<String> sensitivityList = [
    'NORMAL',
    'MEDIUM',
    'HIGH',
  ];

  // ============================================================
  // CURRENT POLICE STATION LIST
  // ============================================================

  List<String> get availablePoliceStations {
    if (commissionerate.isEmpty) {
      return [];
    }

    return policeStationsByCommissionerate[commissionerate] ?? [];
  }

  String get _selectedGpid {
    final value = (widget.gpid ?? widget.applicationId).trim();
    return value.isEmpty ? widget.applicationId : value;
  }

  Future<bool> _saveLocationResult(
    Map<String, dynamic> result,
  ) async {
    if (!mounted) return false;

    setState(() {
      saving = true;
      errorMessage = '';
      successMessage = '';
    });

    try {
      await VerificationApiService.saveModuleResult(
        applicationId: widget.applicationId,
        gpid: _selectedGpid,
        moduleKey: 'locationResult',
        result: result,
      );

      if (!mounted) return false;

      setState(() {
        saving = false;
      });

      return true;
    } catch (e) {
      if (!mounted) return false;

      setState(() {
        saving = false;
        errorMessage =
            'Unable to save Location Verification to the server. '
            'Please check the network and try again.';
      });

      return false;
    }
  }

  // ============================================================
  // GPS
  // ============================================================

  Future<void> captureNewLocation() async {
    setState(() {
      gpsLoading = true;
      errorMessage = '';
      successMessage = '';
    });

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          errorMessage =
              'Location services are disabled. Please enable GPS.';
          gpsLoading = false;
        });
        return;
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
              'Location permission was denied.';
          gpsLoading = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage =
              'Location permission is permanently denied. '
              'Please enable it from device settings.';
          gpsLoading = false;
        });
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
        gpsAccuracy = position.accuracy;
        capturedAt = DateTime.now();

        successMessage =
            'New installation location captured successfully.';

        gpsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to capture GPS location.';
        gpsLoading = false;
      });
    }
  }

  // ============================================================
  // YES / NO BUTTONS
  // ============================================================

  Widget yesNoButtons({
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
              backgroundColor: value == 'NO'
                  ? Colors.red
                  : const Color(0xFFE2E8F0),
              foregroundColor:
                  value == 'NO' ? Colors.white : Colors.black87,
            ),
            child: const Text('NO'),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONFIRMATION
  // ============================================================

  Future<bool> showSaveConfirmation() async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text(
            'I have personally verified the installation location '
            'and confirm that the above information is correct.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('CONFIRM & SAVE'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> saveVerification() async {
    setState(() {
      errorMessage = '';
      successMessage = '';
    });

    // ----------------------------------------------------------
    // POINT 1
    // ----------------------------------------------------------

    if (locationVerified.isEmpty) {
      setState(() {
        errorMessage =
            'Please answer: Location Verified?';
      });
      return;
    }

    if (locationVerified == 'NO') {
      if (notVerifiedRemarks.trim().isEmpty) {
        setState(() {
          errorMessage =
              'Reason / Remarks are mandatory when Location Verified is NO.';
        });
        return;
      }

      final bool confirmed =
          await showSaveConfirmation();

      if (!confirmed || !mounted) return;

      final result = <String, dynamic>{
        'applicationId': widget.applicationId,
        'gpid': _selectedGpid,
        'locationVerified': 'NO',
        'remarks': notVerifiedRemarks.trim(),
        'originalGeoLocation': {
          'latitude': widget.originalLatitude,
          'longitude': widget.originalLongitude,
        },
        'verifiedAt': DateTime.now().toIso8601String(),
      };

      final saved = await _saveLocationResult(result);

      if (!saved || !mounted) return;

      Navigator.pop(context, result);
      return;
    }

    // ----------------------------------------------------------
    // POINT 2
    // ----------------------------------------------------------

    if (locationChanged.isEmpty) {
      setState(() {
        errorMessage =
            'Please answer: Will the Installation Location be Changed?';
      });
      return;
    }

    if (locationChanged == 'YES') {
      if (currentLatitude == null ||
          currentLongitude == null ||
          capturedAt == null) {
        setState(() {
          errorMessage =
              'Please capture the new installation location.';
        });
        return;
      }

      if (samePoliceStation.isEmpty) {
        setState(() {
          errorMessage =
              'Please answer whether the updated location falls '
              'within the jurisdictional limits of this Police Station.';
        });
        return;
      }

      if (samePoliceStation == 'YES' &&
          sector.isEmpty) {
        setState(() {
          errorMessage =
              'Please select Sector Number.';
        });
        return;
      }

      if (samePoliceStation == 'NO') {
        if (commissionerate.isEmpty) {
          setState(() {
            errorMessage =
                'Please select Commissionerate.';
          });
          return;
        }

        if (policeStation.isEmpty) {
          setState(() {
            errorMessage =
                'Please select Police Station.';
          });
          return;
        }
      }
    }

    // ----------------------------------------------------------
    // POINT 3
    // ----------------------------------------------------------

    if (disputedLand.isEmpty) {
      setState(() {
        errorMessage =
            'Please answer whether the proposed installation '
            'location is situated on disputed land.';
      });
      return;
    }

    if (disputedLand == 'YES' &&
        disputedLandRemarks.trim().isEmpty) {
      setState(() {
        errorMessage =
            'Remarks are mandatory for disputed land.';
      });
      return;
    }

    // ----------------------------------------------------------
    // POINT 4
    // ----------------------------------------------------------

    if (sensitivity.isEmpty) {
      setState(() {
        errorMessage =
            'Please select Sensitivity of the Location.';
      });
      return;
    }

    if ((sensitivity == 'MEDIUM' ||
            sensitivity == 'HIGH') &&
        sensitivityRemarks.trim().isEmpty) {
      setState(() {
        errorMessage =
            'Remarks are mandatory for Medium / High sensitivity.';
      });
      return;
    }

    final bool confirmed =
        await showSaveConfirmation();

    if (!confirmed || !mounted) return;

    double? verifiedLatitude;
    double? verifiedLongitude;
    double? verifiedAccuracy;
    DateTime? verifiedCapturedAt;

    if (locationChanged == 'YES') {
      verifiedLatitude = currentLatitude;
      verifiedLongitude = currentLongitude;
      verifiedAccuracy = gpsAccuracy;
      verifiedCapturedAt = capturedAt;
    } else {
      verifiedLatitude = widget.originalLatitude;
      verifiedLongitude = widget.originalLongitude;
      verifiedAccuracy = null;
      verifiedCapturedAt = null;
    }

    final result = <String, dynamic>{
      'applicationId': widget.applicationId,
      'gpid': _selectedGpid,

      'locationVerified': locationVerified,
      'locationChanged': locationChanged,

      'originalGeoLocation': {
        'latitude': widget.originalLatitude,
        'longitude': widget.originalLongitude,
      },

      'currentVerifiedGeoLocation': {
        'latitude': verifiedLatitude,
        'longitude': verifiedLongitude,
        'accuracy': verifiedAccuracy,
        'capturedAt':
            verifiedCapturedAt?.toIso8601String(),
      },

      'samePoliceStation':
          locationChanged == 'YES'
              ? samePoliceStation
              : null,

      'sector':
          locationChanged == 'YES' &&
                  samePoliceStation == 'YES'
              ? sector
              : null,

      'commissionerate':
          locationChanged == 'YES' &&
                  samePoliceStation == 'NO'
              ? commissionerate
              : null,

      'policeStation':
          locationChanged == 'YES' &&
                  samePoliceStation == 'NO'
              ? policeStation
              : null,

      'disputedLand': disputedLand,
      'disputedLandRemarks':
          disputedLandRemarks.trim(),

      'sensitivity': sensitivity,
      'sensitivityRemarks':
          sensitivityRemarks.trim(),

      'verifiedAt':
          DateTime.now().toIso8601String(),
    };

    final saved = await _saveLocationResult(result);

    if (!saved || !mounted) return;

    Navigator.pop(context, result);
  }

  // ============================================================
  // GPID API TEXT HELPER
  // ============================================================

  String _recordText(String key) {
    final value = widget.ganeshRecord?[key];

    if (value == null) return '-';

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '-';
    }

    return text;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
        title: const Text(
          'Location-Based Verification',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            // ==================================================
            // SELECTED GPID / API DETAILS
            // ==================================================

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
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.gpid?.trim().isNotEmpty == true
                          ? widget.gpid!
                          : widget.applicationId,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17365D),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Divider(height: 1),

                    const SizedBox(height: 14),

                    const Text(
                      'Applicant Name',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _recordText('name'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Association / Organisation',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _recordText('association'),
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Police Station',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _recordText('ps_name'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ==================================================
            // ORIGINAL GPID LOCATION
            // ==================================================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Color(0xFF17365D),
                        ),

                        SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            'Original GPID Geo-Location',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(0xFF17365D),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (widget.originalLatitude != null &&
                        widget.originalLongitude != null) ...[
                      Text(
                        'Latitude: '
                        '${widget.originalLatitude!.toStringAsFixed(6)}',
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Longitude: '
                        '${widget.originalLongitude!.toStringAsFixed(6)}',
                      ),
                    ] else ...[
                      const Text(
                        'Pre-Geo-Tagged coordinates will be '
                        'fetched through GPID / Application API.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    const Text(
                      'Original registered geo-location will not be overwritten.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ==================================================
            // POINT 1
            // ==================================================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,

                  children: [
                    const Text(
                      'Point 1 — Location Verified?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    yesNoButtons(
                      value: locationVerified,
                      onChanged: (value) {
                        setState(() {
                          locationVerified = value;

                          if (value == 'NO') {
                            locationChanged = '';
                            samePoliceStation = '';
                            sector = '';
                            commissionerate = '';
                            policeStation = '';
                            disputedLand = '';
                            sensitivity = '';
                          }
                        });
                      },
                    ),

                    if (locationVerified == 'NO') ...[
                      const SizedBox(height: 18),

                      TextFormField(
                        maxLines: 4,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Reason / Remarks *',
                          hintText:
                              'Enter reason for location not verified',
                          border:
                              OutlineInputBorder(),
                        ),

                        onChanged: (value) {
                          notVerifiedRemarks = value;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ==================================================
            // ONLY WHEN LOCATION VERIFIED = YES
            // ==================================================

            if (locationVerified == 'YES') ...[
              const SizedBox(height: 14),

              // =================================================
              // POINT 2
              // =================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [
                      const Text(
                        'Point 2 — Will the Installation Location be Changed?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      yesNoButtons(
                        value: locationChanged,

                        onChanged: (value) {
                          setState(() {
                            locationChanged = value;

                            samePoliceStation = '';
                            sector = '';
                            commissionerate = '';
                            policeStation = '';

                            currentLatitude = null;
                            currentLongitude = null;
                            gpsAccuracy = null;
                            capturedAt = null;
                          });
                        },
                      ),

                      if (locationChanged ==
                          'NO') ...[
                        const SizedBox(height: 16),

                        Container(
                          padding:
                              const EdgeInsets.all(12),

                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFE8F5E9),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),

                          child: const Text(
                            'Original GPID Geo-Location will be retained as the Current Verified Geo-Location.',
                            style: TextStyle(
                              color:
                                  Color(0xFF1B5E20),
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],

                      if (locationChanged ==
                          'YES') ...[
                        const SizedBox(height: 18),

                        SizedBox(
                          height: 50,

                          child: ElevatedButton.icon(
                            onPressed: gpsLoading
                                ? null
                                : captureNewLocation,

                            icon: gpsLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location,
                                  ),

                            label: Text(
                              gpsLoading
                                  ? 'CAPTURING LOCATION...'
                                  : currentLatitude == null
                                      ? 'CAPTURE NEW LOCATION'
                                      : 'RE-CAPTURE NEW LOCATION',
                            ),
                          ),
                        ),

                        if (currentLatitude != null &&
                            currentLongitude != null) ...[
                          const SizedBox(height: 14),

                          Container(
                            padding:
                                const EdgeInsets.all(14),

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                    0xFFD4DAE2),
                              ),
                            ),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                const Text(
                                  'Current Verified Geo-Location',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  'Latitude: '
                                  '${currentLatitude!.toStringAsFixed(6)}',
                                ),

                                Text(
                                  'Longitude: '
                                  '${currentLongitude!.toStringAsFixed(6)}',
                                ),

                                Text(
                                  'GPS Accuracy: '
                                  '${gpsAccuracy?.toStringAsFixed(1) ?? '-'} metres',
                                ),

                                Text(
                                  'Captured At: '
                                  '${capturedAt ?? '-'}',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Does the Updated Location Fall Within the Jurisdictional Limits of this Police Station?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          yesNoButtons(
                            value:
                                samePoliceStation,

                            onChanged: (value) {
                              setState(() {
                                samePoliceStation =
                                    value;

                                sector = '';
                                commissionerate = '';
                                policeStation = '';
                              });
                            },
                          ),

                          // -------------------------------------
                          // SAME PS = YES
                          // -------------------------------------

                          if (samePoliceStation ==
                              'YES') ...[
                            const SizedBox(height: 18),

                            DropdownButtonFormField<
                                String>(
                              initialValue:
                                  sector.isEmpty
                                      ? null
                                      : sector,

                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Sector No. *',
                                border:
                                    OutlineInputBorder(),
                              ),

                              items: sectors
                                  .map(
                                    (item) =>
                                        DropdownMenuItem<
                                            String>(
                                      value: item,
                                      child:
                                          Text(item),
                                    ),
                                  )
                                  .toList(),

                              onChanged: (value) {
                                setState(() {
                                  sector =
                                      value ?? '';
                                });
                              },
                            ),
                          ],

                          // -------------------------------------
                          // SAME PS = NO
                          // -------------------------------------

                          if (samePoliceStation ==
                              'NO') ...[
                            const SizedBox(height: 18),

                            // COMMISSIONERATE
                            DropdownButtonFormField<
                                String>(
                              initialValue:
                                  commissionerate
                                          .isEmpty
                                      ? null
                                      : commissionerate,

                              isExpanded: true,

                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Commissionerate *',
                                border:
                                    OutlineInputBorder(),
                              ),

                              items: commissionerates
                                  .map(
                                    (item) =>
                                        DropdownMenuItem<
                                            String>(
                                      value: item,
                                      child: Text(
                                        item,
                                        overflow:
                                            TextOverflow
                                                .ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),

                              onChanged: (value) {
                                setState(() {
                                  commissionerate =
                                      value ?? '';

                                  // IMPORTANT:
                                  // Clear old PS when
                                  // Commissionerate changes.
                                  policeStation = '';
                                });
                              },
                            ),

                            const SizedBox(height: 16),

                            // POLICE STATION
                            DropdownButtonFormField<
                                String>(
                              key: ValueKey(
                                  commissionerate),

                              initialValue:
                                  policeStation.isEmpty
                                      ? null
                                      : policeStation,

                              isExpanded: true,

                              decoration:
                                  InputDecoration(
                                labelText:
                                    'Police Station *',

                                hintText:
                                    commissionerate
                                            .isEmpty
                                        ? 'Select Commissionerate first'
                                        : 'Select Police Station',

                                border:
                                    const OutlineInputBorder(),
                              ),

                              items:
                                  availablePoliceStations
                                      .map(
                                        (item) =>
                                            DropdownMenuItem<
                                                String>(
                                          value: item,
                                          child: Text(
                                            item,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),

                              onChanged:
                                  commissionerate
                                          .isEmpty
                                      ? null
                                      : (value) {
                                          setState(() {
                                            policeStation =
                                                value ??
                                                    '';
                                          });
                                        },
                            ),

                            if (commissionerate
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),

                              Text(
                                '${availablePoliceStations.length} Police Stations available under $commissionerate',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(
                                      0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // =================================================
              // POINT 3
              // =================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [
                      const Text(
                        'Point 3 — Is the Proposed Installation Location Situated on Disputed Land?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      yesNoButtons(
                        value: disputedLand,

                        onChanged: (value) {
                          setState(() {
                            disputedLand = value;

                            if (value == 'NO') {
                              disputedLandRemarks =
                                  '';
                            }
                          });
                        },
                      ),

                      if (disputedLand ==
                          'YES') ...[
                        const SizedBox(height: 18),

                        TextFormField(
                          maxLines: 4,

                          decoration:
                              const InputDecoration(
                            labelText:
                                'Remarks *',
                            hintText:
                                'Enter disputed land details',
                            border:
                                OutlineInputBorder(),
                          ),

                          onChanged: (value) {
                            disputedLandRemarks =
                                value;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // =================================================
              // POINT 4
              // =================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [
                      const Text(
                        'Point 4 — Sensitivity of the Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            sensitivity.isEmpty
                                ? null
                                : sensitivity,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Sensitivity *',
                          border:
                              OutlineInputBorder(),
                        ),

                        items: sensitivityList
                            .map(
                              (item) =>
                                  DropdownMenuItem<
                                      String>(
                                value: item,
                                child: Text(
                                  item == 'NORMAL'
                                      ? 'Normal'
                                      : item ==
                                              'MEDIUM'
                                          ? 'Medium'
                                          : 'High',
                                ),
                              ),
                            )
                            .toList(),

                        onChanged: (value) {
                          setState(() {
                            sensitivity =
                                value ?? '';

                            if (sensitivity ==
                                'NORMAL') {
                              sensitivityRemarks =
                                  '';
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        maxLines: 4,

                        decoration:
                            InputDecoration(
                          labelText:
                              sensitivity ==
                                          'MEDIUM' ||
                                      sensitivity ==
                                          'HIGH'
                                  ? 'Remarks *'
                                  : 'Remarks',

                          hintText:
                              'Enter sensitivity remarks',

                          border:
                              const OutlineInputBorder(),
                        ),

                        onChanged: (value) {
                          sensitivityRemarks =
                              value;
                        },
                      ),

                      if (sensitivity ==
                              'MEDIUM' ||
                          sensitivity ==
                              'HIGH') ...[
                        const SizedBox(height: 8),

                        const Text(
                          'Remarks are mandatory for Medium / High sensitivity.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ==================================================
            // ERROR
            // ==================================================

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

            // ==================================================
            // SUCCESS
            // ==================================================

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
                    color:
                        Color(0xFF166534),
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

            // ==================================================
            // SAVE
            // ==================================================

            SizedBox(
              height: 52,

              child: FilledButton.icon(
                onPressed:
                    saving ? null : saveVerification,

                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF17365D),
                ),

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
                    : const Icon(Icons.save),

                label: Text(
                  saving
                      ? 'SAVING...'
                      : 'SAVE LOCATION VERIFICATION',
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}