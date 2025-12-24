# Atık Tanıma (Waste Recognition) Uygulaması

Modern Flutter uygulaması ile atık tanıma ve sınıflandırma. Bu uygulama, kullanıcıların kamera ile fotoğraf çekerek veya galeriden seçerek farklı atık türlerini tanımlamasına ve sınıflandırmasına yardımcı olur.

## 🌟 Özellikler

### Ana Özellikler
- **Modern UI/UX**: Material Design 3 ile güzel ve akıcı animasyonlu arayüz
- **Bottom Navigation**: Ana sayfa, Geçmiş ve İstatistikler arasında kolay gezinme
- **Gelişmiş Kamera Özellikleri**:
  - Zoom desteği (+ ve - butonları ile)
  - Ön/Arka kamera değiştirme
  - Flash kontrolü (Otomatik/Kapalı)
  - Yüksek kalite fotoğraf çekimi
- **Galeri Desteği**: Cihaz galerisinden görüntü seçme
- **Atık Kategorileri**:
  - 🍾 Cam (Glass)
  - 📄 Kağıt (Paper)
  - 🥫 Metal (Metal)
  - 🍃 Organik (Organic)
  - ♻️ Plastik (Plastic)

### Gelişmiş Tanıma Özellikleri
- **Detaylı Sonuçlar**: Tanıma sonrası kapsamlı bilgi kartı
- **Güven Skoru**: Tanıma doğruluğu yüzdesi
- **Geri Dönüşüm Tavsiyeleri**: Her atık türü için özel tavsiyeler
- **Görsel Geri Bildirim**: Renkli kartlar ve ikonlar

### Diğer Özellikler
- **Koyu Mod Desteği**: Sistem tercihlerine göre otomatik tema değişimi
- **Akıcı Animasyonlar**: Uygulama genelinde profesyonel geçişler ve animasyonlar
- **Lottie Animasyonları**: Başarı durumları için görsel animasyonlar
- **Hata Yönetimi**: Kapsamlı hata yönetimi ve kullanıcı dostu mesajlar
- **Modern Renk Paleti**: Çevre dostu yeşil tema ile göz alıcı tasarım

## 📱 Ekran Görüntüleri

*Ekran görüntüleri yakında eklenecek*

## 🏗️ Proje Yapısı

```
lib/
├── core/
│   ├── constants/      # Uygulama geneli sabitler
│   ├── models/        # Veri modelleri
│   ├── theme/         # Tema yapılandırması
│   └── utils/         # Yardımcı fonksiyonlar
└── ui/
    └── pages/         # Uygulama ekranları
```

## 🚀 Başlangıç

### Gereksinimler

- Flutter SDK (3.10.1 veya üzeri)
- Dart SDK
- Android Studio / VS Code (Flutter eklentileri ile)
- Android SDK / Xcode (mobil geliştirme için)

### Kurulum

1. Depoyu klonlayın:
```bash
git clone <repository-url>
cd atikTanima_flutterApp
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. Uygulamayı çalıştırın:
```bash
flutter run
```

## 📦 Bağımlılıklar

- `flutter`: SDK
- `permission_handler: ^12.0.1` - Cihaz izinlerini yönetme
- `camera: ^0.11.0` - Kamera işlevselliği
- `image_picker: ^1.1.2` - Galeriden görüntü seçimi
- `lottie: ^3.1.2` - Lottie animasyon desteği

## 🎨 Tasarım Prensipleri

- **Material Design 3**: Google'ın en son tasarım yönergelerini takip eder
- **Erişilebilirlik**: Yüksek kontrast oranları ve okunabilir yazı tipleri
- **Performans**: Optimize edilmiş görüntü işleme ve kamera kullanımı
- **Kullanıcı Deneyimi**: Sezgisel navigasyon ve net geri bildirim

## 🔧 Yapılandırma

### Kamera Ayarları
- Çözünürlük: Yüksek kalite (`camera_page.dart` içinde yapılandırılabilir)
- Görüntü formatı: JPEG
- Maksimum görüntü boyutu: 2048px (`app_constants.dart` içinde yapılandırılabilir)

### Tema
Uygulama hem açık hem de koyu temaları destekler ve sistem tercihlerine göre otomatik olarak değişir.

## 📝 Geliştirme

### Kod Stili
- Flutter/Dart stil yönergelerini takip eder
- Kod kalitesi için `flutter_lints` kullanır
- Özellik tabanlı yapıda organize edilmiştir

### Yeni Özellik Ekleme
1. `lib/core/models/` içinde modeller oluşturun
2. `lib/core/constants/` içinde sabitler ekleyin
3. `lib/ui/` içinde UI bileşenleri oluşturun
4. Gerekirse `lib/core/theme/` içinde temayı güncelleyin

## ✅ Son Güncellemeler (v1.0.0)

### Yeni Eklenen Özellikler
- ✨ **Gelişmiş Kamera Kontrolleri**: Zoom, kamera değiştirme ve flash özellikleri eklendi
- 🎨 **Yenilenmiş UI**: Modern ve renkli arayüz tasarımı
- 📊 **Detaylı Sonuçlar**: Güven skoru ve geri dönüşüm tavsiyeleri
- 🧭 **Bottom Navigation**: Geçmiş ve İstatistikler sayfaları için hazırlık
- 🎯 **Hata Düzeltmeleri**: Kod optimizasyonu ve performans iyileştirmeleri

## 🔮 Gelecek Geliştirmeler

- [ ] ML tabanlı gerçek atık tanıma (şu anda simülasyon modu)
- [ ] Taranan öğelerin geçmişini kaydetme ve görüntüleme
- [ ] İstatistikler ve analitikler sayfası
- [ ] Çoklu dil desteği (İngilizce, Türkçe, Arapça)
- [ ] Bulut senkronizasyonu ve veri yedekleme
- [ ] Sosyal paylaşım özellikleri
- [ ] Çevrimdışı mod desteği

## 📄 Lisans

Bu proje özeldir ve kamu kullanımı için lisanslanmamıştır.

## 👥 Katkıda Bulunanlar

- Geliştirme Ekibi

## 📞 Destek

Sorunlar ve sorular için lütfen geliştirme ekibiyle iletişime geçin.

---

**Sürüm**: 1.0.0  
**Son Güncelleme**: 2024
