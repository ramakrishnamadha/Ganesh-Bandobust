import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/auth_service.dart';
import '../../services/gpid_api_service.dart';
import '../../services/gpid_qr_service.dart';
import '../festivity/festivity_check_screen.dart';

class GpidQrScannerScreen extends StatefulWidget {
  final AuthenticatedUser authenticatedUser;
  final void Function(Map<String, dynamic> record, Map<String, dynamic>? stages)? onVerified;

  const GpidQrScannerScreen({
    super.key,
    required this.authenticatedUser,
    this.onVerified,
  });

  @override
  State<GpidQrScannerScreen> createState() => _GpidQrScannerScreenState();
}

class _GpidQrScannerScreenState extends State<GpidQrScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  String? _statusMessage;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    // Debounce duplicate scans within 2 seconds
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 2000) {
      return;
    }
    _lastScanTime = now;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Reading QR Code...';
    });

    // 1. Extract and validate syntax
    final qrResult = GpidQrService.parseGpid(rawValue);
    if (qrResult == null) {
      if (!mounted) return;
      await _showErrorDialog(
        title: 'Invalid QR Code',
        message:
            'The scanned QR code is not recognized as a valid Ganesh Mandap GPID.\n\nScanned: ${rawValue.length > 60 ? "${rawValue.substring(0, 60)}..." : rawValue}',
        icon: Icons.qr_code_scanner,
        iconColor: Colors.amber[700]!,
      );
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
          _lastScanTime = null;
        });
      }
      return;
    }

    await _verifyGpid(qrResult.gpid);
  }

  Future<void> _verifyGpid(String candidateGpid) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Verifying GPID $candidateGpid & jurisdiction...';
    });

    // 2. Call server-side jurisdiction validation endpoint
    final verification = await GpidApiService.verifyGpidJurisdiction(
      gpid: candidateGpid,
      user: widget.authenticatedUser,
    );

    if (!mounted) return;

    // 3. Handle server response
    switch (verification.status) {
      case GpidVerificationStatus.authorized:
        // GPID is valid and authorized for this officer!
        final record = verification.record ?? <String, dynamic>{
          'unique_id': candidateGpid,
        };

        try {
          await _controller.stop();
        } catch (_) {}

        if (!mounted) return;

        if (widget.onVerified != null) {
          Navigator.pop(context);
          widget.onVerified!(record, verification.stages);
        } else {
          // Replace scanner with the existing Festivity Checking flow
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (_) => FestivityCheckScreen(
                applicationId: candidateGpid,
              ),
            ),
          );
        }
        break;

      case GpidVerificationStatus.unauthorized:
        // 403: Block access due to jurisdiction constraint
        await _showSecurityDialog(
          title: 'Access Denied: Out of Jurisdiction',
          message: verification.errorMessage ??
              'GPID "$candidateGpid" belongs to a Police Station outside your authorized scope.',
        );
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusMessage = null;
            _lastScanTime = null;
          });
        }
        break;

      case GpidVerificationStatus.notFound:
        // 404: Unknown GPID
        await _showErrorDialog(
          title: 'GPID Not Found',
          message: verification.errorMessage ??
              'GPID "$candidateGpid" is not registered in the Ganesh Bandobust master records.',
          icon: Icons.search_off,
          iconColor: Colors.orange,
        );
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusMessage = null;
            _lastScanTime = null;
          });
        }
        break;

      case GpidVerificationStatus.invalidFormat:
        // 400: Malformed GPID
        await _showErrorDialog(
          title: 'Malformed GPID',
          message: verification.errorMessage ??
              'GPID "$candidateGpid" has an invalid format.',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusMessage = null;
            _lastScanTime = null;
          });
        }
        break;

      case GpidVerificationStatus.unauthenticated:
        // 401: Session expired
        await _showErrorDialog(
          title: 'Session Expired',
          message: 'Your login session has expired. Please log in again.',
          icon: Icons.lock_clock,
          iconColor: Colors.red,
        );
        if (mounted) {
          Navigator.pop(context);
        }
        break;

      case GpidVerificationStatus.networkError:
      case GpidVerificationStatus.serverError:
        // Network / server failure with Retry
        final bool shouldRetry = await _showNetworkRetryDialog(
          title: 'Verification Failed',
          message: verification.errorMessage ??
              'Unable to connect to the server to verify GPID "$candidateGpid". Please check your network.',
        );

        if (shouldRetry && mounted) {
          await _verifyGpid(candidateGpid);
        } else if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusMessage = null;
            _lastScanTime = null;
          });
        }
        break;
    }
  }

  Future<bool> _showNetworkRetryDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(
            Icons.cloud_off,
            color: Colors.orange,
            size: 38,
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop(false);
              },
              child: const Text('Scan Another QR'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF17365D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop(true);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _showSecurityDialog({
    required String title,
    required String message,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFFDC2626),
              size: 38,
            ),
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF991B1B),
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF17365D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Scan Another GPID'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showErrorDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Icon(
            icon,
            color: iconColor,
            size: 38,
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF17365D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
        title: const Text(
          'Scan GPID QR Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle Flashlight',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            tooltip: 'Switch Camera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Live Camera Preview
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),

          // 2. Viewfinder Overlay
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ScannerOverlayPainter(),
          ),

          // 3. Top Instructive Banner
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white24,
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    'Position QR Code Inside the Frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Server-side jurisdiction is enforced for your Police Station.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // 4. Processing / Verification Banner
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF17365D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage ?? 'Processing...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
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

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const boxSize = 260.0;
    final left = (size.width - boxSize) / 2;
    final top = (size.height - boxSize) / 2 - 40;
    final rect = Rect.fromLTWH(left, top, boxSize, boxSize);

    // Dark semi-transparent background around cut-out
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(bgPath, bgPaint);

    // Corner border highlights
    final borderPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const cornerLength = 28.0;
    const radius = 16.0;

    // Top-Left Corner
    final tlPath = Path()
      ..moveTo(left, top + cornerLength)
      ..lineTo(left, top + radius)
      ..arcToPoint(
        Offset(left + radius, top),
        radius: const Radius.circular(radius),
      )
      ..lineTo(left + cornerLength, top);
    canvas.drawPath(tlPath, borderPaint);

    // Top-Right Corner
    final trPath = Path()
      ..moveTo(left + boxSize - cornerLength, top)
      ..lineTo(left + boxSize - radius, top)
      ..arcToPoint(
        Offset(left + boxSize, top + radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(left + boxSize, top + cornerLength);
    canvas.drawPath(trPath, borderPaint);

    // Bottom-Left Corner
    final blPath = Path()
      ..moveTo(left, top + boxSize - cornerLength)
      ..lineTo(left, top + boxSize - radius)
      ..arcToPoint(
        Offset(left + radius, top + boxSize),
        radius: const Radius.circular(radius),
      )
      ..lineTo(left + cornerLength, top + boxSize);
    canvas.drawPath(blPath, borderPaint);

    // Bottom-Right Corner
    final brPath = Path()
      ..moveTo(left + boxSize - cornerLength, top + boxSize)
      ..lineTo(left + boxSize - radius, top + boxSize)
      ..arcToPoint(
        Offset(left + boxSize, top + boxSize - radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(left + boxSize, top + boxSize - cornerLength);
    canvas.drawPath(brPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
