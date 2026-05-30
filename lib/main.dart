import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'pages/auth/login_page.dart'; // 1. Pastikan import ke LoginPage buatanmu

void main() async { // 2. Tambahkan kata kunci 'async' di sini
  WidgetsFlutterBinding.ensureInitialized();
  
  // 3. Inisialisasi Firebase sebelum runApp dijalankan
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
      theme: AppTheme.lightTheme, // Tetap menggunakan tema lightTheme bawaanmu
      home: const LoginPage(), // 4. Ubah dari MainNavigation() ke LoginPage()
    );
  }
}