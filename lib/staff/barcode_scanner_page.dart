
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() =>
      _BarcodeScannerPageState();
}

class _BarcodeScannerPageState
    extends State<BarcodeScannerPage> {
  final MobileScannerController controller =
  MobileScannerController();

  bool hasScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product Barcode'),
        actions: [
          IconButton(
            onPressed: () => controller.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (hasScanned) return;

          if (capture.barcodes.isEmpty) return;

          final value = capture.barcodes.first.rawValue;

          if (value == null || value.isEmpty) return;

          hasScanned = true;
          Navigator.pop(context, value);
        },
      ),
    );
  }
}
