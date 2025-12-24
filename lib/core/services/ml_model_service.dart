import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../constants/app_constants.dart';

enum ModelTask { detect, segment }

class MlModelService {
  MlModelService._();
  static final MlModelService instance = MlModelService._();

  Interpreter? _interpreter;
  List<String> _labels = [];
  ModelTask? _loadedTask;

  bool get isLoaded => _interpreter != null && _loadedTask != null;
  ModelTask? get loadedTask => _loadedTask;
  List<String> get labels => List.unmodifiable(_labels);

  /// Detect veya Segment modelini assets'ten yükler + labels okur.
  Future<void> load({required ModelTask task}) async {
    if (isLoaded && _loadedTask == task) return;

    await dispose();

    final modelAssetPath = switch (task) {
      ModelTask.detect => AppConstants.detectModelPath,
      ModelTask.segment => AppConstants.segmentModelPath,
    };

    try {
      // 1) Model bytes: asset gerçekten bundle'a girmiş mi?
      final ByteData bd = await rootBundle.load(modelAssetPath);
      final Uint8List bytes = bd.buffer.asUint8List();

      if (kDebugMode) {
        debugPrint("✅ Model asset loaded: $modelAssetPath");
        debugPrint("✅ Model byte size: ${bytes.length}");
      }

      // 2) Interpreter oluştur (daha stabil: fromBuffer)
      final options = InterpreterOptions()..threads = 4;

      _interpreter = await Interpreter.fromBuffer(bytes, options: options);

      // 3) Labels oku
      _labels = await _loadLabels(AppConstants.labelsPath);

      _loadedTask = task;

      // 4) Debug: input / output tensor bilgisi
      if (kDebugMode) {
        final inT = _interpreter!.getInputTensors();
        final outT = _interpreter!.getOutputTensors();

        debugPrint("📥 INPUT TENSORS:");
        for (final t in inT) {
          debugPrint("  - shape=${t.shape}, type=${t.type}");
        }

        debugPrint("📤 OUTPUT TENSORS:");
        for (final t in outT) {
          debugPrint("  - shape=${t.shape}, type=${t.type}");
        }

        debugPrint("🏷️ Labels count: ${_labels.length}");
      }
    } catch (e, st) {
      await dispose();
      if (kDebugMode) {
        debugPrint("❌ Model load failed for: $modelAssetPath");
        debugPrint("❌ Error: $e");
        debugPrint("$st");
      }
      rethrow;
    }
  }

  Future<List<String>> _loadLabels(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      // labels yoksa bile model çalışabilir; ama sen sınıf adı istiyorsun.
      // İstersen burada rethrow yapabilirsin.
      if (kDebugMode) {
        debugPrint("⚠️ Labels load failed: $assetPath");
        debugPrint("⚠️ Error: $e");
      }
      return [];
    }
  }

  Interpreter get interpreter {
    final itp = _interpreter;
    if (itp == null) {
      throw StateError('Model yüklenmemiş. Önce load() çağırmalısın.');
    }
    return itp;
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _loadedTask = null;
    _labels = [];
  }
}
