import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' show ListShape;

import '../constants/app_constants.dart';
import '../models/detection.dart';
import 'ml_model_service.dart';

class WasteDetector {
  WasteDetector._();
  static final WasteDetector instance = WasteDetector._();

  final MlModelService _ml = MlModelService.instance;

  Future<void> loadDetectModel() => _ml.load(task: ModelTask.detect);

  Future<List<String>> _loadLabels() async {
    final txt = await rootBundle.loadString(AppConstants.labelsPath);
    return txt
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

  /// Çıktı zaten 0..1 ise sigmoid uygulama, logits ise uygula
  double _toProb(double x) {
    if (x >= 0.0 && x <= 1.0) return x;
    return _sigmoid(x);
  }

  double _iou(Rect a, Rect b) {
    final interLeft = math.max(a.left, b.left);
    final interTop = math.max(a.top, b.top);
    final interRight = math.min(a.right, b.right);
    final interBottom = math.min(a.bottom, b.bottom);

    final interW = math.max(0.0, interRight - interLeft);
    final interH = math.max(0.0, interBottom - interTop);
    final interArea = interW * interH;

    final areaA = a.width * a.height;
    final areaB = b.width * b.height;
    final union = areaA + areaB - interArea;

    if (union <= 0) return 0.0;
    return interArea / union;
  }

  List<Detection> _nms(List<Detection> dets, double iouThr) {
    dets.sort((a, b) => b.confidence.compareTo(a.confidence));
    final kept = <Detection>[];

    for (final d in dets) {
      bool keep = true;
      for (final k in kept) {
        if (_iou(d.box, k.box) > iouThr) {
          keep = false;
          break;
        }
      }
      if (keep) kept.add(d);
    }
    return kept;
  }

  /// ✅ NMS'i sınıf bazlı yap
  List<Detection> _nmsPerClass(List<Detection> dets, double iouThr) {
    final byLabel = <String, List<Detection>>{};
    for (final d in dets) {
      byLabel.putIfAbsent(d.label, () => <Detection>[]).add(d);
    }

    final keptAll = <Detection>[];
    for (final e in byLabel.entries) {
      keptAll.addAll(_nms(e.value, iouThr));
    }

    keptAll.sort((a, b) => b.confidence.compareTo(a.confidence));
    return keptAll;
  }

  /// ✅ BoxFit.cover ile aynı: center-crop square + resize 640
  img.Image _centerCropSquare(img.Image src) {
    final w = src.width;
    final h = src.height;
    final size = math.min(w, h);

    final x = ((w - size) / 2).round();
    final y = ((h - size) / 2).round();

    return img.copyCrop(src, x: x, y: y, width: size, height: size);
  }

  Future<List<Detection>> predictDetections(String imagePath) async {
    if (!_ml.isLoaded) {
      throw StateError('Model hazır değil. Önce loadDetectModel() çağır.');
    }

    // ========= 0) Image =========
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return const [];

    final origW = decoded.width;
    final origH = decoded.height;

    // ✅ PREPROCESS: cover ile aynı (center-crop square -> 640x640)
    final cropped = _centerCropSquare(decoded);
    final cropSize = cropped.width; // square
    final resized = img.copyResize(cropped, width: 640, height: 640);

    // ========= 1) Input tensor (1,640,640,3) float32 =========
    final input = Float32List(1 * 640 * 640 * 3);
    int idx = 0;
    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final p = resized.getPixel(x, y);
        input[idx++] = p.r / 255.0;
        input[idx++] = p.g / 255.0;
        input[idx++] = p.b / 255.0;
      }
    }

    // ========= 2) Output =========
    final output = List.generate(
      1,
      (_) => List.generate(9, (_) => List.filled(8400, 0.0)),
    );

    _ml.interpreter.run(input.reshape([1, 640, 640, 3]), output);

    final labels = await _loadLabels();
    final out = output[0]; // channels x 8400

    const int numBoxes = 8400;
    final int channels = out.length; // örn 9
    final int numLabels = labels.length; // örn 5

    // ========= 3) Output formatını otomatik çöz =========
    final bool hasObj = (channels == 5 + numLabels);
    final bool noObj = (channels == 4 + numLabels);

    if (!hasObj && !noObj) {
      debugPrint(
        '[YOLO DEBUG][FATAL] Beklenmeyen output: channels=$channels labels=$numLabels '
        '(beklenen ${4 + numLabels} veya ${5 + numLabels})',
      );
      throw StateError(
        'Beklenmeyen output: channels=$channels, labels=$numLabels. '
        'Beklenen: ${4 + numLabels} veya ${5 + numLabels}',
      );
    }

    final int clsStart = hasObj ? 5 : 4;
    final int numClasses = numLabels;

    // ========= 4) Threshold / NMS =========
    const double iouThr = 0.50;
    const int topK = 20;
    const thresholds = <double>[0.45, 0.25, 0.15, 0.10, 0.05];

    // ========= 5) DEBUG =========
    double maxObj = -1;
    double maxCls = -1;
    double bestScore = -1;
    int bestClsId = -1;

    double minCx = double.infinity, maxCx = -double.infinity;
    double minCy = double.infinity, maxCy = -double.infinity;
    double minW = double.infinity, maxW = -double.infinity;
    double minH = double.infinity, maxH = -double.infinity;

    int normalizedLikeCount = 0;

    for (int i = 0; i < numBoxes; i++) {
      final cxRaw = out[0][i];
      final cyRaw = out[1][i];
      final wRaw = out[2][i];
      final hRaw = out[3][i];

      minCx = math.min(minCx, cxRaw);
      maxCx = math.max(maxCx, cxRaw);
      minCy = math.min(minCy, cyRaw);
      maxCy = math.max(maxCy, cyRaw);
      minW = math.min(minW, wRaw);
      maxW = math.max(maxW, wRaw);
      minH = math.min(minH, hRaw);
      maxH = math.max(maxH, hRaw);

      final bool looksNormalized =
          (cxRaw >= 0 && cxRaw <= 2.0) &&
          (cyRaw >= 0 && cyRaw <= 2.0) &&
          (wRaw >= 0 && wRaw <= 2.0) &&
          (hRaw >= 0 && hRaw <= 2.0);
      if (looksNormalized) normalizedLikeCount++;

      final obj = hasObj ? _toProb(out[4][i]) : 1.0;
      if (obj > maxObj) maxObj = obj;

      double localBestCls = -1;
      int localBestId = -1;
      for (int c = 0; c < numClasses; c++) {
        final s = _toProb(out[clsStart + c][i]);
        if (s > maxCls) maxCls = s;
        if (s > localBestCls) {
          localBestCls = s;
          localBestId = c;
        }
      }

      final score = obj * localBestCls;
      if (score > bestScore) {
        bestScore = score;
        bestClsId = localBestId;
      }
    }

    final bestLabel = (bestClsId >= 0 && bestClsId < labels.length)
        ? labels[bestClsId]
        : 'class_$bestClsId';

    debugPrint(
      '[YOLO DEBUG] orig=${origW}x$origH  cropSquare=${cropSize}x$cropSize  input=640x640  '
      'channels=$channels labels=$numLabels hasObj=$hasObj noObj=$noObj clsStart=$clsStart',
    );
    debugPrint(
      '[YOLO DEBUG] bboxRaw cx[$minCx..$maxCx] cy[$minCy..$maxCy] w[$minW..$maxW] h[$minH..$maxH] '
      'normalizedLike=${(normalizedLikeCount / numBoxes * 100).toStringAsFixed(1)}%',
    );
    debugPrint(
      '[YOLO DEBUG] maxObj=$maxObj maxCls=$maxCls bestScore=$bestScore best=$bestLabel',
    );

    // ========= 6) Decode + threshold fallback =========
    List<Detection> finalResult = const [];

    for (final confThr in thresholds) {
      final dets = <Detection>[];

      int passedScore = 0;
      int passedMinSize = 0;

      for (int i = 0; i < numBoxes; i++) {
        double cx = out[0][i];
        double cy = out[1][i];
        double w = out[2][i];
        double h = out[3][i];

        // normalize ise 640'a çevir
        final bool looksNormalized =
            (cx >= 0 && cx <= 2.0) &&
            (cy >= 0 && cy <= 2.0) &&
            (w >= 0 && w <= 2.0) &&
            (h >= 0 && h <= 2.0);
        if (looksNormalized) {
          cx *= 640.0;
          cy *= 640.0;
          w *= 640.0;
          h *= 640.0;
        }

        final obj = hasObj ? _toProb(out[4][i]) : 1.0;

        double bestClsScore = -1.0;
        int clsId = -1;
        for (int c = 0; c < numClasses; c++) {
          final s = _toProb(out[clsStart + c][i]);
          if (s > bestClsScore) {
            bestClsScore = s;
            clsId = c;
          }
        }

        final score = obj * bestClsScore;
        if (score < confThr || clsId < 0) continue;
        passedScore++;

        double left = cx - w / 2.0;
        double top = cy - h / 2.0;
        double right = cx + w / 2.0;
        double bottom = cy + h / 2.0;

        left = left.clamp(0.0, 640.0);
        top = top.clamp(0.0, 640.0);
        right = right.clamp(0.0, 640.0);
        bottom = bottom.clamp(0.0, 640.0);

        // min kutu boyutu (false-positive azaltır)
        if (right - left < 12 || bottom - top < 12) continue;
        passedMinSize++;

        final label = (clsId < labels.length) ? labels[clsId] : 'class_$clsId';

        dets.add(
          Detection(
            box: Rect.fromLTRB(left, top, right, bottom), // ✅ 640 uzayında
            label: label,
            confidence: score,
          ),
        );
      }

      final afterNms = _nmsPerClass(dets, iouThr);
      afterNms.sort((a, b) => b.confidence.compareTo(a.confidence));

      if (afterNms.isNotEmpty) {
        finalResult = (afterNms.length > topK)
            ? afterNms.take(topK).toList()
            : afterNms;

        debugPrint(
          '[YOLO DEBUG] confThr=$confThr candidates(scorePass=$passedScore,minSizePass=$passedMinSize) '
          'dets=${dets.length} afterNms=${afterNms.length} kept=${finalResult.length}',
        );
        break;
      } else {
        debugPrint(
          '[YOLO DEBUG] confThr=$confThr candidates(scorePass=$passedScore,minSizePass=$passedMinSize) '
          'dets=${dets.length} afterNms=0 kept=0',
        );
      }
    }

    return finalResult;
  }
}
