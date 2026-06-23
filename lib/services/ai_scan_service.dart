import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class AiScanService {
  Interpreter? _interpreter;
  List<String>? _labels;
  Map<String, dynamic>? _explainData;
  bool _isModelLoaded = false;

  static const int _inputSize = 224;

  Future<void> loadModel() async {
    if (_isModelLoaded) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');

      final labelData = await rootBundle.loadString('assets/models/label.txt');
      _labels = labelData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      final jsonString =
          await rootBundle.loadString('assets/data/disease_knowledge.json');
      _explainData = jsonDecode(jsonString);

      _isModelLoaded = true;
      print('[AI SUCCESS] Model TFLite & Kamus Medis Berhasil Dimuat!');
    } catch (e) {
      print('Gagal menginisialisasi TFLite: $e');
    }
  }

  Future<Map<String, dynamic>?> predictImage(String imagePath) async {
    if (!_isModelLoaded) await loadModel();
    if (_interpreter == null || _labels == null) return null;

    try {
      final bytes = File(imagePath).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final resized =
          img.copyResize(decoded, width: _inputSize, height: _inputSize);

      // Build input tensor [1, 224, 224, 3] float32, normalized to [-1, 1]
      final input = List.generate(
        1,
        (_) => List.generate(
          _inputSize,
          (y) => List.generate(
            _inputSize,
            (x) {
              final pixel = resized.getPixel(x, y);
              return [
                (pixel.r.toDouble() - 127.5) / 127.5,
                (pixel.g.toDouble() - 127.5) / 127.5,
                (pixel.b.toDouble() - 127.5) / 127.5,
              ];
            },
          ),
        ),
      );

      final outputSize = _labels!.length;
      final output = [List<double>.filled(outputSize, 0)];

      _interpreter!.run(input, output);

      final scores = output[0];
      int bestIdx = 0;
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > scores[bestIdx]) bestIdx = i;
      }

      final confidence = scores[bestIdx];
      if (confidence < 0.1) {
        print('⚠️ Confidence terlalu rendah: $confidence');
        return null;
      }

      String rawLabel = _labels![bestIdx];
      String cleanLabel =
          rawLabel.replaceAll(RegExp(r'^[0-9]+\s'), '').trim();
      String jsonKey =
          cleanLabel.toLowerCase().replaceAll('_', ' ').trim();

      final detail = _explainData?[jsonKey];
      print('🎯 [AI MATCH] Label: $cleanLabel | Key: $jsonKey | Conf: $confidence');

      return {
        'diseaseName': cleanLabel,
        'confidence': confidence,
        'detailPenyakit': detail,
      };
    } catch (e) {
      print('❌ Inferensi gagal: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}
