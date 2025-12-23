import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_page.dart';
import 'core/theme/app_theme.dart';

/// Uygulama giriş noktası
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Tercih edilen ekran yönlendirmelerini ayarla (sadece dikey)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const AtikTanimaApp());
}

/// Ana uygulama widget'ı
class AtikTanimaApp extends StatelessWidget {
  const AtikTanimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atık Tanıma',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light, // Her zaman açık tema kullan
      home: const HomePage(),
    );
  }
}
