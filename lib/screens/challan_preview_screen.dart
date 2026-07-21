import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class ChallanPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;

  const ChallanPreviewScreen({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challan Preview'),
        backgroundColor: const Color(0xFF1746A2),
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: (format) async => pdfBytes,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
      ),
    );
  }
}
