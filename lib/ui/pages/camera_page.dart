import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:atik_tanima/ui/pages/preview_page.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  String? _error;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _error = "Kamera bulunamadı.");
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isCameraInitialized = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Kamera başlatılamadı: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      // Galeri gibi başka bir ekrandan dönünce kamera tekrar başlasın
      if (!_isCameraInitialized || _controller == null) {
        await _initCamera();
      }
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Kamera kaynağını serbest bırak
      await _controller?.dispose();
      if (!mounted) return;
      setState(() {
        _controller = null;
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final XFile file = await _controller!.takePicture();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PreviewPage(imagePath: file.path)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Fotoğraf çekilemedi: $e")));
    } finally {
      if (!mounted) {
        return;
      }
      setState(() => _isTakingPicture = false);
    }
  }

  Future<void> _openGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return; // kullanıcı iptal etti
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PreviewPage(imagePath: picked.path)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Galeriden seçilemedi: $e")));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hata / yükleniyor durumları
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Kamera"),
          backgroundColor: Colors.green,
        ),
        body: Center(child: Text(_error!, textAlign: TextAlign.center)),
      );
    }

    if (!_isCameraInitialized || _controller == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Kamera"),
          backgroundColor: Colors.green,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Kamera hazırsa: preview + overlay butonlar
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Kamera"),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),

          // Alt ortada butonlar (kamera preview üstünde)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: "btn_camera",
                  backgroundColor: Colors.green,
                  onPressed: _isTakingPicture ? null : _takePicture,
                  child: _isTakingPicture
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Icon(Icons.camera_alt),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  heroTag: "btn_gallery",
                  backgroundColor: Colors.white,
                  onPressed: _openGallery,
                  child: const Icon(Icons.photo_library, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
