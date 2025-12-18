import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:atik_tanima/ui/pages/camera_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _items = <WasteItem>[
    WasteItem(
      type: WasteType.glass,
      subtitle:
          "Cam gıda kapları, meyve suyu şişeleri, konserve kavanozu, bardak vb.",
    ),
    WasteItem(
      type: WasteType.paper,
      subtitle: "Kağıt, kitap, peçete, karton kutu vb.",
    ),
    WasteItem(
      type: WasteType.metal,
      subtitle: "İçecek Kutuları, konserve kutuları vb.",
    ),
    WasteItem(
      type: WasteType.organic,
      subtitle: "Meyve kabuğu, sebze, yaprak vb.",
    ),
    WasteItem(
      type: WasteType.plastic,
      subtitle: "Plastik şişe, poşet, kap, kapak, kutu vb.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          "Atık Tanıma",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _BuildMainPickerCard(onTap: () => _openCamera(context)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _WasteCard(
                    item: item,
                    onTap: () => _showWasteInfoDialog(context, item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CameraPage()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Kamera izni reddedildi")));
    }
  }

  void _showWasteInfoDialog(BuildContext context, WasteItem item) {
    final ui = WasteUi.of(item.type);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: ui.dialogColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ui.icon, size: 44, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  ui.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Sınıf açıklaması",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text("Kapat"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ---------- Models ----------

enum WasteType { glass, paper, metal, organic, plastic }

class WasteItem {
  final WasteType type;
  final String subtitle;

  const WasteItem({required this.type, required this.subtitle});
}

/// UI config tek yerden yönetilsin (ikon/renk/title)
class WasteUi {
  final String title;
  final IconData icon;
  final Color dialogColor;

  const WasteUi({
    required this.title,
    required this.icon,
    required this.dialogColor,
  });

  static WasteUi of(WasteType type) {
    switch (type) {
      case WasteType.glass:
        return const WasteUi(
          title: "Cam Atıklar",
          icon: Icons.wine_bar,
          dialogColor: Color(0xFF2E7D32),
        );
      case WasteType.paper:
        return const WasteUi(
          title: "Kağıt Atıklar",
          icon: Icons.description,
          dialogColor: Color(0xFF1565C0),
        );
      case WasteType.metal:
        return const WasteUi(
          title: "Metal Atıklar",
          icon: Icons.kitchen,
          dialogColor: Color(0xFF6D4C41),
        );
      case WasteType.organic:
        return const WasteUi(
          title: "Organik Atıklar",
          icon: Icons.eco,
          dialogColor: Color(0xFF558B2F),
        );
      case WasteType.plastic:
        return const WasteUi(
          title: "Plastik Atıklar",
          icon: Icons.local_drink,
          dialogColor: Color(0xFF6A1B9A),
        );
    }
  }
}

/// ---------- Small UI widgets (readability) ----------

class _BuildMainPickerCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BuildMainPickerCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.photo_camera, size: 50, color: Colors.grey),
            SizedBox(width: 10),
            Text("veya", style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(width: 10),
            Icon(Icons.photo_library, size: 50, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _WasteCard extends StatelessWidget {
  final WasteItem item;
  final VoidCallback onTap;

  const _WasteCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ui = WasteUi.of(item.type);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        leading: Icon(ui.icon, color: Colors.green),
        title: Text(
          ui.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(item.subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.green),
        onTap: onTap,
      ),
    );
  }
}
