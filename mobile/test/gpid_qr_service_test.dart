import 'package:flutter_test/flutter_test.dart';
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
}
