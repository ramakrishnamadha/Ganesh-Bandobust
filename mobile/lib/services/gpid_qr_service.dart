import 'dart:convert';

/// Representation of a parsed GPID QR code.
class GpidQrResult {
  final String gpid;
  final String format; // 'json' | 'url' | 'raw' | 'embedded'
  final String rawData;

  const GpidQrResult({
    required this.gpid,
    required this.format,
    required this.rawData,
  });
}

class GpidQrService {
  static final RegExp _gpidPattern = RegExp(r'^[A-Za-z0-9_-]{4,32}$');
  static final RegExp _embeddedLabelPattern = RegExp(
    r'(?:GPID|MANDAP\s*ID|PANDAL\s*ID|UNIQUE\s*ID|REF|ID|APP\s*NO|APPLICATION\s*NO|APPLICATION\s*ID)[\s:=#-]+([A-Za-z0-9_-]{4,32})',
    caseSensitive: false,
  );

  /// Generate official standard JSON QR payload for a GPID.
  static String generatePayload(String gpid) {
    final cleanGpid = gpid.trim().toUpperCase();
    return jsonEncode({
      'type': 'GANESH_GPID',
      'version': 1,
      'gpid': cleanGpid,
    });
  }

  /// Validates whether a candidate string matches the canonical GPID format.
  static bool isValidGpidFormat(String candidate) {
    final clean = candidate.trim();
    return _gpidPattern.hasMatch(clean);
  }

  /// Parses raw barcode data and extracts the target GPID.
  /// Returns [GpidQrResult] if valid, or `null` if the QR is malformed/unrecognized.
  static GpidQrResult? parseGpid(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // 1. Try structured JSON format
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          final dynamic rawGpid = decoded['gpid'] ?? decoded['unique_id'] ?? decoded['uniqueId'] ?? decoded['application_no'] ?? decoded['application_id'] ?? decoded['app_no'];
          if (rawGpid != null) {
            final candidate = rawGpid.toString().trim().toUpperCase();
            if (isValidGpidFormat(candidate)) {
              return GpidQrResult(
                gpid: candidate,
                format: 'json',
                rawData: trimmed,
              );
            }
          }
        }
      } catch (_) {
        // Not valid JSON, fall through
      }
    }

    // 2. Try URL format (e.g. police portal or local endpoint link)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final uri = Uri.parse(trimmed);
        final queryGpid = uri.queryParameters['gpid'] ?? uri.queryParameters['id'] ?? uri.queryParameters['application_no'] ?? uri.queryParameters['application_id'] ?? uri.queryParameters['app_no'];
        if (queryGpid != null && isValidGpidFormat(queryGpid)) {
          return GpidQrResult(
            gpid: queryGpid.trim().toUpperCase(),
            format: 'url',
            rawData: trimmed,
          );
        }

        // Check path segments (e.g. /api/gpid/HYDCMRZCMNR1749 or /gpid/HYDCMRZCMNR1749)
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) {
          final last = segments.last.trim();
          if (isValidGpidFormat(last) && segments.any((s) {
            final sl = s.toLowerCase();
            return sl == 'gpid' || sl == 'application' || sl == 'application_no' || sl == 'app_no' || sl == 'id' || sl == 'application_id';
          })) {
            return GpidQrResult(
              gpid: last.toUpperCase(),
              format: 'url',
              rawData: trimmed,
            );
          }
        }
      } catch (_) {
        // Not valid URI, fall through
      }
    }

    // 3. Try canonical plaintext GPID
    final candidate = trimmed.toUpperCase();
    if (isValidGpidFormat(candidate)) {
      return GpidQrResult(
        gpid: candidate,
        format: 'raw',
        rawData: trimmed,
      );
    }

    // 4. Try GPID embedded inside text (e.g. "GPID: HYDCMRZCMNR1749", "Mandap ID - HYDCMRZCMNR1749")
    final embeddedMatch = _embeddedLabelPattern.firstMatch(trimmed);
    if (embeddedMatch != null) {
      final embeddedCandidate = embeddedMatch.group(1)?.trim().toUpperCase();
      if (embeddedCandidate != null && isValidGpidFormat(embeddedCandidate)) {
        return GpidQrResult(
          gpid: embeddedCandidate,
          format: 'embedded',
          rawData: trimmed,
        );
      }
    }

    // Unrecognized or malformed QR format
    return null;
  }
}
