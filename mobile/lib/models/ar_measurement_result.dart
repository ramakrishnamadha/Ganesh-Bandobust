class ArMeasurementResult {
  final double valueFeet;
  final double valueMeters;

  final double startX;
  final double startY;
  final double startZ;

  final double endX;
  final double endY;
  final double endZ;

  final double? latitude;
  final double? longitude;
  final double? gpsAccuracy;

  final DateTime measuredAt;

  final String measurementType;
  final String measurementMethod;

  final String? evidenceImagePath;

  const ArMeasurementResult({
    required this.valueFeet,
    required this.valueMeters,
    required this.startX,
    required this.startY,
    required this.startZ,
    required this.endX,
    required this.endY,
    required this.endZ,
    required this.latitude,
    required this.longitude,
    required this.gpsAccuracy,
    required this.measuredAt,
    required this.measurementType,
    required this.measurementMethod,
    required this.evidenceImagePath,
  });
}