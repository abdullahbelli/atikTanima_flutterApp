/// Uygulama genelinde kullanılan sabitler
class AppConstants {
  // Uygulama Bilgileri
  static const String appName = 'Atık Tanıma';
  static const String appVersion = '1.0.0';

  // Kamera Ayarları
  static const double cameraAspectRatio = 9 / 16;
  static const int maxImageSize = 2048; // piksel cinsinden

  // UI Sabitleri
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;

  // Animasyon Süreleri
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Hata Mesajları
  static const String cameraPermissionDenied = 'Kamera izni reddedildi';
  static const String cameraNotFound = 'Kamera bulunamadı';
  static const String cameraInitFailed = 'Kamera başlatılamadı';
  static const String photoCaptureFailed = 'Fotoğraf çekilemedi';
  static const String gallerySelectionFailed = 'Galeriden seçilemedi';

  // Başarı Mesajları
  static const String photoCaptured = 'Fotoğraf başarıyla çekildi';
  static const String imageSelected = 'Görüntü başarıyla seçildi';

  // Lottie Animasyon Yolları
  static const String doneAnimationPath = 'assets/animations/Done.json';

  // Model ve Label Yolları
  static const String detectModelPath = 'assets/models/wastedetect.tflite';
  static const String segmentModelPath = 'assets/models/waste_segment.tflite';
  static const String labelsPath = 'assets/labels/classes.txt';
}
