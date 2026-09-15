import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';

import '../../models/ar_measurement_result.dart';

enum MeasurementStage {
  waitingForStart,
  lockingStart,
  measuring,
  completed,
}

class MeasurementScreen extends StatefulWidget {
  final String applicationId;
  final String measurementType;

  const MeasurementScreen({
    super.key,
    required this.applicationId,
    required this.measurementType,
  });

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;

  Timer? centerHitTimer;

  MeasurementStage stage = MeasurementStage.waitingForStart;

  vector.Vector3? currentTargetPoint;
  vector.Vector3? pointA;
  vector.Vector3? pointB;

  double liveDistance = 0.0;
  double finalDistance = 0.0;

  double? latitude;
  double? longitude;
  double? gpsAccuracy;

  DateTime? measuredAt;

  String? evidenceImagePath;

  bool locationLoading = false;
  bool evidenceSaving = false;

  late String activeMeasurementType;

  bool targetReady = false;
  bool planeDetected = false;
  bool hitTestBusy = false;

  Offset? pointAScreenPosition;
  Offset? verticalGuideUpperScreenPosition;

  String instruction =
      'Aim the centre target at the starting point and press START.';

  @override
  void initState() {
    super.initState();
    activeMeasurementType = widget.measurementType.toUpperCase();
  }

  String get measurementType => activeMeasurementType;

  bool get isHeight => measurementType == 'HEIGHT';

  @override
  void dispose() {
    centerHitTimer?.cancel();
    arSessionManager?.dispose();
    super.dispose();
  }

  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;
    arLocationManager = locationManager;

    arSessionManager!.onInitialize(
      showAnimatedGuide: false,
      showFeaturePoints: false,
      showPlanes: false,
      showWorldOrigin: false,
      handleTaps: false,
      handlePans: false,
      handleRotation: false,
    );

    arObjectManager!.onInitialize();

    arSessionManager!.onPlaneDetected = (int planeCount) {
      if (!mounted) return;

      setState(() {
        planeDetected = planeCount > 0;
      });
    };

    arSessionManager!.onError = (String error) {
      if (!mounted) return;

      setState(() {
        instruction = 'AR error: $error';
      });
    };

    centerHitTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateCenterTarget(),
    );
  }

  Future<void> _updateCenterTarget() async {
    if (!mounted ||
        arSessionManager == null ||
        hitTestBusy ||
        stage == MeasurementStage.completed) {
      return;
    }

    hitTestBusy = true;

    try {
      final hit = await arSessionManager!.getCenterHitTest();

      if (!mounted) return;

      if (hit == null) {
        setState(() {
          targetReady = false;
          currentTargetPoint = null;

          if (stage == MeasurementStage.lockingStart) {
            instruction =
                'LOCKING POINT A... Keep the centre target steady on the starting point.';
          } else if (stage == MeasurementStage.measuring) {
            instruction =
                'Keep the centre target on the object while moving to Point B.';
          }
        });

        return;
      }

      final x = hit['x'];
      final y = hit['y'];
      final z = hit['z'];

      if (x == null || y == null || z == null) return;

      final target = vector.Vector3(x, y, z);

      if (stage == MeasurementStage.lockingStart) {
        final anchorPosition =
            await arSessionManager!.lockCenterMeasurementAnchor();

        if (!mounted) return;

        if (anchorPosition == null) {
          setState(() {
            targetReady = false;
            instruction =
                'LOCKING POINT A... Keep the centre target steady on the starting point.';
          });
          return;
        }

        final ax = anchorPosition['x'];
        final ay = anchorPosition['y'];
        final az = anchorPosition['z'];

        if (ax == null || ay == null || az == null) {
          return;
        }

        final lockedPoint = vector.Vector3(ax, ay, az);

        final anchorScreen =
            await arSessionManager!.getMeasurementAnchorScreenPosition();

        final verticalGuide =
            await arSessionManager!
                .getMeasurementVerticalGuideScreenPosition();

        if (!mounted) return;

        Offset? projectedPointA;
        Offset? projectedUpperPoint;

        if (anchorScreen != null &&
            anchorScreen['visible'] == true) {
          final sx = anchorScreen['x'];
          final sy = anchorScreen['y'];

          if (sx is double && sy is double) {
            projectedPointA = Offset(sx, sy);
          }
        }

        if (verticalGuide != null) {
          final upper = verticalGuide['upper'];

          if (upper is Map<String, dynamic> &&
              upper['visible'] == true) {
            final ux = upper['x'];
            final uy = upper['y'];

            if (ux is double && uy is double) {
              projectedUpperPoint = Offset(ux, uy);
            }
          }
        }

        setState(() {
          currentTargetPoint = target;
          targetReady = true;
          pointA = lockedPoint;
          pointAScreenPosition = projectedPointA;
          verticalGuideUpperScreenPosition = projectedUpperPoint;
          pointB = null;
          liveDistance = 0.0;
          finalDistance = 0.0;

          latitude = null;
          longitude = null;
          gpsAccuracy = null;
          measuredAt = null;
          evidenceImagePath = null;

          stage = MeasurementStage.measuring;

          instruction = isHeight
              ? 'Point A anchored. Move the reticle upward to Point B.'
              : 'Point A anchored. Move the reticle toward Point B.';
        });

        return;
      }

      double newLiveDistance = liveDistance;

      if (stage == MeasurementStage.measuring && pointA != null) {
        final anchorPosition =
            await arSessionManager!.getMeasurementAnchorPosition();

        if (!mounted) return;

        if (anchorPosition != null) {
          final ax = anchorPosition['x'];
          final ay = anchorPosition['y'];
          final az = anchorPosition['z'];

          if (ax != null && ay != null && az != null) {
            pointA = vector.Vector3(ax, ay, az);
          }
        }

        final anchorScreen =
            await arSessionManager!.getMeasurementAnchorScreenPosition();

        final verticalGuide =
            await arSessionManager!
                .getMeasurementVerticalGuideScreenPosition();

        if (!mounted) return;

        if (anchorScreen != null &&
            anchorScreen['visible'] == true) {
          final sx = anchorScreen['x'];
          final sy = anchorScreen['y'];

          if (sx is double && sy is double) {
            pointAScreenPosition = Offset(sx, sy);
          }
        }

        if (verticalGuide != null) {
          final upper = verticalGuide['upper'];

          if (upper is Map<String, dynamic> &&
              upper['visible'] == true) {
            final ux = upper['x'];
            final uy = upper['y'];

            if (ux is double && uy is double) {
              verticalGuideUpperScreenPosition =
                  Offset(ux, uy);
            }
          }
        }

        if (isHeight) {
          final nativeHeight =
              await arSessionManager!.getNativeHeightRuler();

          if (!mounted) return;

          if (nativeHeight != null) {
            final meters = nativeHeight['meters'];
            final endWorld = nativeHeight['endWorld'];
            final startScreen = nativeHeight['startScreen'];
            final endScreen = nativeHeight['endScreen'];

            if (meters is num) {
              newLiveDistance = meters.toDouble();
            }

            if (endWorld is Map) {
              final ex = endWorld['x'];
              final ey = endWorld['y'];
              final ez = endWorld['z'];

              if (ex is num && ey is num && ez is num) {
                currentTargetPoint = vector.Vector3(
                  ex.toDouble(),
                  ey.toDouble(),
                  ez.toDouble(),
                );
              }
            }

            if (startScreen is Map &&
                startScreen['visible'] == true) {
              final sx = startScreen['x'];
              final sy = startScreen['y'];

              if (sx is num && sy is num) {
                pointAScreenPosition = Offset(
                  sx.toDouble(),
                  sy.toDouble(),
                );
              }
            }

            if (endScreen is Map &&
                endScreen['visible'] == true) {
              final ex = endScreen['x'];
              final ey = endScreen['y'];

              if (ex is num && ey is num) {
                verticalGuideUpperScreenPosition = Offset(
                  ex.toDouble(),
                  ey.toDouble(),
                );
              }
            }
          }
        } else {
          newLiveDistance = _calculateMeasurement(
            pointA!,
            target,
          );

          currentTargetPoint = target;
        }
      }

      setState(() {
        if (!isHeight) {
          currentTargetPoint = target;
        }

        targetReady = currentTargetPoint != null;

        if (stage == MeasurementStage.measuring) {
          liveDistance = newLiveDistance;

          instruction = isHeight
              ? 'Point A locked. Move the target vertically upward to Point B.'
              : 'Point A locked. Move the target horizontally to Point B.';
        } else {
          instruction = isHeight
              ? 'Aim at the BOTTOM point and press START.'
              : 'Aim at the LEFT point and press START.';
        }
      });
    } finally {
      hitTestBusy = false;
    }
  }

  double _calculateMeasurement(
    vector.Vector3 start,
    vector.Vector3 end,
  ) {
    if (isHeight) {
      return (end.y - start.y).abs();
    }

    final dx = end.x - start.x;
    final dz = end.z - start.z;

    return sqrt((dx * dx) + (dz * dz));
  }

  Future<void> _startMeasurement() async {
    if (stage != MeasurementStage.waitingForStart ||
        arSessionManager == null) {
      return;
    }

    /*
     * START must try to lock Point A immediately.
     *
     * Previously START only changed the stage to lockingStart and then
     * _updateCenterTarget() first waited for a fresh getCenterHitTest().
     * That meant the native layer could already have a recent usable depth
     * cached, but Flutter would still refuse to call
     * lockCenterMeasurementAnchor() until another stable centre hit arrived.
     *
     * We now bypass that extra gate and ask the native layer to lock Point A
     * at the exact moment START is pressed.
     */
    await arSessionManager!.clearMeasurementAnchor();

    if (!mounted) return;

    setState(() {
      pointA = null;
      pointB = null;
      pointAScreenPosition = null;
      verticalGuideUpperScreenPosition = null;

      liveDistance = 0.0;
      finalDistance = 0.0;

      latitude = null;
      longitude = null;
      gpsAccuracy = null;
      measuredAt = null;
      evidenceImagePath = null;

      stage = MeasurementStage.lockingStart;

      instruction = 'LOCKING POINT A...';
    });

    final anchorPosition =
        await arSessionManager!.lockCenterMeasurementAnchor();

    if (!mounted) return;

    if (anchorPosition == null) {
      /*
       * If ARCore genuinely has no usable world depth yet, remain in the
       * locking state. The periodic update loop will keep trying, but there
       * is no artificial delay when a cached/available anchor already exists.
       */
      setState(() {
        instruction =
            'LOCKING POINT A... Move the phone slightly to detect depth.';
      });

      _updateCenterTarget();
      return;
    }

    final ax = anchorPosition['x'];
    final ay = anchorPosition['y'];
    final az = anchorPosition['z'];

    if (ax == null || ay == null || az == null) {
      setState(() {
        instruction =
            'LOCKING POINT A... Move the phone slightly to detect depth.';
      });
      return;
    }

    final lockedPoint = vector.Vector3(
      (ax as num).toDouble(),
      (ay as num).toDouble(),
      (az as num).toDouble(),
    );

    final anchorScreen =
        await arSessionManager!.getMeasurementAnchorScreenPosition();

    final verticalGuide =
        await arSessionManager!
            .getMeasurementVerticalGuideScreenPosition();

    if (!mounted) return;

    Offset? projectedPointA;
    Offset? projectedUpperPoint;

    if (anchorScreen != null &&
        anchorScreen['visible'] == true) {
      final sx = anchorScreen['x'];
      final sy = anchorScreen['y'];

      if (sx is num && sy is num) {
        projectedPointA = Offset(
          sx.toDouble(),
          sy.toDouble(),
        );
      }
    }

    if (verticalGuide != null) {
      final upper = verticalGuide['upper'];

      if (upper is Map &&
          upper['visible'] == true) {
        final ux = upper['x'];
        final uy = upper['y'];

        if (ux is num && uy is num) {
          projectedUpperPoint = Offset(
            ux.toDouble(),
            uy.toDouble(),
          );
        }
      }
    }

    setState(() {
      pointA = lockedPoint;
      currentTargetPoint = lockedPoint;
      pointAScreenPosition = projectedPointA;
      verticalGuideUpperScreenPosition = projectedUpperPoint;

      targetReady = true;
      stage = MeasurementStage.measuring;

      instruction = isHeight
          ? 'Point A anchored. Move the reticle upward to Point B.'
          : 'Point A anchored. Move the reticle toward Point B.';
    });
  }

  Future<void> _endMeasurement() async {
    if (!targetReady ||
        currentTargetPoint == null ||
        pointA == null ||
        stage != MeasurementStage.measuring) {
      setState(() {
        instruction = 'Keep the centre target on the final point.';
      });
      return;
    }

    vector.Vector3 lockedPointB;
    double measuredDistance;

    if (isHeight) {
      final nativeHeight =
          await arSessionManager?.getNativeHeightRuler();

      if (!mounted) return;

      if (nativeHeight == null) {
        setState(() {
          instruction =
              'Keep Point A aligned vertically with the centre target.';
        });
        return;
      }

      final meters = nativeHeight['meters'];
      final endWorld = nativeHeight['endWorld'];

      if (meters is! num || endWorld is! Map) {
        setState(() {
          instruction =
              'Unable to lock the HEIGHT endpoint. Keep the phone steady and try END again.';
        });
        return;
      }

      final ex = endWorld['x'];
      final ey = endWorld['y'];
      final ez = endWorld['z'];

      if (ex is! num || ey is! num || ez is! num) {
        setState(() {
          instruction =
              'Unable to lock the HEIGHT endpoint. Keep the phone steady and try END again.';
        });
        return;
      }

      lockedPointB = vector.Vector3(
        ex.toDouble(),
        ey.toDouble(),
        ez.toDouble(),
      );

      measuredDistance = meters.toDouble();
    } else {
      lockedPointB = vector.Vector3(
        currentTargetPoint!.x,
        currentTargetPoint!.y,
        currentTargetPoint!.z,
      );

      measuredDistance = _calculateMeasurement(
        pointA!,
        lockedPointB,
      );
    }

    final now = DateTime.now();

    setState(() {
      pointB = lockedPointB;
      currentTargetPoint = lockedPointB;
      finalDistance = measuredDistance;
      liveDistance = measuredDistance;
      measuredAt = now;
      evidenceImagePath = null;

      stage = MeasurementStage.completed;

      instruction =
          'Measurement locked. GPS is being captured.';
    });

    centerHitTimer?.cancel();

    captureGps();
  }

  Future<void> captureGps() async {
    if (locationLoading || !mounted) {
      return;
    }

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
              'Measurement locked. GPS is disabled. Enable Location Services and press RECORD MEASUREMENT.';
        });

        return;
      }

      var permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          locationLoading = false;
          instruction =
              'Measurement locked, but location permission is unavailable.';
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
            'Measurement and GPS locked. Press RECORD MEASUREMENT to capture evidence.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        locationLoading = false;
        instruction =
            'Measurement locked, but GPS could not be captured. Press RECORD MEASUREMENT to try again.';
      });
    }
  }

  Future<Uint8List?> _imageProviderToPngBytes(
    ImageProvider<Object> provider,
  ) async {
    final completer = Completer<Uint8List?>();

    final imageStream =
        provider.resolve(ImageConfiguration.empty);

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

  Future<bool> _captureEvidenceImage() async {
    if (arSessionManager == null ||
        stage != MeasurementStage.completed ||
        pointA == null ||
        pointB == null) {
      return false;
    }

    if (latitude == null || longitude == null) {
      if (mounted) {
        setState(() {
          instruction =
              'GPS is required. Capturing location now...';
        });
      }

      await captureGps();

      if (latitude == null || longitude == null) {
        return false;
      }
    }

    if (!mounted) return false;

    setState(() {
      evidenceSaving = true;
      instruction =
          'Capturing AR evidence image...';
    });

    try {
      final provider =
          await arSessionManager!.snapshot();

      final screenshot =
          await _imageProviderToPngBytes(provider);

      if (screenshot == null) {
        if (!mounted) return false;

        setState(() {
          evidenceSaving = false;
          instruction =
              'Unable to convert the AR evidence image.';
        });

        return false;
      }

      final decoded =
          img.decodeImage(screenshot);

      if (decoded == null) {
        if (!mounted) return false;

        setState(() {
          evidenceSaving = false;
          instruction =
              'Unable to process the captured evidence image.';
        });

        return false;
      }

      final officialMeasuredAt =
          measuredAt ?? DateTime.now();

      final valueFeet =
          finalDistance * 3.280839895013123;

      final measurementText =
          '$measurementType: ${_formatDistance(finalDistance)} '
          '(${valueFeet.toStringAsFixed(2)} ft)';

      final meterText =
          '${finalDistance.toStringAsFixed(3)} metres';

      final applicationText =
          'Application: ${widget.applicationId}';

      final gpsText =
          'GPS: ${latitude!.toStringAsFixed(6)}, '
          '${longitude!.toStringAsFixed(6)}';

      final accuracyText =
          gpsAccuracy == null
              ? 'GPS Accuracy: -'
              : 'GPS Accuracy: +/-'
                  '${gpsAccuracy!.toStringAsFixed(1)} m';

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

      if (!mounted) return false;

      setState(() {
        evidenceImagePath = file.path;
        evidenceSaving = false;

        instruction =
            'GPS and evidence captured.';
      });

      return true;
    } catch (error) {
      if (!mounted) return false;

      setState(() {
        evidenceSaving = false;
        instruction =
            'Unable to capture evidence image: $error';
      });

      return false;
    }
  }

  Future<void> _recordMeasurement() async {
    if (stage != MeasurementStage.completed ||
        pointA == null ||
        pointB == null ||
        evidenceSaving) {
      return;
    }

    if (latitude == null || longitude == null) {
      setState(() {
        instruction =
            'Capturing GPS before recording...';
      });

      await captureGps();

      if (latitude == null || longitude == null) {
        return;
      }
    }

    if (evidenceImagePath == null) {
      final evidenceCaptured =
          await _captureEvidenceImage();

      if (!evidenceCaptured) {
        return;
      }
    }

    if (!mounted) return;

    final result = ArMeasurementResult(
      valueFeet:
          finalDistance * 3.280839895013123,
      valueMeters: finalDistance,

      startX: pointA!.x,
      startY: pointA!.y,
      startZ: pointA!.z,

      endX: pointB!.x,
      endY: pointB!.y,
      endZ: pointB!.z,

      latitude: latitude,
      longitude: longitude,
      gpsAccuracy: gpsAccuracy,

      measuredAt:
          measuredAt ?? DateTime.now(),

      measurementType:
          widget.measurementType,

      measurementMethod:
          'AR_3D_HIT_TEST',

      evidenceImagePath:
          evidenceImagePath,
    );

    await arSessionManager
        ?.clearMeasurementAnchor();

    if (!mounted) return;

    centerHitTimer?.cancel();

    Navigator.pop(
      context,
      result,
    );
  }

  Future<void> _resetMeasurement() async {
    await arSessionManager?.clearMeasurementAnchor();

    if (!mounted) return;

    setState(() {
      activeMeasurementType =
          widget.measurementType.toUpperCase();

      stage =
          MeasurementStage.waitingForStart;

      pointA = null;
      pointB = null;

      pointAScreenPosition = null;
      verticalGuideUpperScreenPosition = null;

      currentTargetPoint = null;

      liveDistance = 0.0;
      finalDistance = 0.0;

      latitude = null;
      longitude = null;
      gpsAccuracy = null;

      measuredAt = null;
      evidenceImagePath = null;

      locationLoading = false;
      evidenceSaving = false;

      targetReady = false;

      instruction =
          'Aim the centre target at the starting point and press START.';
    });

    centerHitTimer?.cancel();

    centerHitTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateCenterTarget(),
    );
  }

  bool _isAligned() {
    final visualStart =
        pointAScreenPosition;

    if (visualStart == null ||
        stage != MeasurementStage.measuring) {
      return false;
    }

    const reticle =
        Offset(0.5, 0.5);

    final start =
        visualStart;

    final rulerVector =
        reticle - start;

    if (rulerVector.distance < 0.001) {
      return true;
    }

    if (isHeight) {
      const tolerance = 0.035;

      return (start.dx - reticle.dx)
              .abs() <=
          tolerance;
    }

    return (start.dy - reticle.dy)
            .abs() <=
        0.04;
  }

  String _alignmentMessage() {
    final visualStart =
        pointAScreenPosition;

    if (visualStart == null) {
      return 'KEEP POINT A IN VIEW';
    }

    if (_isAligned()) {
      return isHeight
          ? '90° VERTICAL ALIGNMENT OK'
          : 'HORIZONTAL ALIGNMENT OK';
    }

    if (isHeight) {
      const tolerance = 0.035;

      final aX =
          visualStart.dx;

      if (0.5 < aX - tolerance) {
        return 'MOVE CAMERA LEFT TO ALIGN RETICLE ABOVE POINT A';
      }

      if (0.5 > aX + tolerance) {
        return 'MOVE CAMERA RIGHT TO ALIGN RETICLE ABOVE POINT A';
      }

      return '90° VERTICAL ALIGNMENT LOCKED';
    }

    if (visualStart.dy < 0.5) {
      return 'MOVE RETICLE UP';
    }

    return 'MOVE RETICLE DOWN';
  }

  Color _alignmentColor() {
    if (stage != MeasurementStage.measuring) {
      return Colors.white;
    }

    return _isAligned()
        ? Colors.greenAccent
        : Colors.amberAccent;
  }

  String _formatDistance(
    double meters,
  ) {
    final totalInches =
        meters * 39.37007874;

    final feet =
        totalInches ~/ 12;

    final inches =
        totalInches -
            (feet * 12);

    return '$feet ft '
        '${inches.toStringAsFixed(1)} in';
  }

  Widget _buildCrosshair() {
    Color targetColor;

    if (stage ==
        MeasurementStage.completed) {
      targetColor =
          Colors.greenAccent;
    } else if (stage ==
        MeasurementStage.lockingStart) {
      targetColor =
          Colors.amberAccent;
    } else if (targetReady) {
      targetColor =
          Colors.greenAccent;
    } else {
      targetColor =
          Colors.white;
    }

    return Center(
      child: Stack(
        alignment:
            Alignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              border:
                  Border.all(
                color:
                    targetColor,
                width: 2,
              ),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(
              color:
                  targetColor,
              shape:
                  BoxShape.circle,
            ),
          ),
          Container(
            width: 88,
            height: 2,
            color:
                targetColor,
          ),
          Container(
            width: 2,
            height: 88,
            color:
                targetColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementScale() {
    if (stage !=
            MeasurementStage.measuring &&
        stage !=
            MeasurementStage.completed) {
      return const SizedBox
          .shrink();
    }

    final visualPointA =
        pointAScreenPosition;

    if (visualPointA == null) {
      return const SizedBox
          .shrink();
    }

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final start =
              Offset(
            visualPointA.dx *
                constraints.maxWidth,
            visualPointA.dy *
                constraints.maxHeight,
          );

          final end =
              Offset(
            constraints.maxWidth /
                2,
            constraints.maxHeight /
                2,
          );

          final guideUpper =
              verticalGuideUpperScreenPosition ==
                      null
                  ? null
                  : Offset(
                      verticalGuideUpperScreenPosition!
                              .dx *
                          constraints
                              .maxWidth,
                      verticalGuideUpperScreenPosition!
                              .dy *
                          constraints
                              .maxHeight,
                    );

          return IgnorePointer(
            child:
                CustomPaint(
              painter:
                  MeasurementScalePainter(
                start: start,
                end: end,
                scaleColor:
                    _alignmentColor(),
                isHeight:
                    isHeight,
                canvasSize:
                    Size(
                  constraints
                      .maxWidth,
                  constraints
                      .maxHeight,
                ),
                guideUpper:
                    guideUpper,
                measuredMeters:
                    stage ==
                            MeasurementStage
                                .completed
                        ? finalDistance
                        : liveDistance,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final locking =
        stage ==
            MeasurementStage
                .lockingStart;

    final measuring =
        stage ==
            MeasurementStage
                .measuring;

    final completed =
        stage ==
            MeasurementStage
                .completed;

    final displayedDistance =
        completed
            ? finalDistance
            : liveDistance;

    return Scaffold(
      backgroundColor:
          Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: ARView(
              onARViewCreated:
                  onARViewCreated,
              planeDetectionConfig:
                  PlaneDetectionConfig
                      .horizontalAndVertical,
            ),
          ),

          _buildMeasurementScale(),

          _buildCrosshair(),

          SafeArea(
            child: Align(
              alignment:
                  Alignment.topLeft,
              child: Padding(
                padding:
                    const EdgeInsets
                        .all(12),
                child: Material(
                  color:
                      Colors.black54,
                  borderRadius:
                      BorderRadius
                          .circular(
                              30),
                  child:
                      InkWell(
                    borderRadius:
                        BorderRadius
                            .circular(
                                30),
                    onTap: () =>
                        Navigator.pop(
                            context),
                    child:
                        const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons
                            .arrow_back,
                        color: Colors
                            .white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Align(
              alignment:
                  Alignment
                      .topCenter,
              child: Container(
                margin:
                    const EdgeInsets
                        .only(
                  top: 15,
                  left: 70,
                  right: 20,
                ),
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.black54,
                  borderRadius:
                      BorderRadius
                          .circular(
                              16),
                ),
                child: Text(
                  '$measurementType MEASUREMENT',
                  textAlign:
                      TextAlign
                          .center,
                  style:
                      const TextStyle(
                    color: Colors
                        .white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ),
            ),
          ),

          if (measuring ||
              completed)
            Positioned(
              top: MediaQuery.of(
                        context,
                      ).size.height *
                  0.25,
              left: 20,
              right: 20,
              child: Center(
                child:
                    Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        22,
                    vertical: 12,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors
                        .black87,
                    borderRadius:
                        BorderRadius
                            .circular(
                                20),
                    border:
                        Border.all(
                      color:
                          completed
                              ? Colors
                                  .greenAccent
                              : Colors
                                  .white54,
                    ),
                  ),
                  child:
                      Text(
                    _formatDistance(
                      displayedDistance,
                    ),
                    style:
                        TextStyle(
                      color:
                          completed
                              ? Colors
                                  .greenAccent
                              : Colors
                                  .white,
                      fontSize:
                          34,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),
              ),
            ),

          SafeArea(
            child: Align(
              alignment:
                  Alignment
                      .bottomCenter,
              child: Container(
                width:
                    double.infinity,
                margin:
                    const EdgeInsets
                        .all(18),
                padding:
                    const EdgeInsets
                        .all(16),
                decoration:
                    BoxDecoration(
                  color: Colors.black
                      .withValues(
                          alpha:
                              0.78),
                  borderRadius:
                      BorderRadius
                          .circular(
                              20),
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize
                          .min,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          evidenceSaving
                              ? Icons
                                  .camera_alt
                              : locationLoading
                                  ? Icons
                                      .location_searching
                                  : locking
                                      ? Icons
                                          .lock_clock
                                      : targetReady
                                          ? Icons
                                              .check_circle
                                          : Icons
                                              .center_focus_weak,
                          color:
                              evidenceSaving ||
                                      locationLoading
                                  ? Colors
                                      .cyanAccent
                                  : locking
                                      ? Colors
                                          .amberAccent
                                      : targetReady
                                          ? Colors
                                              .greenAccent
                                          : Colors
                                              .white70,
                        ),
                        const SizedBox(
                            width:
                                8),
                        Flexible(
                          child:
                              Text(
                            evidenceSaving
                                ? 'SAVING EVIDENCE'
                                : locationLoading
                                    ? 'CAPTURING GPS'
                                    : locking
                                        ? 'LOCKING POINT A'
                                        : targetReady
                                            ? 'TARGET READY'
                                            : planeDetected
                                                ? 'AIM AT START POINT'
                                                : 'READY TO START',
                            textAlign:
                                TextAlign
                                    .center,
                            style:
                                TextStyle(
                              color:
                                  evidenceSaving ||
                                          locationLoading
                                      ? Colors
                                          .cyanAccent
                                      : locking
                                          ? Colors
                                              .amberAccent
                                          : targetReady
                                              ? Colors
                                                  .greenAccent
                                              : Colors
                                                  .white,
                              fontSize:
                                  14,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 12),

                    if (measuring)
                      Container(
                        width:
                            double
                                .infinity,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              12,
                          vertical:
                              9,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              _alignmentColor()
                                  .withValues(
                            alpha:
                                0.14,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      12),
                          border:
                              Border.all(
                            color:
                                _alignmentColor(),
                            width:
                                1.5,
                          ),
                        ),
                        child:
                            Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            Icon(
                              _isAligned()
                                  ? Icons
                                      .check_circle
                                  : Icons
                                      .screen_rotation_alt,
                              color:
                                  _alignmentColor(),
                              size:
                                  20,
                            ),
                            const SizedBox(
                                width:
                                    8),
                            Flexible(
                              child:
                                  Text(
                                _alignmentMessage(),
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    TextStyle(
                                  color:
                                      _alignmentColor(),
                                  fontSize:
                                      14,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (measuring)
                      const SizedBox(
                          height:
                              12),

                    Text(
                      instruction,
                      textAlign:
                          TextAlign
                              .center,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            15,
                      ),
                    ),

                    if (completed &&
                        latitude != null &&
                        longitude !=
                            null) ...[
                      const SizedBox(
                          height:
                              8),
                      Text(
                        'GPS: '
                        '${latitude!.toStringAsFixed(6)}, '
                        '${longitude!.toStringAsFixed(6)}'
                        '${gpsAccuracy == null ? '' : '  ±${gpsAccuracy!.toStringAsFixed(1)} m'}',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            const TextStyle(
                          color:
                              Colors
                                  .greenAccent,
                          fontSize:
                              12,
                        ),
                      ),
                    ],

                    const SizedBox(
                        height: 15),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 56,
                      child:
                          ElevatedButton(
                        onPressed:
                            evidenceSaving ||
                                    locationLoading
                                ? null
                                : completed
                                    ? _recordMeasurement
                                    : locking
                                        ? null
                                        : measuring
                                            ? _endMeasurement
                                            : _startMeasurement,
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              completed
                                  ? Colors
                                      .white
                                  : measuring
                                      ? Colors
                                          .redAccent
                                      : Colors
                                          .green,
                          foregroundColor:
                              completed
                                  ? Colors
                                      .black
                                  : Colors
                                      .white,
                          disabledBackgroundColor:
                              Colors
                                  .amber
                                  .shade800,
                          disabledForegroundColor:
                              Colors
                                  .white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        15),
                          ),
                        ),
                        child:
                            Text(
                          evidenceSaving
                              ? 'SAVING EVIDENCE...'
                              : locationLoading
                                  ? 'CAPTURING GPS...'
                                  : completed
                                      ? 'RECORD MEASUREMENT'
                                      : locking
                                          ? 'LOCKING...'
                                          : measuring
                                              ? 'END'
                                              : 'START',
                          style:
                              const TextStyle(
                            fontSize:
                                18,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
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

class MeasurementScalePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color scaleColor;
  final bool isHeight;
  final Size canvasSize;
  final Offset? guideUpper;
  final double measuredMeters;

  const MeasurementScalePainter({
    required this.start,
    required this.end,
    required this.scaleColor,
    required this.isHeight,
    required this.canvasSize,
    required this.guideUpper,
    required this.measuredMeters,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final rulerEnd =
        isHeight
            ? Offset(
                start.dx,
                end.dy,
              )
            : end;

    final delta =
        rulerEnd - start;

    final length =
        delta.distance;

    if (length < 2) {
      return;
    }

    final direction =
        delta / length;

    final normal =
        Offset(
      -direction.dy,
      direction.dx,
    );

    final linePaint =
        Paint()
          ..color =
              scaleColor
          ..strokeWidth =
              3
          ..strokeCap =
              StrokeCap.round;

    final tickPaint =
        Paint()
          ..color =
              scaleColor
          ..strokeWidth =
              2
          ..strokeCap =
              StrokeCap.round;

    final pointPaint =
        Paint()
          ..color =
              Colors.greenAccent
          ..style =
              PaintingStyle.fill;

    final pointBorderPaint =
        Paint()
          ..color =
              Colors.black
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              2;

    final guidePaint =
        Paint()
          ..color =
              scaleColor.withValues(
                  alpha:
                      0.65)
          ..strokeWidth =
              2
          ..strokeCap =
              StrokeCap.round;

    if (isHeight) {
      canvas.drawLine(
        start,
        rulerEnd,
        guidePaint,
      );
    } else {
      canvas.drawLine(
        Offset(
          0,
          start.dy,
        ),
        Offset(
          canvasSize.width,
          start.dy,
        ),
        guidePaint,
      );
    }

    canvas.drawLine(
      start,
      rulerEnd,
      linePaint,
    );

    const tickSpacing =
        22.0;

    var distance =
        0.0;

    var tickIndex =
        0;

    while (distance <= length) {
      final centre =
          start +
              direction *
                  distance;

      final majorTick =
          tickIndex % 5 == 0;

      final tickLength =
          majorTick
              ? 18.0
              : 10.0;

      final halfTick =
          normal *
              (tickLength /
                  2);

      canvas.drawLine(
        centre - halfTick,
        centre + halfTick,
        tickPaint,
      );

      if (majorTick &&
          tickIndex > 0) {
        final currentMeters =
            length <= 0
                ? 0.0
                : (distance /
                        length) *
                    measuredMeters;

        final totalInches =
            currentMeters *
                39.37007874;

        final feet =
            totalInches ~/
                12;

        if (feet > 0) {
          final labelPainter =
              TextPainter(
            text:
                TextSpan(
              text:
                  '$feet ft',
              style:
                  TextStyle(
                color:
                    scaleColor,
                fontSize:
                    11,
                fontWeight:
                    FontWeight
                        .bold,
                shadows:
                    const [
                  Shadow(
                    color:
                        Colors
                            .black,
                    blurRadius:
                        3,
                  ),
                ],
              ),
            ),
            textDirection:
                TextDirection
                    .ltr,
          )..layout();

          labelPainter.paint(
            canvas,
            centre +
                normal *
                    16 -
                Offset(
                  labelPainter
                          .width /
                      2,
                  labelPainter
                          .height /
                      2,
                ),
          );
        }
      }

      distance +=
          tickSpacing;

      tickIndex++;
    }

    canvas.drawCircle(
      start,
      8,
      pointPaint,
    );

    canvas.drawCircle(
      start,
      8,
      pointBorderPaint,
    );

    final textPainter =
        TextPainter(
      text:
          const TextSpan(
        text: 'A',
        style:
            TextStyle(
          color:
              Colors.black,
          fontSize:
              10,
          fontWeight:
              FontWeight.bold,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      start -
          Offset(
            textPainter.width /
                2,
            textPainter.height /
                2,
          ),
    );
  }

  @override
  bool shouldRepaint(
    covariant MeasurementScalePainter
        oldDelegate,
  ) {
    return oldDelegate.start !=
            start ||
        oldDelegate.end !=
            end ||
        oldDelegate.scaleColor !=
            scaleColor ||
        oldDelegate.isHeight !=
            isHeight ||
        oldDelegate.canvasSize !=
            canvasSize ||
        oldDelegate.guideUpper !=
            guideUpper ||
        oldDelegate.measuredMeters !=
            measuredMeters;
  }
}