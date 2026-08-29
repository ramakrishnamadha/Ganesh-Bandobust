import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../models/ar_measurement_result.dart';

enum MeasurementStage {
  scanning,
  readyForStart,
  readyForEnd,
  measured,
}

class ArMeasurementScreen extends StatefulWidget {
  final String applicationId;
  final String measurementType;

  const ArMeasurementScreen({
    super.key,
    required this.applicationId,
    required this.measurementType,
  });

  @override
  State<ArMeasurementScreen> createState() =>
      _ArMeasurementScreenState();
}

class _ArMeasurementScreenState extends State<ArMeasurementScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;

  Vector3? startPoint;
  Vector3? endPoint;
  Vector3? livePoint;

  double? distanceMeters;
  double? distanceFeet;
  double? liveDistanceMeters;

  double? latitude;
  double? longitude;
  double? gpsAccuracy;

  DateTime? measuredAt;
  DateTime? livePointUpdatedAt;
  DateTime? lastSuccessfulCenterHitAt;

  bool locationLoading = false;
  bool evidenceSaving = false;
  bool arReady = false;
  bool _centerHitRequestInFlight = false;

  String? evidenceImagePath;
  Timer? _centerScanTimer;

  MeasurementStage stage = MeasurementStage.scanning;

  String instruction =
      'Move the phone slowly to scan the surroundings.';

  String get typeLabel {
    switch (widget.measurementType) {
      case 'HEIGHT':
        return 'Height';
      case 'WIDTH':
        return 'Width';
      default:
        return 'Length';
    }
  }

  double get minimumAcceptedMeters => 0.03;
  double get maximumAcceptedMeters => 30.0;

  Future<void> onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) async {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;
    arLocationManager = locationManager;

    try {
      await sessionManager.onInitialize(
        showFeaturePoints: false,
        showPlanes: false,
        showWorldOrigin: false,
        handleTaps: false,
      );

      if (!mounted) return;

      setState(() {
        arReady = true;
        stage = MeasurementStage.readyForStart;
        instruction =
            'Move the dot to Point A, then tap +.';
      });

      _startCenterScanning();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        instruction = 'Unable to initialize AR measurement: $error';
      });
    }
  }

  void _startCenterScanning() {
    _centerScanTimer?.cancel();
    _centerScanTimer = Timer.periodic(
      const Duration(milliseconds: 140),
      (_) {
        if (mounted &&
            arReady &&
            stage != MeasurementStage.measured) {
          _requestCenterHit();
        }
      },
    );
  }

  Future<void> _requestCenterHit() async {
    await _updateCenterHit();
  }

  Future<bool> _updateCenterHit({
    bool showGuidance = false,
  }) async {
    final sessionManager = arSessionManager;

    if (sessionManager == null ||
        _centerHitRequestInFlight ||
        !arReady ||
        stage == MeasurementStage.measured) {
      return _hasFreshLivePoint;
    }

    _centerHitRequestInFlight = true;

    try {
      final hits = await sessionManager.hitTestCenter();
      final point = _extractValidPoint(hits);

      if (!mounted) return false;

      if (point == null) {
        final now = DateTime.now();
        final recentlyHadValidHit = lastSuccessfulCenterHitAt != null &&
            now.difference(lastSuccessfulCenterHitAt!) <
                const Duration(milliseconds: 900);

        if (!recentlyHadValidHit) {
          setState(() {
            livePoint = null;
            livePointUpdatedAt = null;

            if (showGuidance) {
              instruction =
                  'Keep moving slowly until the centre dot locks onto the surface.';
            }
          });
        } else if (showGuidance && mounted) {
          setState(() {
            instruction =
                'Hold steady on Point B. The last valid surface position is being retained.';
          });
        }

        return recentlyHadValidHit && livePoint != null;
      }

      double? previewMeters;
      if (stage == MeasurementStage.readyForEnd && startPoint != null) {
        final rawMeters = _distanceBetween(startPoint!, point);

        if (rawMeters.isFinite &&
            rawMeters >= 0 &&
            rawMeters <= maximumAcceptedMeters) {
          if (liveDistanceMeters == null) {
            previewMeters = rawMeters;
          } else {
            // Light smoothing keeps the preview readable while still
            // responding quickly as the phone moves.
            const smoothing = 0.35;
            previewMeters =
                (liveDistanceMeters! * (1 - smoothing)) +
                    (rawMeters * smoothing);
          }
        }
      }

      final now = DateTime.now();

      setState(() {
        livePoint = point;
        livePointUpdatedAt = now;
        lastSuccessfulCenterHitAt = now;

        if (previewMeters != null) {
          liveDistanceMeters = previewMeters;
        }

        if (stage == MeasurementStage.readyForStart) {
          instruction = 'Surface ready. Tap + once to lock Point A.';
        } else if (stage == MeasurementStage.readyForEnd) {
          instruction = 'Move to Point B. Tap + once when aligned.';
        }
      });

      return true;
    } catch (error) {
      if (mounted && showGuidance) {
        setState(() {
          instruction =
              'AR centre measurement is not ready yet. Move the phone slowly and try again.';
        });
      }

      return false;
    } finally {
      _centerHitRequestInFlight = false;
    }
  }

  Vector3? _extractValidPoint(List<ARHitTestResult> hits) {
    if (hits.isEmpty) return null;

    for (final hit in hits) {
      final matrix = hit.worldTransform.storage;
      if (matrix.length < 15) continue;

      final x = matrix[12];
      final y = matrix[13];
      final z = matrix[14];

      if (!x.isFinite || !y.isFinite || !z.isFinite) continue;

      return Vector3(x, y, z);
    }

    return null;
  }

  double _distanceBetween(Vector3 a, Vector3 b) {
    return sqrt(
      pow(b.x - a.x, 2) +
          pow(b.y - a.y, 2) +
          pow(b.z - a.z, 2),
    );
  }

  bool get _hasFreshLivePoint {
    if (livePoint == null || livePointUpdatedAt == null) return false;
    return DateTime.now().difference(livePointUpdatedAt!) <
        const Duration(milliseconds: 1200);
  }

  bool get _canPlacePoint {
    return arReady &&
        stage != MeasurementStage.measured &&
        _hasFreshLivePoint &&
        livePoint != null;
  }

  Future<void> _addPoint() async {
    if (!arReady || stage == MeasurementStage.measured) return;

    if (!_canPlacePoint) {
      if (mounted) {
        setState(() {
          instruction =
              'Move slowly until the reticle becomes bright, then continue.';
        });
      }
      return;
    }

    final point = Vector3(
      livePoint!.x,
      livePoint!.y,
      livePoint!.z,
    );

    if (stage == MeasurementStage.readyForStart) {
      final confirmed = await _confirmPointAction(
        title: 'Start Measurement',
        message:
            'Start $typeLabel measurement from Point A at the current reticle position?',
        confirmLabel: 'YES, START',
      );

      if (!confirmed || !mounted) return;

      setState(() {
        startPoint = Vector3(point.x, point.y, point.z);
        endPoint = null;
        distanceMeters = null;
        distanceFeet = null;
        liveDistanceMeters = 0;
        latitude = null;
        longitude = null;
        gpsAccuracy = null;
        measuredAt = null;
        evidenceImagePath = null;
        stage = MeasurementStage.readyForEnd;
        instruction =
            'Point A locked. Move the reticle to Point B. Live $typeLabel will update.';
      });
      return;
    }

    if (stage == MeasurementStage.readyForEnd && startPoint != null) {
      final meters = _distanceBetween(startPoint!, point);

      if (!meters.isFinite) {
        setState(() {
          instruction =
              'Invalid AR result. Hold the phone steady and try Point B again.';
        });
        return;
      }

      if (meters < minimumAcceptedMeters) {
        setState(() {
          instruction =
              'Point B is too close to Point A. Move the reticle to the opposite end.';
        });
        return;
      }

      if (meters > maximumAcceptedMeters) {
        setState(() {
          instruction =
              'ARCore reported an unrealistic jump (${meters.toStringAsFixed(2)} m). Re-aim Point B and try again.';
        });
        return;
      }

      final confirmed = await _confirmPointAction(
        title: 'End Measurement',
        message:
            'End $typeLabel measurement at Point B?\n\nCurrent value: ${_formatFeetInches(meters)} (${meters.toStringAsFixed(2)} m)',
        confirmLabel: 'YES, END',
      );

      if (!confirmed || !mounted) return;

      _centerScanTimer?.cancel();

      setState(() {
        endPoint = Vector3(point.x, point.y, point.z);
        distanceMeters = meters;
        distanceFeet = meters * 3.280839895;
        liveDistanceMeters = meters;
        measuredAt = DateTime.now();
        evidenceImagePath = null;
        stage = MeasurementStage.measured;
        instruction =
            '$typeLabel measurement locked. Check the final value, then capture evidence.';
      });

      captureGps();
    }
  }

  Future<bool> _confirmPointAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('NO'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  void _undo() {
    if (stage == MeasurementStage.measured) {
      setState(() {
        endPoint = null;
        distanceMeters = null;
        distanceFeet = null;
        measuredAt = null;
        evidenceImagePath = null;
        latitude = null;
        longitude = null;
        gpsAccuracy = null;
        stage = MeasurementStage.readyForEnd;
        instruction =
            'Point B removed. Move the dot to Point B, then tap +.';
      });
      _startCenterScanning();
      return;
    }

    if (stage == MeasurementStage.readyForEnd) {
      setState(() {
        startPoint = null;
        liveDistanceMeters = null;
        stage = MeasurementStage.readyForStart;
        instruction = 'Point A removed. Move the dot to Point A, then tap +.';
      });
    }
  }

  void _clearMeasurement() {
    setState(() {
      startPoint = null;
      endPoint = null;
      livePoint = null;
      livePointUpdatedAt = null;
      lastSuccessfulCenterHitAt = null;
      liveDistanceMeters = null;
      distanceMeters = null;
      distanceFeet = null;
      latitude = null;
      longitude = null;
      gpsAccuracy = null;
      measuredAt = null;
      evidenceImagePath = null;
      stage = arReady
          ? MeasurementStage.readyForStart
          : MeasurementStage.scanning;
      instruction = arReady
          ? 'Cleared. Move the dot to Point A, then tap +.'
          : 'Move the phone slowly to scan the surroundings.';
    });

    if (arReady) _startCenterScanning();
  }

  Future<void> captureGps() async {
    if (locationLoading || !mounted) return;

    setState(() {
      locationLoading = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          locationLoading = false;
          instruction =
              'Measurement completed, but GPS is disabled. Enable location services before capturing evidence.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          locationLoading = false;
          instruction =
              'Measurement completed, but location permission is unavailable.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        gpsAccuracy = position.accuracy;
        locationLoading = false;
        instruction =
            'Measurement and GPS captured. Capture the evidence image to complete this measurement.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        locationLoading = false;
        instruction =
            'Measurement completed, but GPS could not be captured. Try GPS again before confirming.';
      });
    }
  }

  Future<Uint8List?> imageProviderToPngBytes(
    ImageProvider<Object> provider,
  ) async {
    final completer = Completer<Uint8List?>();
    final imageStream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo imageInfo, bool synchronousCall) async {
        try {
          final byteData = await imageInfo.image.toByteData(
            format: ui.ImageByteFormat.png,
          );

          if (!completer.isCompleted) {
            completer.complete(byteData?.buffer.asUint8List());
          }
        } catch (_) {
          if (!completer.isCompleted) completer.complete(null);
        } finally {
          imageStream.removeListener(listener);
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        imageStream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    imageStream.addListener(listener);
    return completer.future;
  }

  Future<void> captureEvidenceImage() async {
    if (arSessionManager == null ||
        stage != MeasurementStage.measured ||
        distanceFeet == null ||
        distanceMeters == null ||
        startPoint == null ||
        endPoint == null) {
      setState(() {
        instruction = 'Complete the measurement before capturing evidence.';
      });
      return;
    }

    if (latitude == null || longitude == null) {
      setState(() {
        instruction = 'GPS is required. Capturing location now...';
      });

      await captureGps();
      if (latitude == null || longitude == null) return;
    }

    setState(() {
      evidenceSaving = true;
      instruction = 'Capturing AR evidence image...';
    });

    try {
      final provider = await arSessionManager!.snapshot();
      final screenshot = await imageProviderToPngBytes(provider);

      if (screenshot == null) {
        if (!mounted) return;
        setState(() {
          evidenceSaving = false;
          instruction = 'Unable to convert the AR snapshot.';
        });
        return;
      }

      final decoded = img.decodeImage(screenshot);
      if (decoded == null) {
        if (!mounted) return;
        setState(() {
          evidenceSaving = false;
          instruction = 'Unable to process the captured evidence image.';
        });
        return;
      }

      final officialMeasuredAt = measuredAt ?? DateTime.now();
      final measurementText =
          '${widget.measurementType}: ${_formatFeetInches(distanceMeters!)} (${distanceFeet!.toStringAsFixed(2)} ft)';
      final meterText = '${distanceMeters!.toStringAsFixed(3)} metres';
      final applicationText = 'Application: ${widget.applicationId}';
      final gpsText =
          'GPS: ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
      final accuracyText = gpsAccuracy == null
          ? 'GPS Accuracy: -'
          : 'GPS Accuracy: +/-${gpsAccuracy!.toStringAsFixed(1)} m';
      final timeText = 'Measured At: ${officialMeasuredAt.toLocal()}';
      const methodText = 'Method: ARCORE_CENTER_RAYCAST';

      img.drawString(
        decoded,
        measurementText,
        font: img.arial24,
        x: 20,
        y: 20,
      );
      img.drawString(
        decoded,
        meterText,
        font: img.arial14,
        x: 20,
        y: 55,
      );
      img.drawString(
        decoded,
        applicationText,
        font: img.arial14,
        x: 20,
        y: 80,
      );
      img.drawString(
        decoded,
        gpsText,
        font: img.arial14,
        x: 20,
        y: 105,
      );
      img.drawString(
        decoded,
        accuracyText,
        font: img.arial14,
        x: 20,
        y: 130,
      );
      img.drawString(
        decoded,
        timeText,
        font: img.arial14,
        x: 20,
        y: 155,
      );
      img.drawString(
        decoded,
        methodText,
        font: img.arial14,
        x: 20,
        y: 180,
      );

      final directory = await getApplicationDocumentsDirectory();
      final safeApplicationId = widget.applicationId.replaceAll(
        RegExp(r'[^A-Za-z0-9_-]'),
        '_',
      );
      final filename =
          'measurement_${safeApplicationId}_${widget.measurementType}_${officialMeasuredAt.millisecondsSinceEpoch}.jpg';
      final file = File('${directory.path}/$filename');

      await file.writeAsBytes(
        img.encodeJpg(decoded, quality: 95),
        flush: true,
      );

      if (!mounted) return;
      setState(() {
        evidenceImagePath = file.path;
        evidenceSaving = false;
        instruction =
            'Evidence captured. Tap Use Measurement to send this value to Idol Verification.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        evidenceSaving = false;
        instruction = 'Unable to capture evidence image: $error';
      });
    }
  }

  void confirmMeasurement() {
    if (stage != MeasurementStage.measured ||
        startPoint == null ||
        endPoint == null ||
        distanceMeters == null ||
        distanceFeet == null) {
      setState(() {
        instruction = 'A valid AR measurement is required.';
      });
      return;
    }

    if (evidenceImagePath == null) {
      setState(() {
        instruction = 'Capture the evidence image before confirming.';
      });
      return;
    }

    if (latitude == null || longitude == null) {
      setState(() {
        instruction = 'GPS location is required before confirming.';
      });
      return;
    }

    final result = ArMeasurementResult(
      valueFeet: distanceFeet!,
      valueMeters: distanceMeters!,
      startX: startPoint!.x,
      startY: startPoint!.y,
      startZ: startPoint!.z,
      endX: endPoint!.x,
      endY: endPoint!.y,
      endZ: endPoint!.z,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracy: gpsAccuracy,
      measuredAt: measuredAt ?? DateTime.now(),
      measurementType: widget.measurementType,
      measurementMethod: 'ARCORE_CENTER_RAYCAST',
      evidenceImagePath: evidenceImagePath,
    );

    Navigator.pop(context, result);
  }

  String _formatFeetInches(double meters) {
    var totalInches = (meters * 39.37007874).round();
    var feet = totalInches ~/ 12;
    var inches = totalInches % 12;

    if (inches == 12) {
      feet += 1;
      inches = 0;
    }

    return '$feet\' $inches\"';
  }

  String get _stageText {
    switch (stage) {
      case MeasurementStage.scanning:
        return 'SCANNING';
      case MeasurementStage.readyForStart:
        return 'POINT A';
      case MeasurementStage.readyForEnd:
        return 'POINT B';
      case MeasurementStage.measured:
        return 'LOCKED';
    }
  }

  Color get _stageColor {
    switch (stage) {
      case MeasurementStage.scanning:
        return Colors.orange;
      case MeasurementStage.readyForStart:
        return Colors.white;
      case MeasurementStage.readyForEnd:
        return Colors.yellowAccent;
      case MeasurementStage.measured:
        return Colors.greenAccent;
    }
  }

  double? get _displayMeters {
    if (stage == MeasurementStage.measured) return distanceMeters;
    if (stage == MeasurementStage.readyForEnd) return liveDistanceMeters;
    return null;
  }

  @override
  void dispose() {
    _centerScanTimer?.cancel();
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayMeters = _displayMeters;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig:
                  PlaneDetectionConfig.horizontalAndVertical,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  _RoundGlassButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Idol $typeLabel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _RoundGlassButton(
                    icon: Icons.delete_outline,
                    onPressed: _clearMeasurement,
                  ),
                ],
              ),
            ),
          ),

          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (displayMeters != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_formatFeetInches(displayMeters)}  •  ${displayMeters.toStringAsFixed(2)} m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _MeasureReticle(
                    active: _hasFreshLivePoint,
                    locked: stage == MeasurementStage.measured,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: stage == MeasurementStage.measured ? 220 : 132,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _stageText,
                      style: TextStyle(
                        color: _stageColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      instruction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (stage != MeasurementStage.measured)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        child: TextButton.icon(
                          onPressed: stage == MeasurementStage.readyForEnd
                              ? _undo
                              : null,
                          icon: const Icon(Icons.undo),
                          label: const Text('Undo'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Semantics(
                        label: stage == MeasurementStage.readyForStart
                            ? 'Start measurement at Point A'
                            : 'End measurement at Point B',
                        button: true,
                        child: SizedBox(
                          width: 92,
                          height: 78,
                          child: FloatingActionButton.extended(
                            heroTag: 'ar_measure_add_point',
                            onPressed: _canPlacePoint ? _addPoint : null,
                            backgroundColor:
                                _canPlacePoint ? Colors.white : Colors.white38,
                            foregroundColor:
                                _canPlacePoint ? Colors.black : Colors.black45,
                            elevation: _canPlacePoint ? 4 : 0,
                            icon: Icon(
                              stage == MeasurementStage.readyForStart
                                  ? Icons.play_arrow
                                  : Icons.stop,
                            ),
                            label: Text(
                              stage == MeasurementStage.readyForStart
                                  ? 'START'
                                  : 'END',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 22),
                      const SizedBox(width: 72),
                    ],
                  ),
                ),
              ),
            ),

          if (stage == MeasurementStage.measured)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _undo,
                              icon: const Icon(Icons.undo),
                              label: const Text('Undo B'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed:
                                  evidenceSaving ? null : captureEvidenceImage,
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: Text(
                                evidenceSaving
                                    ? 'Saving...'
                                    : evidenceImagePath == null
                                        ? 'Evidence'
                                        : 'Retake',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (locationLoading) ...[
                        const SizedBox(height: 6),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 6),
                        const Text(
                          'Capturing GPS...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (evidenceImagePath != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.greenAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                gpsAccuracy == null
                                    ? 'Evidence captured.'
                                    : 'Evidence + GPS captured (±${gpsAccuracy!.toStringAsFixed(1)} m).',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: evidenceImagePath != null &&
                                  latitude != null &&
                                  longitude != null
                              ? confirmMeasurement
                              : null,
                          icon: const Icon(Icons.check),
                          label: const Text('Use Measurement'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeasureReticle extends StatelessWidget {
  final bool active;
  final bool locked;

  const _MeasureReticle({
    required this.active,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final color = locked
        ? Colors.greenAccent
        : active
            ? Colors.white
            : Colors.white70;

    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _MeasureReticlePainter(
          color: color,
          active: active,
        ),
      ),
    );
  }
}

class _MeasureReticlePainter extends CustomPainter {
  final Color color;
  final bool active;

  const _MeasureReticlePainter({
    required this.color,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final shadowPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 2.8 : 2.4
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final radius = active ? 16.0 : 15.0;
    const innerGap = 21.0;
    const outerExtent = 33.0;

    // Circle shadow + circle.
    canvas.drawCircle(center, radius, shadowPaint);
    canvas.drawCircle(center, radius, paint);

    // Four highly visible alignment ticks.
    final tickSegments = <List<Offset>>[
      [
        Offset(center.dx, center.dy - innerGap),
        Offset(center.dx, center.dy - outerExtent),
      ],
      [
        Offset(center.dx, center.dy + innerGap),
        Offset(center.dx, center.dy + outerExtent),
      ],
      [
        Offset(center.dx - innerGap, center.dy),
        Offset(center.dx - outerExtent, center.dy),
      ],
      [
        Offset(center.dx + innerGap, center.dy),
        Offset(center.dx + outerExtent, center.dy),
      ],
    ];

    for (final segment in tickSegments) {
      canvas.drawLine(segment[0], segment[1], shadowPaint);
      canvas.drawLine(segment[0], segment[1], paint);
    }

    // Centre aiming point.
    canvas.drawCircle(center, active ? 4.0 : 3.0, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _MeasureReticlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.active != active;
  }
}

class _RoundGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundGlassButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}
