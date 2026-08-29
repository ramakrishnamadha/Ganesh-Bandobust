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

class _ArMeasurementScreenState
    extends State<ArMeasurementScreen> {
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

  String? evidenceImagePath;

  MeasurementStage stage = MeasurementStage.scanning;

  String instruction =
      'Move the phone slowly from side to side so ARCore can detect the surroundings.';

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
        showFeaturePoints: true,
        showPlanes: true,
        showWorldOrigin: false,
        handleTaps: true,
      );

      sessionManager.onPlaneOrPointTap = handleHitResults;

      if (!mounted) return;

      setState(() {
        arReady = true;
        stage = MeasurementStage.readyForStart;
        instruction =
            'AR ready. Align the yellow centre pointer with Point A, then tap exactly at the centre pointer.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        instruction = 'Unable to initialize AR measurement: $error';
      });
    }
  }

  Vector3? _extractValidPoint(
    List<ARHitTestResult> hits,
  ) {
    if (hits.isEmpty) return null;

    for (final hit in hits) {
      final matrix = hit.worldTransform.storage;

      if (matrix.length < 15) continue;

      final x = matrix[12];
      final y = matrix[13];
      final z = matrix[14];

      if (!x.isFinite || !y.isFinite || !z.isFinite) {
        continue;
      }

      return Vector3(x, y, z);
    }

    return null;
  }

  void handleHitResults(
    List<ARHitTestResult> hits,
  ) {
    if (!arReady) return;

    if (stage == MeasurementStage.measured) {
      setState(() {
        instruction =
            'Measurement is locked. Use Reset if you want to measure again.';
      });
      return;
    }

    final point = _extractValidPoint(hits);

    if (point == null) {
      setState(() {
        instruction =
            'No stable AR surface detected. Keep the object well lit, move the phone slowly, align the centre pointer and try again.';
      });
      return;
    }

    if (stage == MeasurementStage.readyForStart ||
        startPoint == null) {
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

        stage = MeasurementStage.readyForEnd;

        instruction =
            'Point A fixed. Keep the same object in view, move the yellow pointer to Point B, then tap at the centre pointer.';
      });

      return;
    }

    if (stage == MeasurementStage.readyForEnd &&
        startPoint != null) {
      final start = startPoint!;

      final meters = sqrt(
        pow(point.x - start.x, 2) +
            pow(point.y - start.y, 2) +
            pow(point.z - start.z, 2),
      );

      if (!meters.isFinite) {
        setState(() {
          instruction =
              'Invalid AR measurement. Re-align the phone and try Point B again.';
        });
        return;
      }

      if (meters < minimumAcceptedMeters) {
        setState(() {
          instruction =
              'Point B is too close to Point A. Move the pointer to the actual opposite end of the object and try again.';
        });
        return;
      }

      if (meters > maximumAcceptedMeters) {
        setState(() {
          instruction =
              'ARCore reported an unrealistic jump (${meters.toStringAsFixed(2)} m). Keep the object in view and try Point B again.';
        });
        return;
      }

      setState(() {
        endPoint = point;
        distanceMeters = meters;
        distanceFeet = meters * 3.280839895;
        measuredAt = DateTime.now();
        evidenceImagePath = null;
        stage = MeasurementStage.measured;

        instruction =
            'Measurement locked successfully. GPS is being captured. Verify the value before capturing evidence.';
      });

      captureGps();
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
            'Measurement and GPS captured. If the value looks correct, capture the evidence image.';
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

    final imageStream = provider.resolve(
      ImageConfiguration.empty,
    );

    late ImageStreamListener listener;

    listener = ImageStreamListener(
      (
        ImageInfo imageInfo,
        bool synchronousCall,
      ) async {
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
      onError: (
        Object error,
        StackTrace? stackTrace,
      ) {
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
      setState(() {
        instruction =
            'GPS is required before evidence capture. Capturing location now...';
      });

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
      final ImageProvider<Object> provider =
          await arSessionManager!.snapshot();

      final Uint8List? screenshot =
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
          '${widget.measurementType}: '
          '${distanceFeet!.toStringAsFixed(2)} ft';

      final meterText =
          '${distanceMeters!.toStringAsFixed(3)} metres';

      final applicationText =
          'Application: ${widget.applicationId}';

      final gpsText =
          'GPS: '
          '${latitude!.toStringAsFixed(6)}, '
          '${longitude!.toStringAsFixed(6)}';

      final accuracyText =
          gpsAccuracy == null
              ? 'GPS Accuracy: -'
              : 'GPS Accuracy: +/-${gpsAccuracy!.toStringAsFixed(1)} m';

      final timeText =
          'Measured At: ${officialMeasuredAt.toLocal()}';

      const methodText =
          'Method: AR_3D_HIT_TEST';

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
          'measurement_'
          '${safeApplicationId}_'
          '${widget.measurementType}_'
          '${officialMeasuredAt.millisecondsSinceEpoch}.jpg';

      final file =
          File('${directory.path}/$filename');

      await file.writeAsBytes(
        img.encodeJpg(
          decoded,
          quality: 95,
        ),
        flush: true,
      );

      if (!mounted) return;

      setState(() {
        evidenceImagePath = file.path;
        evidenceSaving = false;

        instruction =
            'Evidence image captured. Review the image and measurement, then tap Use Measurement.';
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

  void resetMeasurement() {
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

      stage = arReady
          ? MeasurementStage.readyForStart
          : MeasurementStage.scanning;

      instruction = arReady
          ? 'Measurement reset. Align the yellow centre pointer with Point A and tap at the centre.'
          : 'Move the phone slowly so ARCore can detect the surroundings.';
    });
  }

  void confirmMeasurement() {
    if (stage != MeasurementStage.measured ||
        startPoint == null ||
        endPoint == null ||
        distanceMeters == null ||
        distanceFeet == null) {
      setState(() {
        instruction =
            'A valid AR measurement is required.';
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

    final result =
        ArMeasurementResult(
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
      measurementMethod: 'AR_3D_HIT_TEST',
      evidenceImagePath: evidenceImagePath,
    );

    Navigator.pop(context, result);
  }

  String get stageText {
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

  Color get stageColor {
    switch (stage) {
      case MeasurementStage.scanning:
        return Colors.orange;
      case MeasurementStage.readyForStart:
        return Colors.yellow;
      case MeasurementStage.readyForEnd:
        return Colors.cyanAccent;
      case MeasurementStage.measured:
        return Colors.greenAccent;
    }
  }

  @override
  void dispose() {
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
                    PlaneDetectionConfig
                        .horizontalAndVertical,
              ),
            ),

            const IgnorePointer(
              child: Center(
                child: _ArCenterPointer(),
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
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
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
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          Text(
                            'Measure Idol $typeLabel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
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
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: stageColor,
                        ),
                      ),
                      child: Text(
                        stageText,
                        style: TextStyle(
                          color: stageColor,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: evidenceImagePath == null
                  ? 255
                  : 365,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.74,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      instruction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    if (!arReady) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(),
                    ],

                    if (startPoint != null &&
                        stage ==
                            MeasurementStage
                                .readyForEnd) ...[
                      const SizedBox(height: 10),
                      const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color:
                                Colors.greenAccent,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Point A fixed',
                            style: TextStyle(
                              color:
                                  Colors.greenAccent,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (distanceFeet != null) ...[
                      const SizedBox(height: 12),

                      Text(
                        '${distanceFeet!.toStringAsFixed(2)} ft',
                        style: const TextStyle(
                          color:
                              Colors.greenAccent,
                          fontSize: 36,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      Text(
                        '${distanceMeters!.toStringAsFixed(3)} metres',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      if (measuredAt != null)
                        Text(
                          'Measured: ${measuredAt!.toLocal()}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
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
                  color: Colors.black.withValues(
                    alpha: 0.82,
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Text(
                      'Keep the yellow centre dot exactly on the point you want to measure before tapping.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (locationLoading) ...[
                      const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(
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
                      const SizedBox(height: 10),
                    ],

                    if (latitude != null &&
                        longitude != null) ...[
                      Text(
                        'GPS '
                        '${latitude!.toStringAsFixed(6)}, '
                        '${longitude!.toStringAsFixed(6)}'
                        '${gpsAccuracy == null ? '' : ' | +/-${gpsAccuracy!.toStringAsFixed(1)} m'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (distanceFeet != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: evidenceSaving
                              ? null
                              : captureEvidenceImage,
                          icon: const Icon(
                            Icons.camera_alt,
                          ),
                          label: Text(
                            evidenceSaving
                                ? 'Saving Evidence...'
                                : evidenceImagePath ==
                                        null
                                    ? 'Capture Evidence Image'
                                    : 'Retake Evidence Image',
                          ),
                          style:
                              FilledButton.styleFrom(
                            backgroundColor:
                                const Color(
                              0xFF17365D,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (evidenceImagePath != null) ...[
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(10),
                        child: Image.file(
                          File(evidenceImagePath!),
                          width: double.infinity,
                          height: 105,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color:
                                Colors.greenAccent,
                            size: 18,
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Evidence captured with measurement, GPS and timestamp.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child:
                              OutlinedButton.icon(
                            onPressed:
                                resetMeasurement,
                            icon: const Icon(
                              Icons.refresh,
                            ),
                            label:
                                const Text('Reset'),
                            style:
                                OutlinedButton
                                    .styleFrom(
                              foregroundColor:
                                  Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: FilledButton.icon(
                            onPressed: stage ==
                                            MeasurementStage
                                                .measured &&
                                        evidenceImagePath !=
                                            null &&
                                        latitude != null &&
                                        longitude != null
                                    ? confirmMeasurement
                                    : null,
                            icon: const Icon(
                              Icons.check,
                            ),
                            label: const Text(
                              'Use Measurement',
                            ),
                            style:
                                FilledButton.styleFrom(
                              backgroundColor:
                                  Colors.green,
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

class _ArCenterPointer extends StatelessWidget {
  const _ArCenterPointer();

  @override
  Widget build(BuildContext context) {
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
                color: Colors.yellow,
                width: 2,
              ),
            ),
          ),

          Container(
            width: 3,
            height: 80,
            color: Colors.yellow,
          ),

          Container(
            width: 80,
            height: 3,
            color: Colors.yellow,
          ),

          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.yellow,
            ),
          ),
        ],
      ),
    );
  }
}
