import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'pages/auth/login_page.dart'; 
import 'package:camera/camera.dart'; // Import paket kamera

// PENTING: Deklarasikan variabel global cameras di atas fungsi main agar bisa di-share ke AI Scanner page
List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Ambil daftar hardware lensa kamera fisik yang tersedia di HP Samsung kamu
  try {
    cameras = await availableCameras();
    print("📸 Kamera Fisik Berhasil Didaftarkan: ${cameras.length} lensa ditemukan.");
  } catch (e) {
    print("⚠️ Gagal mendeteksi sensor kamera fisik: $e");
  }
  
  // 2. Inisialisasi Firebase sebelum runApp dijalankan
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const UrbanLeafApp());
}

class UrbanLeafApp extends StatelessWidget {
  const UrbanLeafApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UrbanLeaf AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, 
      home: const LoginPage(), 
    );
  }
}