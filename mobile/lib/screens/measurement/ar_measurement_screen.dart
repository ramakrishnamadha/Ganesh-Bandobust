import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/widgets/ar_view.dart';
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

  double? distanceMeters;
  double? distanceFeet;

  double? latitude;
  double? longitude;
  double? gpsAccuracy;
  DateTime? measuredAt;

  bool locationLoading = false;
  bool evidenceSaving = false;
  bool arReady = false;
  bool lockingPoint = false;

  String? evidenceImagePath;

  MeasurementStage stage = MeasurementStage.scanning;

  String instruction =
      'Move the phone slowly from side to side so ARCore can detect the surroundings.';

  Timer? _liveTimer;

  Map<String, dynamic>? _heightRuler;
  Map<String, dynamic>? _verticalGuide;
  Map<String, dynamic>? _widthAnchorScreen;
  double? _widthLiveMeters;
  Map<String, double>? _liveCenterHit;

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

  bool get isHeight => widget.measurementType == 'HEIGHT';

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
        showAnimatedGuide: false,
        showFeaturePoints: true,
        showPlanes: true,
        showWorldOrigin: false,
        handleTaps: false,
      );

      if (!mounted) return;

      setState(() {
        arReady = true;
        stage = MeasurementStage.readyForStart;
        instruction =
            'Align the green reticle with the bottom Point A, then press START.';
      });

      _startLiveUpdates();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        instruction = 'Unable to initialize AR measurement: $error';
      });
    }
  }

  void _startLiveUpdates() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) => _updateLiveMeasurement(),
    );
  }

  Future<void> _updateLiveMeasurement() async {
    final manager = arSessionManager;
    if (!mounted || manager == null || !arReady || lockingPoint) {
      return;
    }

    try {
      if (stage == MeasurementStage.readyForStart) {
        final hit = await manager.getCenterHitTest();
        if (!mounted) return;
        setState(() {
          _liveCenterHit = hit;
        });
        return;
      }

      if (stage == MeasurementStage.readyForEnd && startPoint != null) {
        if (isHeight) {
          final ruler = await manager.getNativeHeightRuler();
          final guide =
              await manager.getMeasurementVerticalGuideScreenPosition();

          if (!mounted) return;

          setState(() {
            _heightRuler = ruler;
            _verticalGuide = guide;
          });
        } else {
          final anchorScreen =
              await manager.getMeasurementAnchorScreenPosition();
          final hit = await manager.getCenterHitTest();

          double? liveMeters;

          if (hit != null) {
            final livePoint = Vector3(
              hit['x']!,
              hit['y']!,
              hit['z']!,
            );

            liveMeters = (livePoint - startPoint!).length;
          }

          if (!mounted) return;

          setState(() {
            _widthAnchorScreen = anchorScreen;
            _liveCenterHit = hit;
            _widthLiveMeters = liveMeters;
          });
        }
      }
    } catch (_) {
      // Keep the current visual state and allow the next AR frame to retry.
    }
  }

  Future<void> _lockPointA() async {
    final manager = arSessionManager;

    if (manager == null ||
        !arReady ||
        stage != MeasurementStage.readyForStart ||
        lockingPoint) {
      return;
    }

    setState(() {
      lockingPoint = true;
      instruction = 'Locking Point A...';
    });

    try {
      await manager.clearMeasurementAnchor();

      Map<String, double>? position;

      // Give ARCore a few very short chances to use the current or cached
      // tracked pose. This is especially helpful for WIDTH when the reticle
      // is aimed at an edge or a narrow surface.
      for (var attempt = 0; attempt < 3; attempt++) {
        position = await manager.lockCenterMeasurementAnchor();

        if (position != null) {
          break;
        }

        if (attempt < 2) {
          await Future.delayed(
            const Duration(milliseconds: 120),
          );
        }
      }

      if (!mounted) return;

      if (position == null) {
        setState(() {
          lockingPoint = false;
          instruction =
              'Point A could not be locked. Keep the reticle on Point A, move the phone slowly, and press START again.';
        });
        return;
      }

      final point = Vector3(
        position['x']!,
        position['y']!,
        position['z']!,
      );

      setState(() {
        startPoint = point;
        endPoint = null;
        distanceMeters = null;
        distanceFeet = null;
        latitude = null;
        longitude = null;
        gpsAccuracy = null;
        measuredAt = null;
        evidenceImagePath = null;
        _heightRuler = null;
        _verticalGuide = null;
        _widthAnchorScreen = null;
        _widthLiveMeters = null;
        lockingPoint = false;
        stage = MeasurementStage.readyForEnd;
        instruction = isHeight
            ? 'POINT A LOCKED. Move the phone upward until the green reticle reaches the top Point B. The ruler will extend from Point A. Then press END.'
            : 'POINT A LOCKED. Move the green reticle horizontally to Point B. The ruler will extend from Point A. Then press END.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        lockingPoint = false;
        instruction = 'Unable to lock Point A: $error';
      });
    }
  }

  Future<void> _lockPointB() async {
    final manager = arSessionManager;

    if (manager == null ||
        startPoint == null ||
        stage != MeasurementStage.readyForEnd ||
        lockingPoint) {
      return;
    }

    setState(() {
      lockingPoint = true;
      instruction = 'Locking Point B...';
    });

    try {
      Vector3? point;
      double? meters;

      if (isHeight) {
        final ruler =
            await manager.getNativeHeightRuler();

        if (ruler != null) {
          final end = ruler['endWorld'];

          if (end is Map) {
            final x = end['x'];
            final y = end['y'];
            final z = end['z'];

            if (x is num && y is num && z is num) {
              point = Vector3(
                x.toDouble(),
                y.toDouble(),
                z.toDouble(),
              );
            }
          }

          final rawMeters = ruler['meters'];
          if (rawMeters is num) {
            meters = rawMeters.toDouble();
          }
        }
      } else {
        final hit = await manager.getCenterHitTest();

        if (hit != null) {
          point = Vector3(
            hit['x']!,
            hit['y']!,
            hit['z']!,
          );

          meters = (point - startPoint!).length;
        }
      }

      if (!mounted) return;

      if (point == null || meters == null || !meters.isFinite) {
        setState(() {
          lockingPoint = false;
          instruction =
              'Point B could not be locked. Keep the reticle exactly on Point B and press END again.';
        });
        return;
      }

      if (meters < minimumAcceptedMeters) {
        setState(() {
          lockingPoint = false;
          instruction =
              'Point B is too close to Point A. Move the reticle to the actual end point and press END again.';
        });
        return;
      }

      if (meters > maximumAcceptedMeters) {
        setState(() {
          lockingPoint = false;
          instruction =
              'The measured distance is unrealistic. Reset and measure again.';
        });
        return;
      }

      setState(() {
        endPoint = point;
        distanceMeters = meters;
        distanceFeet = meters! * 3.280839895;
        measuredAt = DateTime.now();
        evidenceImagePath = null;
        lockingPoint = false;
        stage = MeasurementStage.measured;
        instruction =
            'POINT B LOCKED. Measurement completed. GPS is being captured.';
      });

      await captureGps();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        lockingPoint = false;
        instruction = 'Unable to lock Point B: $error';
      });
    }
  }

  Future<void> captureGps() async {
    if (locationLoading || !mounted) return;

    setState(() {
      locationLoading = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          locationLoading = false;
          instruction =
              'Measurement completed, but GPS is disabled. Enable location services before capturing evidence.';
        });
        return;
      }

      var permission =
          await Geolocator.checkPermission();

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

      final position =
          await Geolocator.getCurrentPosition(
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
            'Measurement and GPS captured. Capture the evidence image, then use the measurement.';
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
    final imageStream =
        provider.resolve(ImageConfiguration.empty);

    late ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo imageInfo, bool synchronousCall) async {
        try {
          final byteData =
              await imageInfo.image.toByteData(
            format: ui.ImageByteFormat.png,
          );

          if (!completer.isCompleted) {
            completer.complete(
              byteData?.buffer.asUint8List(),
            );
          }
        } catch (_) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        } finally {
          imageStream.removeListener(listener);
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        imageStream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete(null);
        }
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
        instruction =
            'Complete and lock the AR measurement before capturing evidence.';
      });
      return;
    }

    if (latitude == null || longitude == null) {
      await captureGps();
      if (latitude == null || longitude == null) {
        return;
      }
    }

    setState(() {
      evidenceSaving = true;
      instruction = 'Capturing AR evidence image...';
    });

    try {
      final provider =
          await arSessionManager!.snapshot();

      final screenshot =
          await imageProviderToPngBytes(provider);

      if (screenshot == null) {
        if (!mounted) return;
        setState(() {
          evidenceSaving = false;
          instruction =
              'Unable to convert the AR snapshot into an evidence image.';
        });
        return;
      }

      final decoded = img.decodeImage(screenshot);

      if (decoded == null) {
        if (!mounted) return;
        setState(() {
          evidenceSaving = false;
          instruction =
              'Unable to process the captured AR evidence image.';
        });
        return;
      }

      final officialMeasuredAt =
          measuredAt ?? DateTime.now();

      final measurementText =
          '${widget.measurementType}: ${_formatFeetInches(distanceFeet!)}';

      final meterText =
          '${distanceMeters!.toStringAsFixed(3)} metres';

      final applicationText =
          'Application: ${widget.applicationId}';

      final gpsText =
          'GPS: ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';

      final accuracyText = gpsAccuracy == null
          ? 'GPS Accuracy: -'
          : 'GPS Accuracy: +/-${gpsAccuracy!.toStringAsFixed(1)} m';

      final timeText =
          'Measured At: ${officialMeasuredAt.toLocal()}';

      final methodText = isHeight
          ? 'Method: ARCORE_ANCHORED_VERTICAL_RULER'
          : 'Method: ARCORE_ANCHORED_WIDTH_RULER';

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

      final directory =
          await getApplicationDocumentsDirectory();

      final safeApplicationId =
          widget.applicationId.replaceAll(
        RegExp(r'[^A-Za-z0-9_-]'),
        '_',
      );

      final filename =
          'measurement_${safeApplicationId}_${widget.measurementType}_${officialMeasuredAt.millisecondsSinceEpoch}.jpg';

      final file =
          File('${directory.path}/$filename');

      await file.writeAsBytes(
        img.encodeJpg(decoded, quality: 95),
        flush: true,
      );

      if (!mounted) return;

      setState(() {
        evidenceImagePath = file.path;
        evidenceSaving = false;
        instruction =
            'Evidence captured. Tap Use Measurement to return this value to Idol Verification.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        evidenceSaving = false;
        instruction =
            'Unable to capture evidence image: $error';
      });
    }
  }

  Future<void> resetMeasurement() async {
    _liveTimer?.cancel();

    try {
      await arSessionManager?.clearMeasurementAnchor();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      startPoint = null;
      endPoint = null;
      distanceMeters = null;
      distanceFeet = null;
      latitude = null;
      longitude = null;
      gpsAccuracy = null;
      measuredAt = null;
      evidenceImagePath = null;
      _heightRuler = null;
      _verticalGuide = null;
      _widthAnchorScreen = null;
      _widthLiveMeters = null;
      _liveCenterHit = null;
      lockingPoint = false;

      stage = arReady
          ? MeasurementStage.readyForStart
          : MeasurementStage.scanning;

      instruction = arReady
          ? 'Measurement reset. Align the green reticle with Point A and press START.'
          : 'Move the phone slowly so ARCore can detect the surroundings.';
    });

    _startLiveUpdates();
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
        instruction =
            'Please capture the measurement evidence image before confirming.';
      });
      return;
    }

    if (latitude == null || longitude == null) {
      setState(() {
        instruction =
            'GPS location is required before confirming this official measurement.';
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
      measurementMethod: isHeight
          ? 'ARCORE_ANCHORED_VERTICAL_RULER'
          : 'ARCORE_ANCHORED_WIDTH_RULER',
      evidenceImagePath: evidenceImagePath,
    );

    Navigator.pop(context, result);
  }

  String _formatFeetInches(double valueFeet) {
    var totalInches = (valueFeet * 12).round();
    if (totalInches < 0) totalInches = 0;

    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;

    return "$feet ft $inches in";
  }

  String get stageText {
    switch (stage) {
      case MeasurementStage.scanning:
        return 'SCANNING';
      case MeasurementStage.readyForStart:
        return 'POINT A';
      case MeasurementStage.readyForEnd:
        return 'POINT A LOCKED';
      case MeasurementStage.measured:
        return 'POINT B LOCKED';
    }
  }

  Color get stageColor {
    switch (stage) {
      case MeasurementStage.scanning:
        return Colors.orange;
      case MeasurementStage.readyForStart:
        return _liveCenterHit == null
            ? Colors.orange
            : Colors.greenAccent;
      case MeasurementStage.readyForEnd:
        return Colors.greenAccent;
      case MeasurementStage.measured:
        return Colors.greenAccent;
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: ARView(
                onARViewCreated: onARViewCreated,
                planeDetectionConfig:
                    PlaneDetectionConfig.horizontalAndVertical,
              ),
            ),

            if (isHeight &&
                stage == MeasurementStage.readyForEnd &&
                _heightRuler != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _HeightRulerPainter(
                      ruler: _heightRuler!,
                      verticalGuide: _verticalGuide,
                    ),
                  ),
                ),
              ),

            if (!isHeight &&
                stage == MeasurementStage.readyForEnd &&
                _widthAnchorScreen != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _WidthRulerPainter(
                      anchorScreen: _widthAnchorScreen!,
                      meters: _widthLiveMeters,
                    ),
                  ),
                ),
              ),

            IgnorePointer(
              child: Center(
                child: _ArGreenReticle(
                  ready: stage != MeasurementStage.readyForStart ||
                      _liveCenterHit != null,
                ),
              ),
            ),

            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DIGITAL AR MEASUREMENT',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Measure Idol $typeLabel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.applicationId,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: stageColor),
                      ),
                      child: Text(
                        stageText,
                        style: TextStyle(
                          color: stageColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (stage == MeasurementStage.readyForEnd)
              Positioned(
                left: 12,
                top: 118,
                width: 220,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.greenAccent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            color: Colors.greenAccent,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'POINT A LOCKED',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        instruction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      if (isHeight &&
                          _heightRuler?['meters'] is num) ...[
                        const SizedBox(height: 7),
                        Text(
                          'Live Height: ${_formatFeetInches((_heightRuler!['meters'] as num).toDouble() * 3.280839895)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      if (!isHeight &&
                          _widthLiveMeters != null) ...[
                        const SizedBox(height: 7),
                        Text(
                          'Live Width: ${_formatFeetInches(_widthLiveMeters! * 3.280839895)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Positioned(
                left: 16,
                right: 16,
                bottom: evidenceImagePath == null ? 250 : 360,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.76),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        instruction,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (!arReady) ...[
                        const SizedBox(height: 10),
                        const LinearProgressIndicator(),
                      ],

                      if (distanceFeet != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'MEASURED RESULT',
                                style: TextStyle(
                                  color: Color(0xFF166534),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatFeetInches(distanceFeet!),
                                style: const TextStyle(
                                  color: Color(0xFF166534),
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${distanceMeters!.toStringAsFixed(3)} metres',
                                style: const TextStyle(
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stage == MeasurementStage.readyForStart) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: arReady && !lockingPoint
                              ? _lockPointA
                              : null,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            lockingPoint
                                ? 'LOCKING POINT A...'
                                : 'START - LOCK POINT A',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],

                    if (stage == MeasurementStage.readyForEnd) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: !lockingPoint
                              ? _lockPointB
                              : null,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: Text(
                            lockingPoint
                                ? 'LOCKING POINT B...'
                                : 'END - LOCK POINT B',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],

                    if (locationLoading) ...[
                      const SizedBox(height: 10),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Capturing GPS...',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (distanceFeet != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: evidenceSaving
                              ? null
                              : captureEvidenceImage,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            evidenceSaving
                                ? 'Saving Evidence...'
                                : evidenceImagePath == null
                                    ? 'Capture Evidence Image'
                                    : 'Retake Evidence Image',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF17365D),
                          ),
                        ),
                      ),
                    ],

                    if (evidenceImagePath != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(evidenceImagePath!),
                          width: double.infinity,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: resetMeasurement,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: stage ==
                                            MeasurementStage.measured &&
                                        evidenceImagePath != null &&
                                        latitude != null &&
                                        longitude != null
                                    ? confirmMeasurement
                                    : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Use Measurement'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArGreenReticle extends StatelessWidget {
  final bool ready;

  const _ArGreenReticle({
    required this.ready,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        ready ? Colors.greenAccent : Colors.orangeAccent;

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: 2,
              ),
            ),
          ),
          Container(
            width: 3,
            height: 80,
            color: color,
          ),
          Container(
            width: 80,
            height: 3,
            color: color,
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


class _WidthRulerPainter extends CustomPainter {
  final Map<String, dynamic> anchorScreen;
  final double? meters;

  const _WidthRulerPainter({
    required this.anchorScreen,
    required this.meters,
  });

  Offset? _anchorPoint(Size size) {
    final x = anchorScreen['x'];
    final y = anchorScreen['y'];

    if (x is! num || y is! num) {
      return null;
    }

    return Offset(
      x.toDouble() * size.width,
      y.toDouble() * size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final start = _anchorPoint(size);

    if (start == null) {
      return;
    }

    // Point B is always the centre reticle while the officer moves the phone.
    final end = Offset(
      size.width / 2,
      size.height / 2,
    );

    final linePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final tickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    canvas.drawLine(start, end, linePaint);

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = (Offset(dx, dy)).distance;

    if (length > 5) {
      const tickSpacing = 28.0;

      final ux = dx / length;
      final uy = dy / length;

      // Perpendicular direction for ruler ticks.
      final px = -uy;
      final py = ux;

      for (double d = 0; d <= length; d += tickSpacing) {
        final cx = start.dx + (ux * d);
        final cy = start.dy + (uy * d);

        final major =
            ((d / tickSpacing).round() % 4) == 0;

        final tickLength = major ? 22.0 : 12.0;
        final half = tickLength / 2;

        canvas.drawLine(
          Offset(
            cx - (px * half),
            cy - (py * half),
          ),
          Offset(
            cx + (px * half),
            cy + (py * half),
          ),
          tickPaint,
        );
      }
    }

    canvas.drawCircle(
      start,
      9,
      Paint()..color = Colors.greenAccent,
    );

    canvas.drawCircle(
      end,
      9,
      Paint()..color = Colors.redAccent,
    );

    if (meters != null &&
        meters!.isFinite &&
        meters! >= 0) {
      final feet = meters! * 3.280839895;
      var totalInches = (feet * 12).round();

      if (totalInches < 0) {
        totalInches = 0;
      }

      final wholeFeet = totalInches ~/ 12;
      final inches = totalInches % 12;

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$wholeFeet ft $inches in',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final mid = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2,
      );

      final labelOffset = Offset(
        mid.dx + 14,
        mid.dy - textPainter.height - 8,
      );

      textPainter.paint(
        canvas,
        labelOffset,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _WidthRulerPainter oldDelegate,
  ) {
    return true;
  }
}

class _HeightRulerPainter extends CustomPainter {
  final Map<String, dynamic> ruler;
  final Map<String, dynamic>? verticalGuide;

  const _HeightRulerPainter({
    required this.ruler,
    required this.verticalGuide,
  });

  Offset? _screenPoint(
    dynamic raw,
    Size size,
  ) {
    if (raw is! Map) return null;

    final x = raw['x'];
    final y = raw['y'];

    if (x is! num || y is! num) {
      return null;
    }

    return Offset(
      x.toDouble() * size.width,
      y.toDouble() * size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final start =
        _screenPoint(ruler['startScreen'], size);

    final end =
        _screenPoint(ruler['endScreen'], size);

    if (start == null || end == null) {
      return;
    }

    final linePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final tickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    canvas.drawLine(start, end, linePaint);

    final dy = end.dy - start.dy;
    final length = dy.abs();

    if (length > 5) {
      const tickSpacing = 28.0;
      final direction = dy >= 0 ? 1.0 : -1.0;

      for (double d = 0; d <= length; d += tickSpacing) {
        final y = start.dy + (direction * d);

        final major =
            ((d / tickSpacing).round() % 4) == 0;

        final tickLength = major ? 22.0 : 12.0;

        canvas.drawLine(
          Offset(start.dx - tickLength / 2, y),
          Offset(start.dx + tickLength / 2, y),
          tickPaint,
        );
      }
    }

    canvas.drawCircle(
      start,
      9,
      Paint()..color = Colors.greenAccent,
    );

    canvas.drawCircle(
      end,
      9,
      Paint()..color = Colors.redAccent,
    );

    final meters = ruler['meters'];

    if (meters is num) {
      final feet = meters.toDouble() * 3.280839895;
      var totalInches = (feet * 12).round();
      if (totalInches < 0) totalInches = 0;

      final wholeFeet = totalInches ~/ 12;
      final inches = totalInches % 12;

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$wholeFeet ft $inches in',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelOffset = Offset(
        start.dx + 18,
        (start.dy + end.dy) / 2 -
            textPainter.height / 2,
      );

      textPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(
    covariant _HeightRulerPainter oldDelegate,
  ) {
    return true;
  }
}
