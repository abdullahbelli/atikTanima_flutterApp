import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'preview_page.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';

/// Kamera sayfası - Fotoğraf çekme ve galeri seçimi
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
  bool _isFlashOn = false;
  bool _hasFlash = false;
  bool _isDisposing = false; // Sayfa kapatılırken flag

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  /// Kamerayı başlatır
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _error = AppConstants.cameraNotFound);
        return;
      }

      // Arka kamera tercih edilir, yoksa ilk kullanılabilir kamera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
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
      setState(() => _error = '${AppConstants.cameraInitFailed}: $e');
    }
  }

  /// Uygulama yaşam döngüsü değişikliklerini dinler
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_isDisposing || !_isCameraInitialized || _controller == null) return;

    // Uygulama arka plana gittiğinde kamerayı serbest bırak
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      await _controller?.dispose();
      if (!mounted || _isDisposing) return;
      setState(() {
        _controller = null;
        _isCameraInitialized = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama ön plana döndüğünde kamerayı tekrar başlat
      if (!_isDisposing && mounted) {
        await _initCamera();
      }
    }
  }

  /// Fotoğraf çeker
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final XFile file = await _controller!.takePicture();
      if (!mounted) return;

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PreviewPage(imagePath: file.path),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(
        context,
        '${AppConstants.photoCaptureFailed}: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isTakingPicture = false);
      }
    }
  }

  /// Galeriden görüntü seçer
  Future<void> _openGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: AppConstants.maxImageSize.toDouble(),
        maxHeight: AppConstants.maxImageSize.toDouble(),
        imageQuality: 85,
      );

      if (picked == null) return; // Kullanıcı iptal etti
      if (!mounted) return;

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PreviewPage(imagePath: picked.path),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(
        context,
        '${AppConstants.gallerySelectionFailed}: $e',
      );
    }
  }

  /// Flash'ı açıp kapatır
  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.auto;
      await _controller!.setFlashMode(newFlashMode);
      if (!mounted) return;
      setState(() {
        _isFlashOn = !_isFlashOn;
        _hasFlash = true; // Flash modu ayarlanabiliyorsa flash mevcut
      });
    } catch (e) {
      // Bu cihazda flash mevcut değil
      if (mounted) {
        setState(() => _hasFlash = false);
      }
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Hata Durumu
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _error = null);
                      _initCamera();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      if (!_isDisposing) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: TextButton.styleFrom(
                      enableFeedback: false,
                    ),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    label: const Text(
                      'Geri Dön',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Yükleniyor Durumu - Kamera hazır olana kadar overlay göster
    if (!_isCameraInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Siyah arka plan
            Container(color: Colors.black),
            // Yükleme göstergesi
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            // Geri butonu
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  enableFeedback: false,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () {
                    if (!_isDisposing) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Kamera Hazır
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          enableFeedback: false,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () {
            if (!_isDisposing) {
              _isDisposing = true;
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          // Flash butonu
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: _isFlashOn ? Colors.amber : Colors.white,
              ),
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Kamera Önizlemesi
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Alt Kontroller
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Galeri Butonu
                    _CameraControlButton(
                      icon: Icons.photo_library,
                      onTap: _openGallery,
                      backgroundColor: Colors.white.withOpacity(0.3),
                    ),

                    const SizedBox(width: 24),

                    // Fotoğraf Çekme Butonu
                    GestureDetector(
                      onTap: _isTakingPicture ? null : _takePicture,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 4,
                          ),
                        ),
                        child: _isTakingPicture
                            ? Padding(
                                padding: const EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Simetri için placeholder
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kamera kontrol butonu widget'ı
class _CameraControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;

  const _CameraControlButton({
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
