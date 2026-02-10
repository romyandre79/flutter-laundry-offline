import 'dart:io';
import 'package:camera/camera.dart';
import 'package:camera_windows/camera_windows.dart';
import 'package:flutter/material.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';

class WindowsCameraScreen extends StatefulWidget {
  const WindowsCameraScreen({super.key});

  @override
  State<WindowsCameraScreen> createState() => _WindowsCameraScreenState();
}

class _WindowsCameraScreenState extends State<WindowsCameraScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Use CameraWindows explicitly to get cameras on Windows
      if (Platform.isWindows) {
        _cameras = await CameraWindows().availableCameras();
      } else {
        _cameras = await availableCameras();
      }

      if (_cameras.isEmpty) {
        setState(() {
          _error = 'Tidak ada kamera ditemukan';
        });
        return;
      }

      await _startCamera(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() {
        _error = 'Gagal menginisialisasi kamera: $e';
      });
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memulai kamera: $e';
        });
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final XFile file = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: AppThemeColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  void _switchCamera() async {
    if (_cameras.length <= 1) return;

    setState(() {
      _isInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });

    await _controller?.dispose();
    await _startCamera(_cameras[_selectedCameraIndex]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ambil Foto', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.switch_camera),
              onPressed: _isInitialized && !_isTakingPicture ? _switchCamera : null,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: CameraPreview(_controller!),
          ),
        ),
        Container(
          height: 100,
          color: Colors.black,
          child: Center(
            child: _isTakingPicture
                ? const CircularProgressIndicator()
                : GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
