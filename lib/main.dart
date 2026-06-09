import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'pages/auth/login_page.dart';
import 'services/article_service.dart';
import 'services/plant_type_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  PlantTypeService().seedIfEmpty().catchError((_) {});
  ArticleService().seedIfEmpty().catchError((_) {});

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