import 'dart:convert'; // Tambahan untuk json.decode
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_v2/tflite_v2.dart';

class AiScanService {
  Map<String, dynamic>? _explainData;
  bool _isModelLoaded = false;

  // Fungsi memuat berkas model unquant dan kamus medis dari assets
  Future<void> loadModel() async {
    if (_isModelLoaded) return;
    try {
      // 1. Muat berkas model unquant tflite milik kelompokmu
      await Tflite.loadModel(
        model: "assets/models/model_unquant.tflite",
        labels: "assets/models/labels.txt",
      );

      // 2. Muat berkas kamus data medis penanganan bahasa Indonesia
      String jsonString = await rootBundle.loadString('assets/data/disease_knowledge.json');
      _explainData = jsonDecode(jsonString);
      _isModelLoaded = true;
      print(" [AI SUCCESS] Model TFLite v2 & Kamus Medis Berhasil Disinkronkan!");
    } catch (e) {
      print("Gagal menginisialisasi Tflite v2: $e");
    }
  }

  // Fungsi inferensi gambar otomatis lewat String path file tanpa olah array piksel manual
  Future<Map<String, dynamic>?> predictImage(String imagePath) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    try {
      // FIX UTAMA: Tambahkan parameter asynch: true untuk memintas masalah GPU Mali Samsung
      var output = await Tflite.runModelOnImage(
        path: imagePath,
        numResults: 1,
        threshold: 0.1,
        imageMean: 127.5, // Standard deviasi Teachable Machine unquant model
        imageStd: 127.5,
        asynch: true, // <── TAMBAHKAN BARIS INI (SANGAT KRUSIAL UNTUK HP SAMSUNG MALI GPU)
      );
      print("🤖 DEBUG: Output TFLite: $output"); // <── Tambahkan ini

      if (output != null && output.isNotEmpty) {
        String rawLabel = output[0]['label'];
        // Membersihkan angka indeks di depan label (misal "0 Tomato_Healthy" -> "Tomato_Healthy")
        String cleanLabel = rawLabel.replaceAll(RegExp(r'^[0-9]+\s'), '').trim();
        
        // Normalisasi key untuk dicocokkan ke key disease_knowledge.json
        String jsonKey = cleanLabel.toLowerCase().replaceAll('_', ' ').trim();
        var detail = _explainData?[jsonKey];

        print("🎯 [AI MATCH] Label TFLite: '$cleanLabel' | Ditranslasikan ke JSON Key: '$jsonKey'");

        return {
          'diseaseName': cleanLabel,
          'confidence': output[0]['confidence'] as double,
          'detailPenyakit': detail,
        };
      }
      print("⚠️ Tflite v2 mengembalikan output kosong/null.");
      return null;
    } catch (e) {
      print("❌ Terjadi kesalahan inferensi gambar pada native layer Tflite: $e");
      return null;
    }
  }

  void dispose() {
    Tflite.close();
  }
}