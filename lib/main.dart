import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/core/theme/app_theme.dart';
import 'package:bluetooth_rc_car/firebase_options.dart';
import 'package:bluetooth_rc_car/presentation/screens/app_shell.dart';
import 'package:bluetooth_rc_car/presentation/screens/app_splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: RcCarApp()));
}

class RcCarApp extends StatelessWidget {
  const RcCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,
      theme: AppTheme.darkTheme,
      home: const AppSplashScreen(child: AppShell()),
    );
  }
}
