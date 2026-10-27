import 'dart:developer' as developer;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../app/constants/app_colors.dart';
import '../app/constants/app_text.dart';
import '../models/capture_item.dart';
import '../services/scan_service.dart';
import 'results_view.dart';
import '../widgets/action_buttons.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CameraScreenController());
    return GetBuilder<CameraScreenController>(
      builder: (_) => controller.buildScreen(context),
    );
  }
}

class CameraScreenController extends GetxController
    with WidgetsBindingObserver {
  final ScanService _scanner = ScanService();
  final List<CaptureItem> _items = [];
  final List<Future<void>> _scans = [];

  CameraController? _controller;
  String? _error;

  bool _active = false;
  bool _finishing = false;
  bool _draining = false;
  int _pending = 0;
  bool _flash = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _scanner.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive) {
      if (c != null) {
        _controller = null;
        c.dispose();
        update();
      }
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _error = 'No camera found on this device.';
        update();
        return;
      }
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (isClosed) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      _error = null;
      update();
    } on CameraException catch (e) {
      if (isClosed) return;
      _error = e.code.contains('Denied') || e.code.contains('denied')
          ? 'Camera permission was denied. Enable it in system settings.'
          : 'Camera error: ${e.description ?? e.code}';
      update();
    }
  }

  void _start() {
    if (_active || _finishing || _controller == null) return;
    _items.clear();
    _scans.clear();
    _active = true;
    update();
  }

  void _capture() {
    final c = _controller;
    if (!_active || _finishing || c == null || !c.value.isInitialized) return;
    HapticFeedback.selectionClick();
    _pending++;
    _flashShutter();
    update();
    if (!_draining) {
      _draining = true;
      _drain();
    }
  }

  Future<void> _drain() async {
    while (_pending > 0) {
      final c = _controller;
      if (c == null || !c.value.isInitialized) {
        _pending = 0;
        break;
      }
      try {
        final shot = await c.takePicture();
        final item = CaptureItem(id: _items.length + 1, path: shot.path);
        _items.add(item);
        _scans.add(_scan(item));
      } on CameraException catch (e) {
        debugPrint('takePicture failed: ${e.code}');
      }
      _pending--;
      update();
    }
    _draining = false;
  }

  Future<void> _scan(CaptureItem item) async {
    try {
      item.codes = await _scanner.scan(item.path);
    } catch (error, stackTrace) {
      developer.log(
        'QR/barcode scan failed for photo #${item.id}.',
        name: 'CodeCapture.Camera',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      item.errorMessage = error.toString();
      item.codes = const [];
    }
  }

  Future<void> _stop() async {
    if (!_active || _finishing) return;
    _active = false;
    _finishing = true;
    update();

    while (_draining) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await Future.wait(_scans);
    if (isClosed) return;

    final items = List<CaptureItem>.of(_items);
    _finishing = false;
    update();

    if (items.isEmpty) {
      final context = Get.context;
      if (context != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(AppText.noImages)));
      }
      return;
    }

    await Get.to<void>(() => ResultsScreen(items: items));
    if (isClosed) return;
    _items.clear();
    _scans.clear();
    update();
  }

  void _flashShutter() {
    _flash = true;
    update();
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!isClosed) {
        _flash = false;
        update();
      }
    });
  }

  Widget buildScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _flash ? 0.5 : 0,
              duration: const Duration(milliseconds: 60),
              child: const ColoredBox(color: Colors.white),
            ),
          ),
          SafeArea(
            child: Column(
              children: [_buildStatusBar(), const Spacer(), _buildControls()],
            ),
          ),
          if (_finishing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _capture(),
      child: Center(child: CameraPreview(c)),
    );
  }

  Widget _buildStatusBar() {
    final label = _active
        ? 'Capturing  ·  ${_items.length} photo${_items.length == 1 ? '' : 's'}'
        : 'Tap Start to begin';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _active ? Colors.redAccent : Colors.white38,
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
            if (_pending > 0) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final ready = _controller != null && !_finishing;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ActionPillButton(
            label: AppText.start,
            icon: Icons.play_arrow_rounded,
            color: AppColors.start,
            onPressed: ready && !_active ? _start : null,
          ),
          ShutterButton(enabled: ready && _active, onPressed: _capture),
          ActionPillButton(
            label: AppText.stop,
            icon: Icons.stop_rounded,
            color: AppColors.stop,
            onPressed: ready && _active ? _stop : null,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return const ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(AppText.readingCodes, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
