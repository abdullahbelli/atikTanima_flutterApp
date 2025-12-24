import 'package:flutter/material.dart';

/// Atık türleri enum'u
enum WasteType {
  glass,    // Cam
  paper,    // Kağıt
  metal,    // Metal
  organic,  // Organik
  plastic,  // Plastik
}

/// Atık öğesi modeli
class WasteItem {
  final WasteType type;
  final String subtitle;

  const WasteItem({
    required this.type,
    required this.subtitle,
  });
}

/// Atık türleri için UI yapılandırması (ikon, renk, başlık)
class WasteUi {
  final String title;
  final IconData icon;
  final Color dialogColor;
  final Color cardColor;
  final Color iconColor;

  const WasteUi({
    required this.title,
    required this.icon,
    required this.dialogColor,
    required this.cardColor,
    required this.iconColor,
  });

  /// Atık türüne göre UI yapılandırmasını döndürür
  static WasteUi of(WasteType type) {
    switch (type) {
      case WasteType.glass:
        return const WasteUi(
          title: 'Cam Atıklar',
          icon: Icons.wine_bar,
          dialogColor: Color(0xFF2E7D32),
          cardColor: Color(0xFFE8F5E9),
          iconColor: Color(0xFF2E7D32),
        );
      case WasteType.paper:
        return const WasteUi(
          title: 'Kağıt Atıklar',
          icon: Icons.description,
          dialogColor: Color(0xFF1565C0),
          cardColor: Color(0xFFE3F2FD),
          iconColor: Color(0xFF1565C0),
        );
      case WasteType.metal:
        return const WasteUi(
          title: 'Metal Atıklar',
          icon: Icons.kitchen,
          dialogColor: Color(0xFF6D4C41),
          cardColor: Color(0xFFEFEBE9),
          iconColor: Color(0xFF6D4C41),
        );
      case WasteType.organic:
        return const WasteUi(
          title: 'Organik Atıklar',
          icon: Icons.eco,
          dialogColor: Color(0xFF558B2F),
          cardColor: Color(0xFFF1F8E9),
          iconColor: Color(0xFF558B2F),
        );
      case WasteType.plastic:
        return const WasteUi(
          title: 'Plastik Atıklar',
          icon: Icons.local_drink,
          dialogColor: Color(0xFF6A1B9A),
          cardColor: Color(0xFFF3E5F5),
          iconColor: Color(0xFF6A1B9A),
        );
    }
  }
}
