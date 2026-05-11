import 'package:campus_club/models/qr_attendance_payload.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/providers/meeting_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanAttendanceScreen extends ConsumerStatefulWidget {
  const ScanAttendanceScreen({super.key});

  @override
  ConsumerState<ScanAttendanceScreen> createState() =>
      _ScanAttendanceScreenState();
}

class _ScanAttendanceScreenState extends ConsumerState<ScanAttendanceScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performCheckIn(String raw) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    try {
      final payload = QrAttendancePayload.parse(raw);
      await ref.read(meetingServiceProvider).markAttendanceByQr(
            clubId: payload.clubId,
            meetingId: payload.meetingId,
            qrToken: payload.token,
            user: user,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ You are marked present.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _processing = true);
    try {
      await _performCheckIn(raw);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _pickQrFromGallery() async {
    if (_processing) return;
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choosing a QR from photos is available on Android and iOS only.',
          ),
        ),
      );
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    setState(() => _processing = true);
    try {
      final capture = await _controller.analyzeImage(
        picked.path,
        formats: const [BarcodeFormat.qrCode],
      );
      final barcodes = capture?.barcodes ?? const <Barcode>[];
      String? raw;
      for (final b in barcodes) {
        final v = b.rawValue;
        if (v != null && v.isNotEmpty) {
          raw = v;
          break;
        }
      }
      if (raw == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No QR code found in this image.'),
          ),
        );
        return;
      }
      await _performCheckIn(raw);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not read image: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan meeting QR'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Card(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Check in',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Point the camera at the QR code your club BoD is showing, '
                      'or upload a photo of it. Student account required; '
                      'you must be a club member.',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!kIsWeb)
                      OutlinedButton.icon(
                        onPressed: _processing ? null : _pickQrFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Choose from gallery'),
                      ),
                    if (_processing) ...[
                      const SizedBox(height: 12),
                      const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ],
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
