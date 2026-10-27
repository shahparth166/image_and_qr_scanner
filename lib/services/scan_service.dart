import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../models/capture_item.dart';

class ScanService {
  final BarcodeScanner _scanner = BarcodeScanner(formats: [BarcodeFormat.all]);
  Future<void>? _lastScan;

  Future<List<ScannedCode>> scan(String imagePath) async {
    final previous = _lastScan;
    final completer = Completer<void>();
    _lastScan = completer.future;

    if (previous != null) {
      try {
        await previous;
      } catch (_) {}
    }

    try {
      return await _scanInternal(imagePath);
    } finally {
      completer.complete();
    }
  }

  Future<List<ScannedCode>> _scanInternal(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw FileSystemException('Captured image does not exist', imagePath);
      }

      final imageSize = await imageFile.length();
      if (imageSize == 0) {
        throw FileSystemException('Captured image is empty', imagePath);
      }

      developer.log(
        'Scanning captured image ($imageSize bytes).',
        name: 'CodeCapture.Scan',
      );

      // The native plugin reads the saved file and its orientation metadata.
      final inputImage = InputImage.fromFilePath(imagePath);
      final barcodes = await _scanner.processImage(inputImage);

      final codes = <ScannedCode>[];
      for (final barcode in barcodes) {
        final value = (barcode.rawValue ?? barcode.displayValue ?? '').trim();
        if (value.isEmpty) continue;

        codes.add(
          ScannedCode(
            kind: barcode.format == BarcodeFormat.qrCode
                ? CodeKind.qr
                : CodeKind.barcode,
            format: _formatName(barcode.format),
            value: value,
          ),
        );
      }

      developer.log(
        codes.isEmpty
            ? 'Scan completed; no readable codes were found.'
            : 'Scan completed; decoded ${codes.length} code(s).',
        name: 'CodeCapture.Scan',
      );
      return codes;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to scan captured image: $imagePath',
        name: 'CodeCapture.Scan',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  Future<void> dispose() => _scanner.close();

  static String _formatName(BarcodeFormat f) {
    switch (f) {
      case BarcodeFormat.qrCode:
        return 'QR Code';
      case BarcodeFormat.code128:
        return 'Code 128';
      case BarcodeFormat.code39:
        return 'Code 39';
      case BarcodeFormat.code93:
        return 'Code 93';
      case BarcodeFormat.codabar:
        return 'Codabar';
      case BarcodeFormat.dataMatrix:
        return 'Data Matrix';
      case BarcodeFormat.ean13:
        return 'EAN-13';
      case BarcodeFormat.ean8:
        return 'EAN-8';
      case BarcodeFormat.itf:
        return 'ITF';
      case BarcodeFormat.upca:
        return 'UPC-A';
      case BarcodeFormat.upce:
        return 'UPC-E';
      case BarcodeFormat.pdf417:
        return 'PDF417';
      case BarcodeFormat.aztec:
        return 'Aztec';
      default:
        return 'Barcode';
    }
  }
}
