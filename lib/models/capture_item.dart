enum CodeKind { qr, barcode }

class ScannedCode {
  const ScannedCode({
    required this.kind,
    required this.format,
    required this.value,
  });

  final CodeKind kind;

  final String format;

  final String value;
}

class CaptureItem {
  CaptureItem({required this.id, required this.path});

  final int id;
  final String path;
  List<ScannedCode> codes = const [];
  String? errorMessage;

  bool get hasQr => codes.any((c) => c.kind == CodeKind.qr);
  bool get hasBarcode => codes.any((c) => c.kind == CodeKind.barcode);
  bool get hasCode => codes.isNotEmpty;
}
