import 'dart:convert'; // Tambahan untuk json.decode
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AiScanService {
  Interpreter? _interpreter;
  List<String>? _labels;

  // =============== INI FUNGSI YANG HILANG (DISEDIAKAN KEMBALI) ===============
  // Fungsi untuk memuat berkas model .tflite dan labels.txt dari folder assets
  Future<void> loadModel() async {
    try {
      // 1. Muat Interpreter TFLite secara lokal dari folder assets
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      
      // 2. Muat teks labels baris-per-baris dari file labels.txt
      final labelsString = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsString
          .split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();

      print("AI Scan Service: Model TFLite & ${_labels!.length} Label Berhasil Dimuat!");
    } catch (e) {
      print("AI Scan Service Gagal Memuat Model/Label: $e");
    }
  }

  // =============== FUNGSI MEMBACA DATABASE KAMUS PENYAKIT JSON ===============
  Future<Map<String, dynamic>?> getDiseaseDetails(String outputLabel) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/disease_knowledge.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      // Normalisasi teks agar pencarian key di JSON fleksibel (huruf kecil & spasi)
      String cleanKey = outputLabel.toLowerCase().replaceAll('_', ' ').trim();
      
      print("Mencari Kamus Medis JSON untuk Key: '$cleanKey'");

      if (data.containsKey(cleanKey)) {
        return data[cleanKey];
      } else {
        print("Detail untuk label '$cleanKey' tidak ditemukan di JSON.");
        return null;
      }
    } catch (e) {
      print("Gagal membaca database JSON lokal: $e");
      return null;
    }
  }

  // Memproses gambar dan mengembalikan hasil inferensi
  Future<Map<String, dynamic>?> predictImage(File imageFile) async {
    // PROTEKSI: Jika interpreter belum siap, otomatis coba muat model dulu di sini
    if (_interpreter == null || _labels == null) {
      print("Menyiapkan model TFLite secara otomatis sesaat sebelum inferensi...");
      await loadModel();
    }

    if (_interpreter == null || _labels == null) {
      print("AI Scan Service: Model tetap belum siap!");
      return null;
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      const int inputSize = 224;
      final resizedImage = img.copyResize(originalImage, width: inputSize, height: inputSize);

      // Inisialisasi input tensor Float32List datar [1, 224, 224, 3]
      var input = List.generate(
        1,
        (index) => List.generate(
          inputSize,
          (y) => List.generate(
            inputSize,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
          ),
        ),
      );

      // Gunakan output satu dimensi untuk inferensi model dengan satu hasil keluaran
      var output = List.generate(1, (_) => List<double>.filled(_labels!.length, 0.0));

      // Jalankan inferensi menggunakan metode run
      _interpreter!.run(input, output);

      List<double> results = output[0];
      double maxScore = -1.0;
      int maxIndex = -1;

      for (int i = 0; i < results.length; i++) {
        if (results[i] > maxScore) {
          maxScore = results[i];
          maxIndex = i;
        }
      }

      print("AI Scan Sukses! Terdeteksi Indeks: $maxIndex dengan Akurasi: $maxScore");

      return {
        'diseaseName': _labels![maxIndex],
        'confidence': maxScore,
      };
    } catch (e) {
      print("AI Scan Service Inferensi Error Asli: $e");
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}