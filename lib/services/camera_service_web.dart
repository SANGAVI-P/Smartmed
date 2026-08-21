// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> captureWebPhoto(BuildContext context) async {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const WebCameraDialog();
    },
  );
}

class WebCameraDialog extends StatefulWidget {
  const WebCameraDialog({super.key});

  @override
  State<WebCameraDialog> createState() => _WebCameraDialogState();
}

class _WebCameraDialogState extends State<WebCameraDialog> {
  html.VideoElement? _videoElement;
  html.MediaStream? _stream;
  String? _error;
  bool _initialized = false;
  String? _viewId;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _viewId = 'webcam-view-${DateTime.now().millisecondsSinceEpoch}';
    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    // Register view factory using dart:ui_web
    ui_web.platformViewRegistry.registerViewFactory(_viewId!, (int viewId) => _videoElement!);

    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception('Camera is not available on this device. Please use Upload Photo instead.');
      }
      final stream = await mediaDevices.getUserMedia({'video': true});
      _stream = stream;
      _videoElement!.srcObject = stream;
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      final errorStr = e.toString();
      setState(() {
        if (errorStr.contains('NotAllowedError') || errorStr.contains('PermissionDeniedError') || errorStr.contains('Permission denied')) {
          _error = 'Camera access is required to take a prescription photo. Please allow camera permission in your browser settings.';
        } else {
          _error = 'Camera is not available on this device. Please use Upload Photo instead.';
        }
      });
    }
  }

  void _capture() {
    if (_videoElement == null || !_initialized) return;

    final canvas = html.CanvasElement(
      width: _videoElement!.videoWidth,
      height: _videoElement!.videoHeight,
    );
    final ctx = canvas.context2D;
    ctx.drawImage(_videoElement!, 0, 0);

    final dataUrl = canvas.toDataUrl('image/jpeg');
    final base64String = dataUrl.split(',')[1];
    final bytes = base64.decode(base64String);

    _stopStream();

    Navigator.of(context).pop({
      'bytes': bytes,
      'name': 'webcam_capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
      'size': bytes.length,
    });
  }

  void _stopStream() {
    if (_stream != null) {
      for (var track in _stream!.getTracks()) {
        track.stop();
      }
      _stream = null;
    }
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Take Prescription',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 320,
                color: Colors.black,
                child: _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : !_initialized
                        ? const Center(
                            child: CircularProgressIndicator(color: Color(0xff3b82f6)),
                          )
                        : HtmlElementView(viewType: _viewId!),
              ),
            ),
            const SizedBox(height: 24),
            if (_error == null && _initialized) ...[
              ElevatedButton.icon(
                onPressed: _capture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff3b82f6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Capture Photo', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
            ],
            TextButton(
              onPressed: () {
                _stopStream();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
