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

import 'package:vector_math/vector_math_64.dart'
    show Vector3;

import '../../models/ar_measurement_result.dart';

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

  String instruction =
      'Move the phone slowly so the device can understand the surroundings.';

  String get typeLabel {
    if (widget.measurementType == 'HEIGHT') {
      return 'Height';
    }

    if (widget.measurementType == 'WIDTH') {
      return 'Width';
    }

    return 'Length';
  }

  /* =========================================================
     AR INITIALIZATION
  ========================================================= */

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

    await sessionManager.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );

    sessionManager.onPlaneOrPointTap =
        handleHitResults;

    if (!mounted) {
      return;
    }

    setState(() {
      arReady = true;
      instruction =
          'AR ready. Tap the first point of the object.';
    });
  }

  /* =========================================================
     HANDLE REAL-WORLD HIT RESULTS
  ========================================================= */

  void handleHitResults(
    List<ARHitTestResult> hits,
  ) {
    if (hits.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        instruction =
            'No surface detected at that point. Move the device slowly and try again.';
      });

      return;
    }

    final hit = hits.first;
    final matrix = hit.worldTransform.storage;

    final point = Vector3(
      matrix[12],
      matrix[13],
      matrix[14],
    );

    /*
      First tap = start point.
    */

    if (startPoint == null) {
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

        instruction =
            'Start point fixed. Tap the second point.';
      });

      return;
    }

    /*
      Second tap = end point.
      Calculate true 3D straight-line distance.
    */

    if (endPoint == null) {
      final start = startPoint!;

      final meters = sqrt(
        pow(point.x - start.x, 2) +
            pow(point.y - start.y, 2) +
            pow(point.z - start.z, 2),
      );

      setState(() {
        endPoint = point;

        distanceMeters = meters;
        distanceFeet =
            meters * 3.280839895;

        measuredAt = DateTime.now();

        evidenceImagePath = null;

        instruction =
            'Measurement completed. GPS is being captured. Review the result, then capture evidence.';
      });

      captureGps();

      return;
    }

    /*
      Third tap starts a completely new measurement.
    */

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

      instruction =
          'New start point fixed. Tap the second point.';
    });
  }

  /* =========================================================
     GPS
  ========================================================= */

  Future<void> captureGps() async {
    if (locationLoading) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      locationLoading = true;
    });

    try {
      final serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) {
          return;
        }

        setState(() {
          locationLoading = false;

          instruction =
              'Measurement completed, but GPS is disabled. Enable location services before capturing evidence.';
        });

        return;
      }

      var permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator
                .requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission
                  .deniedForever) {
        if (!mounted) {
          return;
        }

        setState(() {
          locationLoading = false;

          instruction =
              'Measurement completed, but location permission is unavailable.';
        });

        return;
      }

      final position =
          await Geolocator
              .getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        latitude =
            position.latitude;

        longitude =
            position.longitude;

        gpsAccuracy =
            position.accuracy;

        locationLoading =
            false;

        instruction =
            'Measurement and GPS captured. Capture the evidence image.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        locationLoading = false;

        instruction =
            'Measurement completed, but GPS could not be captured.';
      });
    }
  }

  /* =========================================================
     CONVERT SNAPSHOT IMAGEPROVIDER TO BYTES

     ar_flutter_plugin_plus 1.1.3 snapshot()
     returns ImageProvider<Object>.
  ========================================================= */

  Future<Uint8List?> imageProviderToPngBytes(
    ImageProvider<Object> provider,
  ) async {
    final completer =
        Completer<Uint8List?>();

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
        } catch (error) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        } finally {
          imageStream.removeListener(
            listener,
          );
        }
      },
      onError: (
        Object error,
        StackTrace? stackTrace,
      ) {
        imageStream.removeListener(
          listener,
        );

        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );

    imageStream.addListener(listener);

    return completer.future;
  }

  /* =========================================================
     CAPTURE EVIDENCE IMAGE
  ========================================================= */

  Future<void> captureEvidenceImage() async {
    if (arSessionManager == null ||
        distanceFeet == null ||
        distanceMeters == null ||
        startPoint == null ||
        endPoint == null) {
      setState(() {
        instruction =
            'Complete the AR measurement before capturing evidence.';
      });

      return;
    }

    /*
      Require GPS before official evidence capture.
    */

    if (latitude == null ||
        longitude == null) {
      setState(() {
        instruction =
            'GPS is required before evidence capture. Waiting for location...';
      });

      await captureGps();

      if (latitude == null ||
          longitude == null) {
        return;
      }
    }

    setState(() {
      evidenceSaving = true;

      instruction =
          'Capturing AR evidence image...';
    });

    try {
      /*
        Plugin 1.1.3 returns ImageProvider<Object>.
      */

      final ImageProvider<Object> provider =
          await arSessionManager!.snapshot();

      final Uint8List? screenshot =
          await imageProviderToPngBytes(
        provider,
      );

      if (screenshot == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          evidenceSaving = false;

          instruction =
              'Unable to convert the AR snapshot into an evidence image.';
        });

        return;
      }

      final decoded =
          img.decodeImage(screenshot);

      if (decoded == null) {
        if (!mounted) {
          return;
        }

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
              : 'GPS Accuracy: '
                  '+/-${gpsAccuracy!.toStringAsFixed(1)} m';

      final timeText =
          'Measured At: '
          '${officialMeasuredAt.toLocal()}';

      const methodText =
          'Method: AR_3D_HIT_TEST';

      /*
        Burn the key evidence information directly
        into the stored evidence image.
      */

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

      final file = File(
        '${directory.path}/$filename',
      );

      await file.writeAsBytes(
        img.encodeJpg(
          decoded,
          quality: 95,
        ),
        flush: true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        evidenceImagePath =
            file.path;

        evidenceSaving = false;

        instruction =
            'Evidence image captured successfully. Review it below, then use the measurement.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        evidenceSaving = false;

        instruction =
            'Unable to capture evidence image: $error';
      });
    }
  }

  /* =========================================================
     RESET
  ========================================================= */

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

      instruction =
          'Measurement reset. Tap the first point.';
    });
  }

  /* =========================================================
     CONFIRM RESULT
  ========================================================= */

  void confirmMeasurement() {
    if (startPoint == null ||
        endPoint == null ||
        distanceMeters == null ||
        distanceFeet == null) {
      return;
    }

    if (evidenceImagePath == null) {
      setState(() {
        instruction =
            'Please capture the measurement evidence image before confirming.';
      });

      return;
    }

    if (latitude == null ||
        longitude == null) {
      setState(() {
        instruction =
            'GPS location is required before confirming this official measurement.';
      });

      return;
    }

    final result =
        ArMeasurementResult(
      valueFeet:
          distanceFeet!,

      valueMeters:
          distanceMeters!,

      startX:
          startPoint!.x,

      startY:
          startPoint!.y,

      startZ:
          startPoint!.z,

      endX:
          endPoint!.x,

      endY:
          endPoint!.y,

      endZ:
          endPoint!.z,

      latitude:
          latitude,

      longitude:
          longitude,

      gpsAccuracy:
          gpsAccuracy,

      measuredAt:
          measuredAt ?? DateTime.now(),

      measurementType:
          widget.measurementType,

      measurementMethod:
          'AR_3D_HIT_TEST',

      evidenceImagePath:
          evidenceImagePath,
    );

    Navigator.pop(
      context,
      result,
    );
  }

  /* =========================================================
     DISPOSE
  ========================================================= */

  @override
  void dispose() {
    arSessionManager?.dispose();

    super.dispose();
  }

  /* =========================================================
     UI
  ========================================================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black,

      body: SafeArea(
        child: Stack(
          children: [
            /* =================================================
               AR CAMERA VIEW
            ================================================= */

            Positioned.fill(
              child: ARView(
                onARViewCreated:
                    onARViewCreated,

                planeDetectionConfig:
                    PlaneDetectionConfig
                        .horizontalAndVertical,
              ),
            ),

            /* =================================================
               CENTRAL POINTER
            ================================================= */

            const IgnorePointer(
              child: Center(
                child: _ArCenterPointer(),
              ),
            ),

            /* =================================================
               TOP BAR
            ================================================= */

            Positioned(
              left: 12,
              right: 12,
              top: 12,

              child: Container(
                padding:
                    const EdgeInsets
                        .all(14),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.black54,

                  borderRadius:
                      BorderRadius
                          .circular(14),
                ),

                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },

                      icon:
                          const Icon(
                        Icons.arrow_back,
                        color:
                            Colors.white,
                      ),
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          const Text(
                            'DIGITAL AR MEASUREMENT',
                            style:
                                TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          Text(
                            'Measure Idol $typeLabel',
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          Text(
                            widget.applicationId,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /* =================================================
               INSTRUCTION / RESULT PANEL
            ================================================= */

            Positioned(
              left: 16,
              right: 16,
              bottom:
                  evidenceImagePath == null
                      ? 245
                      : 355,

              child: Container(
                padding:
                    const EdgeInsets
                        .all(14),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.black
                          .withValues(
                            alpha:
                                0.72,
                          ),

                  borderRadius:
                      BorderRadius
                          .circular(14),
                ),

                child: Column(
                  children: [
                    Text(
                      instruction,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    if (!arReady) ...[
                      const SizedBox(
                          height: 8),

                      const LinearProgressIndicator(),
                    ],

                    if (distanceFeet !=
                        null) ...[
                      const SizedBox(
                          height: 12),

                      Text(
                        '${distanceFeet!.toStringAsFixed(2)} ft',
                        style:
                            const TextStyle(
                          color:
                              Colors.greenAccent,
                          fontSize: 34,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      Text(
                        '${distanceMeters!.toStringAsFixed(3)} metres',
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),

                      if (measuredAt != null)
                        Text(
                          'Measured: ${measuredAt!.toLocal()}',
                          style:
                              const TextStyle(
                            color:
                                Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            /* =================================================
               BOTTOM CONTROLS
            ================================================= */

            Positioned(
              left: 16,
              right: 16,
              bottom: 20,

              child: Container(
                padding:
                    const EdgeInsets
                        .all(14),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.black
                          .withValues(
                            alpha:
                                0.80,
                          ),

                  borderRadius:
                      BorderRadius
                          .circular(16),
                ),

                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    /* GPS STATUS */

                    if (locationLoading) ...[
                      const Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          ),

                          SizedBox(
                              width: 8),

                          Text(
                            'Capturing GPS...',
                            style:
                                TextStyle(
                              color:
                                  Colors.white70,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 10),
                    ],

                    if (latitude != null &&
                        longitude != null) ...[
                      Text(
                        'GPS '
                        '${latitude!.toStringAsFixed(6)}, '
                        '${longitude!.toStringAsFixed(6)}'
                        '${gpsAccuracy == null ? '' : ' • ±${gpsAccuracy!.toStringAsFixed(1)} m'}',
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(
                          height: 10),
                    ],

                    /* EVIDENCE BUTTON */

                    if (distanceFeet !=
                        null) ...[
                      SizedBox(
                        width:
                            double.infinity,

                        child:
                            FilledButton.icon(
                          onPressed:
                              evidenceSaving
                                  ? null
                                  : captureEvidenceImage,

                          icon:
                              const Icon(
                            Icons.camera_alt,
                          ),

                          label:
                              Text(
                            evidenceSaving
                                ? 'Saving Evidence...'
                                : evidenceImagePath ==
                                        null
                                    ? 'Capture Evidence Image'
                                    : 'Retake Evidence Image',
                          ),

                          style:
                              FilledButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                                    0xFF17365D),
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 10),
                    ],

                    /* EVIDENCE PREVIEW */

                    if (evidenceImagePath !=
                        null) ...[
                      ClipRRect(
                        borderRadius:
                            BorderRadius
                                .circular(10),

                        child: Image.file(
                          File(
                            evidenceImagePath!,
                          ),

                          width:
                              double.infinity,

                          height: 105,

                          fit:
                              BoxFit.cover,
                        ),
                      ),

                      const SizedBox(
                          height: 8),

                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color:
                                Colors.greenAccent,
                            size: 18,
                          ),

                          SizedBox(
                              width: 7),

                          Expanded(
                            child: Text(
                              'Evidence image captured with measurement, GPS and timestamp.',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 10),
                    ],

                    /* RESET + CONFIRM */

                    Row(
                      children: [
                        Expanded(
                          child:
                              OutlinedButton.icon(
                            onPressed:
                                resetMeasurement,

                            icon:
                                const Icon(
                              Icons.refresh,
                            ),

                            label:
                                const Text(
                              'Reset',
                            ),

                            style:
                                OutlinedButton
                                    .styleFrom(
                              foregroundColor:
                                  Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(
                            width: 12),

                        Expanded(
                          child:
                              FilledButton.icon(
                            onPressed:
                                distanceFeet ==
                                            null ||
                                        evidenceImagePath ==
                                            null ||
                                        latitude ==
                                            null ||
                                        longitude ==
                                            null
                                    ? null
                                    : confirmMeasurement,

                            icon:
                                const Icon(
                              Icons.check,
                            ),

                            label:
                                const Text(
                              'Use Measurement',
                            ),

                            style:
                                FilledButton
                                    .styleFrom(
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

/* =========================================================
   REUSABLE AR CENTER POINTER
========================================================= */

class _ArCenterPointer extends StatelessWidget {
  const _ArCenterPointer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,

      child: Stack(
        alignment:
            Alignment.center,

        children: [
          Container(
            width: 52,
            height: 52,

            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,

              border:
                  Border.all(
                color:
                    Colors.yellow,
                width: 2,
              ),
            ),
          ),

          Container(
            width: 3,
            height: 72,
            color:
                Colors.yellow,
          ),

          Container(
            width: 72,
            height: 3,
            color:
                Colors.yellow,
          ),

          Container(
            width: 10,
            height: 10,

            decoration:
                const BoxDecoration(
              shape:
                  BoxShape.circle,

              color:
                  Colors.yellow,
            ),
          ),
        ],
      ),
    );
  }
}
