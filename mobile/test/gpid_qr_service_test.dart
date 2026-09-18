import 'package:flutter_test/flutter_test.dart';
import 'package:ganesh_bandobust_mobile/services/gpid_api_service.dart';
import 'package:ganesh_bandobust_mobile/services/gpid_qr_service.dart';

void main() {
  group('GpidQrService Tests', () {
    test('generatePayload outputs valid structured JSON', () {
      final payload = GpidQrService.generatePayload('HYDCMRZCMNR1749');
      expect(payload, contains('"type":"GANESH_GPID"'));
      expect(payload, contains('"version":1'));
      expect(payload, contains('"gpid":"HYDCMRZCMNR1749"'));

      final parsed = GpidQrService.parseGpid(payload);
      expect(parsed, isNotNull);
      expect(parsed!.gpid, equals('HYDCMRZCMNR1749'));
      expect(parsed.format, equals('json'));
    });

    test('parseGpid handles canonical plaintext GPIDs', () {
      final parsed = GpidQrService.parseGpid('HYDCMRZCMNR1749');
      expect(parsed, isNotNull);
      expect(parsed!.gpid, equals('HYDCMRZCMNR1749'));
      expect(parsed.format, equals('raw'));
    });

    test('parseGpid handles lowercase and trims whitespace', () {
      final parsed = GpidQrService.parseGpid('  hydcmrzcmnr1749  ');
      expect(parsed, isNotNull);
      expect(parsed!.gpid, equals('HYDCMRZCMNR1749'));
      expect(parsed.format, equals('raw'));
    });

    test('parseGpid handles URLs with gpid query param', () {
      final parsed = GpidQrService.parseGpid(
        'https://policeportal.tspolice.gov.in/ganesh/details?gpid=HYDCMRZCMNR1749',
      );
      expect(parsed, isNotNull);
      expect(parsed!.gpid, equals('HYDCMRZCMNR1749'));
      expect(parsed.format, equals('url'));
    });

    test('parseGpid handles URLs with path segment', () {
      final parsed = GpidQrService.parseGpid(
        'https://policeportal.tspolice.gov.in/ganesh/gpid/HYDCMRZCMNR1749',
      );
      expect(parsed, isNotNull);
      expect(parsed!.gpid, equals('HYDCMRZCMNR1749'));
      expect(parsed.format, equals('url'));
    });

    test('parseGpid handles GPID embedded inside text labels', () {
      final samples = [
        'GPID: HYDCMRZCMNR1749',
        'GPID:HYDCMRZCMNR1749',
        'Mandap ID: HYDCMRZCMNR1749, Zone: Central',
        'Pandal ID - HYDCMRZCMNR1749',
        'Ref# HYDCMRZCMNR1749',
        'Unique ID: HYDCMRZCMNR1749',
        'ID: HYDCMRZCMNR1749',
      ];

      for (final text in samples) {
        final parsed = GpidQrService.parseGpid(text);
        expect(parsed, isNotNull, reason: 'Failed for sample: $text');
        expect(parsed!.gpid, equals('HYDCMRZCMNR1749'), reason: 'Wrong GPID for sample: $text');
        expect(parsed.format, equals('embedded'), reason: 'Wrong format for sample: $text');
      }
    });

    test('parseGpid rejects malformed or random data', () {
      expect(GpidQrService.parseGpid(null), isNull);
      expect(GpidQrService.parseGpid(''), isNull);
      expect(GpidQrService.parseGpid('   '), isNull);
      expect(GpidQrService.parseGpid('12'), isNull); // Too short
      expect(GpidQrService.parseGpid('Hello world this is a test'), isNull); // Spaces
      expect(GpidQrService.parseGpid('https://google.com/search?q=ganesh'), isNull); // Non-GPID URL
      expect(GpidQrService.parseGpid('{"some":"other_json"}'), isNull); // JSON without GPID
      expect(GpidQrService.parseGpid('GPID@#\$%^&*!'), isNull); // Special characters
    });

    test('isValidGpidFormat correctly validates GPID strings', () {
      expect(GpidQrService.isValidGpidFormat('HYDCMRZCMNR1749'), isTrue);
      expect(GpidQrService.isValidGpidFormat('GPID-1234'), isTrue);
      expect(GpidQrService.isValidGpidFormat('HYD_123'), isTrue);
      expect(GpidQrService.isValidGpidFormat('AB'), isFalse);
      expect(GpidQrService.isValidGpidFormat('A B C D'), isFalse);
      expect(GpidQrService.isValidGpidFormat('A'*40), isFalse); // Exceeds 32 chars
    });
  });

  group('GpidVerificationResult State Tests', () {
    test('authorized state constructs and verifies correctly', () {
      const result = GpidVerificationResult(
        status: GpidVerificationStatus.authorized,
        gpid: 'HYDCMRZCMNR1749',
        isAuthorized: true,
        record: <String, dynamic>{
          'unique_id': 'HYDCMRZCMNR1749',
          'ps_name': 'Charminar',
          'name': 'Ganesh Mandap Association',
        },
        stages: <String, dynamic>{
          'stage1': {'status': 'COMPLETED'},
          'stage2': {'status': 'COMPLETED'},
          'stage3': {'status': 'IN_PROGRESS'},
        },
      );

      expect(result.status, equals(GpidVerificationStatus.authorized));
      expect(result.isAuthorized, isTrue);
      expect(result.gpid, equals('HYDCMRZCMNR1749'));
      expect(result.record, isNotNull);
      expect(result.record!['ps_name'], equals('Charminar'));
      expect(result.stages, isNotNull);
      expect(result.stages!['stage3']['status'], equals('IN_PROGRESS'));
      expect(result.isOfflineFallback, isFalse);
    });

    test('unauthorized state correctly captures jurisdiction denial', () {
      const result = GpidVerificationResult(
        status: GpidVerificationStatus.unauthorized,
        gpid: 'HYDCMRZCMNR1749',
        isAuthorized: false,
        errorMessage:
            'Access Denied: GPID in Charminar PS is outside your authorized scope (Asif Nagar PS).',
      );

      expect(result.status, equals(GpidVerificationStatus.unauthorized));
      expect(result.isAuthorized, isFalse);
      expect(result.gpid, equals('HYDCMRZCMNR1749'));
      expect(result.errorMessage, contains('Access Denied'));
      expect(result.record, isNull);
    });

    test('notFound state correctly represents unregistered GPID', () {
      const result = GpidVerificationResult(
        status: GpidVerificationStatus.notFound,
        gpid: 'HYDUNKNOWN9999',
        isAuthorized: false,
        errorMessage: 'GPID not found in master records: HYDUNKNOWN9999',
      );

      expect(result.status, equals(GpidVerificationStatus.notFound));
      expect(result.isAuthorized, isFalse);
      expect(result.gpid, equals('HYDUNKNOWN9999'));
      expect(result.errorMessage, contains('not found'));
    });

    test('invalidFormat state correctly represents malformed input', () {
      const result = GpidVerificationResult(
        status: GpidVerificationStatus.invalidFormat,
        gpid: '',
        isAuthorized: false,
        errorMessage: 'GPID cannot be empty.',
      );

      expect(result.status, equals(GpidVerificationStatus.invalidFormat));
      expect(result.isAuthorized, isFalse);
      expect(result.gpid, isEmpty);
      expect(result.errorMessage, equals('GPID cannot be empty.'));
    });

    test('networkError state allows offline fallback tracking', () {
      const result = GpidVerificationResult(
        status: GpidVerificationStatus.networkError,
        gpid: 'HYDCMRZCMNR1749',
        isAuthorized: false,
        errorMessage: 'Network connection failed and GPID is not stored in offline cache.',
        isOfflineFallback: false,
      );

      expect(result.status, equals(GpidVerificationStatus.networkError));
      expect(result.isAuthorized, isFalse);
      expect(result.errorMessage, contains('Network connection failed'));
    });

    test('verifyGpidJurisdiction rejects empty GPID with invalidFormat immediately', () async {
      final result = await GpidApiService.verifyGpidJurisdiction(gpid: '   ');
      expect(result.status, equals(GpidVerificationStatus.invalidFormat));
      expect(result.isAuthorized, isFalse);
      expect(result.errorMessage, contains('empty'));
    });
  });
}
