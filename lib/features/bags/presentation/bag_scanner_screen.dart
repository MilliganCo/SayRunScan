import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BagScannerScreen extends StatefulWidget {
  const BagScannerScreen({super.key});

  @override
  State<BagScannerScreen> createState() => _BagScannerScreenState();
}

class _BagScannerScreenState extends State<BagScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  String? _last;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue ?? '';
          if (code.isEmpty || code == _last) return;
          _last = code;
          String value = code;
          final ssccReg = RegExp(r'^\d{18,20}$');
          if (!ssccReg.hasMatch(code)) {
            if (code.length >= 31) {
              value = code.substring(0, 31);
            }
          }
          _controller.stop();
          Navigator.pop(context, value);
        },
      ),
    );
  }
}
