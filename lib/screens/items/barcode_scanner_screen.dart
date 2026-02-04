import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  String? _scannedBarcode;
  bool _isFlashOn = false;
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
              cameraController.toggleTorch();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera scanner
                MobileScanner(
                  controller: cameraController,
                  onDetect: _onBarcodeDetected,
                  fit: BoxFit.cover,
                ),

                // Scanner overlay using CustomPaint
                CustomPaint(
                  painter: ScannerOverlayPainter(),
                ),

                // Scanning instructions
                Positioned(
                  top: MediaQuery.of(context).padding.top + 100,
                  left: 0,
                  right: 0,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Align barcode within the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              children: [
                if (_scannedBarcode != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Scanned: $_scannedBarcode',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showManualEntryDialog();
                        },
                        icon: const Icon(Icons.keyboard),
                        label: const Text('Enter Manually'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _resetScanner,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() {
          _scannedBarcode = barcode.rawValue!;
          _isScanning = false;
        });

        // Haptic feedback
        HapticFeedback.lightImpact();

        // Return the scanned barcode after a short delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            Navigator.pop(context, _scannedBarcode);
          }
        });
        break;
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _scannedBarcode = null;
      _isScanning = true;
    });
  }

  void _showManualEntryDialog() {
    final manualController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Barcode Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter the barcode number:'),
            const SizedBox(height: 16),
            TextField(
              controller: manualController,
              decoration: const InputDecoration(
                labelText: 'Barcode',
                border: OutlineInputBorder(),
                hintText: 'Enter barcode number',
              ),
              keyboardType: TextInputType.text,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final barcode = manualController.text.trim();
              if (barcode.isNotEmpty) {
                Navigator.pop(context);
                Navigator.pop(context, barcode);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

// Improved scanner overlay painter
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    // Calculate overlay dimensions
    final width = size.width;
    final height = size.height;
    final center = Offset(width / 2, height / 2);

    // Make scanner area responsive - use 70% of screen width
    final scannerSize = width * 0.7;
    final scannerRect = Rect.fromCenter(
      center: center,
      width: scannerSize,
      height: scannerSize * 0.6, // Rectangular shape for barcodes
    );

    // Draw background overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height));

    // Cut out the scanner area
    path.addRRect(
      RRect.fromRectAndRadius(
        scannerRect,
        const Radius.circular(12),
      ),
    );

    canvas.drawPath(path, paint);

    // Draw scanner border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        scannerRect,
        const Radius.circular(12),
      ),
      borderPaint,
    );

    // Draw animated scanning line
    final linePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final linePosition = (now % 2000) / 2000; // 2 second cycle

    final lineY = scannerRect.top + (scannerRect.height * linePosition);

    canvas.drawLine(
      Offset(scannerRect.left, lineY),
      Offset(scannerRect.right, lineY),
      linePaint,
    );

    // Draw corner marks
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLength = 25.0;

    // Top left corner
    canvas.drawLine(
      scannerRect.topLeft,
      scannerRect.topLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scannerRect.topLeft,
      scannerRect.topLeft + const Offset(0, cornerLength),
      cornerPaint,
    );

    // Top right corner
    canvas.drawLine(
      scannerRect.topRight,
      scannerRect.topRight - const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scannerRect.topRight,
      scannerRect.topRight + const Offset(0, cornerLength),
      cornerPaint,
    );

    // Bottom left corner
    canvas.drawLine(
      scannerRect.bottomLeft,
      scannerRect.bottomLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scannerRect.bottomLeft,
      scannerRect.bottomLeft - const Offset(0, cornerLength),
      cornerPaint,
    );

    // Bottom right corner
    canvas.drawLine(
      scannerRect.bottomRight,
      scannerRect.bottomRight - const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scannerRect.bottomRight,
      scannerRect.bottomRight - const Offset(0, cornerLength),
      cornerPaint,
    );

    // Draw help text at the bottom of scanner area
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Position barcode here',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        scannerRect.bottom + 20,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Return true for animated line
  }
}