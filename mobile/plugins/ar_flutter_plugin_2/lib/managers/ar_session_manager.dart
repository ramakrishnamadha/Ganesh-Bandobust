import 'dart:math' show sqrt;
import 'dart:typed_data';

import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/utils/json_converters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

typedef ARHitResultHandler = void Function(List<ARHitTestResult> hits);
typedef ARPlaneResultHandler = void Function(int planeCount);
typedef ErrorHandler = void Function(String error);

class ARSessionManager {
  late MethodChannel _channel;

  final bool debug;
  final BuildContext buildContext;
  final PlaneDetectionConfig planeDetectionConfig;

  late ARHitResultHandler onPlaneOrPointTap;
  late ARPlaneResultHandler onPlaneDetected;

  ErrorHandler? onError;

  ARSessionManager(
    int id,
    this.buildContext,
    this.planeDetectionConfig, {
    this.debug = false,
  }) {
    _channel = MethodChannel('arsession_$id');
    _channel.setMethodCallHandler(_platformCallHandler);

    if (debug) {
      print('ARSessionManager initialized');
    }
  }

  Future<Matrix4?> getCameraPose() async {
    try {
      final serializedCameraPose =
          await _channel.invokeMethod<List<dynamic>>(
        'getCameraPose',
        {},
      );

      if (serializedCameraPose == null) {
        return null;
      }

      return MatrixConverter().fromJson(serializedCameraPose);
    } catch (e) {
      if (debug) {
        print('Camera pose error: $e');
      }
      return null;
    }
  }

  Future<Matrix4?> getPose(ARAnchor anchor) async {
    try {
      if (anchor.name.isEmpty) {
        throw Exception(
          'Anchor can not be resolved. Anchor name is empty.',
        );
      }

      final serializedAnchorPose =
          await _channel.invokeMethod<List<dynamic>>(
        'getAnchorPose',
        {
          'anchorId': anchor.name,
        },
      );

      if (serializedAnchorPose == null) {
        return null;
      }

      return MatrixConverter().fromJson(serializedAnchorPose);
    } catch (e) {
      if (debug) {
        print('Anchor pose error: $e');
      }
      return null;
    }
  }

  Future<double?> getDistanceBetweenAnchors(
    ARAnchor anchor1,
    ARAnchor anchor2,
  ) async {
    final anchor1Pose = await getPose(anchor1);
    final anchor2Pose = await getPose(anchor2);

    final anchor1Translation =
        anchor1Pose?.getTranslation();
    final anchor2Translation =
        anchor2Pose?.getTranslation();

    if (anchor1Translation != null &&
        anchor2Translation != null) {
      return getDistanceBetweenVectors(
        anchor1Translation,
        anchor2Translation,
      );
    }

    return null;
  }

  Future<double?> getDistanceFromAnchor(
    ARAnchor anchor,
  ) async {
    final cameraPose = await getCameraPose();
    final anchorPose = await getPose(anchor);

    final cameraTranslation =
        cameraPose?.getTranslation();
    final anchorTranslation =
        anchorPose?.getTranslation();

    if (anchorTranslation != null &&
        cameraTranslation != null) {
      return getDistanceBetweenVectors(
        anchorTranslation,
        cameraTranslation,
      );
    }

    return null;
  }

  double getDistanceBetweenVectors(
    Vector3 vector1,
    Vector3 vector2,
  ) {
    final dx = vector1.x - vector2.x;
    final dy = vector1.y - vector2.y;
    final dz = vector1.z - vector2.z;

    return sqrt(
      dx * dx +
          dy * dy +
          dz * dz,
    );
  }

  Future<Map<String, double>?> getCenterHitTest() async {
    try {
      final dynamic result =
          await _channel.invokeMethod<dynamic>(
        'getCenterHitTest',
      );

      return _positionMapFromResult(result);
    } catch (e) {
      if (debug) {
        print('Center hit test error: $e');
      }
      return null;
    }
  }

  Future<Map<String, double>?>
      lockCenterMeasurementAnchor() async {
    try {
      final dynamic result =
          await _channel.invokeMethod<dynamic>(
        'lockCenterMeasurementAnchor',
      );

      return _positionMapFromResult(result);
    } catch (e) {
      if (debug) {
        print('Measurement anchor lock error: $e');
      }
      return null;
    }
  }

  Future<Map<String, double>?>
      getMeasurementAnchorPosition() async {
    try {
      final dynamic result =
          await _channel.invokeMethod<dynamic>(
        'getMeasurementAnchorPosition',
      );

      return _positionMapFromResult(result);
    } catch (e) {
      if (debug) {
        print('Measurement anchor position error: $e');
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?>
      getMeasurementAnchorScreenPosition() async {
    try {
      final dynamic result =
          await _channel.invokeMethod<dynamic>(
        'getMeasurementAnchorScreenPosition',
      );

      if (result == null || result is! Map) {
        return null;
      }

      final map = Map<dynamic, dynamic>.from(result);

      final rawX = map['x'];
      final rawY = map['y'];
      final rawVisible = map['visible'];

      if (rawX is! num || rawY is! num) {
        return null;
      }

      return <String, dynamic>{
        'x': rawX.toDouble(),
        'y': rawY.toDouble(),
        'visible': rawVisible is bool
            ? rawVisible
            : true,
      };
    } catch (e) {
      if (debug) {
        print('Measurement anchor screen position error: $e');
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?>
      getMeasurementVerticalGuideScreenPosition() async {
    try {
      final dynamic result =
          await _channel.invokeMethod<dynamic>(
        'getMeasurementVerticalGuideScreenPosition',
      );

      if (result == null || result is! Map) {
        return null;
      }

      final map = Map<dynamic, dynamic>.from(result);

      Map<String, dynamic>? readPoint(dynamic rawPoint) {
        if (rawPoint == null || rawPoint is! Map) {
          return null;
        }

        final point = Map<dynamic, dynamic>.from(rawPoint);

        final rawX = point['x'];
        final rawY = point['y'];
        final rawVisible = point['visible'];

        if (rawX is! num || rawY is! num) {
          return null;
        }

        return <String, dynamic>{
          'x': rawX.toDouble(),
          'y': rawY.toDouble(),
          'visible': rawVisible is bool
              ? rawVisible
              : true,
        };
      }

      final anchor = readPoint(map['anchor']);
      final upper = readPoint(map['upper']);

      if (anchor == null || upper == null) {
        return null;
      }

      return <String, dynamic>{
        'anchor': anchor,
        'upper': upper,
      };
    } catch (e) {
      if (debug) {
        print(
          'Measurement vertical guide screen position error: $e',
        );
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> getNativeHeightRuler() async {
    try {
      final dynamic result =
          await _channel.invokeMethod<dynamic>(
        'getNativeHeightRuler',
      );

      if (result == null || result is! Map) {
        return null;
      }

      final map = Map<dynamic, dynamic>.from(result);

      Map<String, dynamic>? readWorldPoint(dynamic rawPoint) {
        if (rawPoint == null || rawPoint is! Map) {
          return null;
        }

        final point = Map<dynamic, dynamic>.from(rawPoint);

        final rawX = point['x'];
        final rawY = point['y'];
        final rawZ = point['z'];

        if (rawX is! num ||
            rawY is! num ||
            rawZ is! num) {
          return null;
        }

        return <String, dynamic>{
          'x': rawX.toDouble(),
          'y': rawY.toDouble(),
          'z': rawZ.toDouble(),
        };
      }

      Map<String, dynamic>? readScreenPoint(dynamic rawPoint) {
        if (rawPoint == null || rawPoint is! Map) {
          return null;
        }

        final point = Map<dynamic, dynamic>.from(rawPoint);

        final rawX = point['x'];
        final rawY = point['y'];
        final rawVisible = point['visible'];

        if (rawX is! num || rawY is! num) {
          return null;
        }

        return <String, dynamic>{
          'x': rawX.toDouble(),
          'y': rawY.toDouble(),
          'visible': rawVisible is bool
              ? rawVisible
              : true,
        };
      }

      final startWorld = readWorldPoint(map['startWorld']);
      final endWorld = readWorldPoint(map['endWorld']);
      final startScreen = readScreenPoint(map['startScreen']);
      final endScreen = readScreenPoint(map['endScreen']);
      final rawMeters = map['meters'];

      if (startWorld == null ||
          endWorld == null ||
          startScreen == null ||
          endScreen == null ||
          rawMeters is! num) {
        return null;
      }

      return <String, dynamic>{
        'startWorld': startWorld,
        'endWorld': endWorld,
        'startScreen': startScreen,
        'endScreen': endScreen,
        'meters': rawMeters.toDouble(),
        'stableTarget': map['stableTarget'] is bool
            ? map['stableTarget']
            : true,
        'axis': map['axis']?.toString(),
      };
    } catch (e) {
      if (debug) {
        print('Native height ruler error: $e');
      }
      return null;
    }
  }

  Future<void> clearMeasurementAnchor() async {
    try {
      await _channel.invokeMethod<void>(
        'clearMeasurementAnchor',
      );
    } catch (e) {
      if (debug) {
        print('Clear measurement anchor error: $e');
      }
    }
  }

  Map<String, double>? _positionMapFromResult(
    dynamic result,
  ) {
    if (result == null || result is! Map) {
      return null;
    }

    final map =
        Map<dynamic, dynamic>.from(result);

    dynamic rawPosition = map['position'];

    if (rawPosition == null) {
      rawPosition = map;
    }

    if (rawPosition is! Map) {
      return null;
    }

    final position =
        Map<dynamic, dynamic>.from(rawPosition);

    final rawX = position['x'];
    final rawY = position['y'];
    final rawZ = position['z'];
    final rawDistance = map['distance'];

    if (rawX is! num ||
        rawY is! num ||
        rawZ is! num) {
      return null;
    }

    return <String, double>{
      'x': rawX.toDouble(),
      'y': rawY.toDouble(),
      'z': rawZ.toDouble(),
      'distance':
          rawDistance is num
              ? rawDistance.toDouble()
              : 0.0,
    };
  }

  void disableCamera() {
    _channel.invokeMethod<void>(
      'disableCamera',
    );
  }

  void enableCamera() {
    _channel.invokeMethod<void>(
      'enableCamera',
    );
  }

  void showPlanes(bool showPlanes) {
    _channel.invokeMethod<void>(
      'showPlanes',
      {
        'showPlanes': showPlanes,
      },
    );
  }

  Future<void> _platformCallHandler(
    MethodCall call,
  ) {
    if (debug) {
      print(
        '_platformCallHandler call '
        '${call.method} ${call.arguments}',
      );
    }

    try {
      switch (call.method) {
        case 'onError':
          if (onError != null) {
            onError!(call.arguments[0]);
          } else {
            ScaffoldMessenger.of(
              buildContext,
            ).showSnackBar(
              SnackBar(
                content:
                    Text(call.arguments[0]),
                action: SnackBarAction(
                  label: 'HIDE',
                  onPressed:
                      ScaffoldMessenger.of(
                    buildContext,
                  ).hideCurrentSnackBar,
                ),
              ),
            );
          }
          break;

        case 'onPlaneOrPointTap':
          final rawHitTestResults =
              call.arguments as List<dynamic>;

          final serializedHitTestResults =
              rawHitTestResults
                  .map(
                    (hitTestResult) =>
                        Map<String, dynamic>.from(
                      hitTestResult,
                    ),
                  )
                  .toList();

          final hitTestResults =
              serializedHitTestResults
                  .map(
                    (e) =>
                        ARHitTestResult.fromJson(
                      e,
                    ),
                  )
                  .toList();

          onPlaneOrPointTap(
            hitTestResults,
          );
          break;

        case 'onPlaneDetected':
          final planeCountResult =
              call.arguments as int;

          onPlaneDetected(
            planeCountResult,
          );
          break;

        case 'dispose':
          _channel.invokeMethod<void>(
            'dispose',
          );
          break;

        default:
          if (debug) {
            print(
              'Unimplemented method '
              '${call.method}',
            );
          }
      }
    } catch (e) {
      if (debug) {
        print(
          'Platform callback error: $e',
        );
      }
    }

    return Future.value();
  }

  onInitialize({
    bool showAnimatedGuide = true,
    bool showFeaturePoints = false,
    bool showPlanes = true,
    String? customPlaneTexturePath,
    bool showWorldOrigin = false,
    bool handleTaps = true,
    bool handlePans = false,
    bool handleRotation = false,
  }) {
    _channel.invokeMethod<void>(
      'init',
      {
        'showAnimatedGuide':
            showAnimatedGuide,
        'showFeaturePoints':
            showFeaturePoints,
        'planeDetectionConfig':
            planeDetectionConfig.index,
        'showPlanes': showPlanes,
        'customPlaneTexturePath':
            customPlaneTexturePath,
        'showWorldOrigin':
            showWorldOrigin,
        'handleTaps': handleTaps,
        'handlePans': handlePans,
        'handleRotation':
            handleRotation,
      },
    );
  }

  dispose() async {
    try {
      await _channel.invokeMethod<void>(
        'dispose',
      );
    } catch (e) {
      if (debug) {
        print(e);
      }
    }
  }

  Future<ImageProvider> snapshot() async {
    final result =
        await _channel.invokeMethod<Uint8List>(
      'snapshot',
    );

    return MemoryImage(result!);
  }
}
