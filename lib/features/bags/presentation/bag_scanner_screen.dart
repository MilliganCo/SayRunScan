import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BagScannerScreen extends StatefulWidget {
  const BagScannerScreen({super.key});

  @override
  State<BagScannerScreen> createState() => _BagScannerScreenState();
}

class _BagScannerScreenState extends State<BagScannerScreen> {
  String? _last;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MobileScanner(
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
          Navigator.pop(context, value);
        },
      ),
    );
  }
}
