import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_theme.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  runApp(const GuangyuApp());
}

class GuangyuApp extends StatelessWidget {
  const GuangyuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '光屿',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const AuthGate(),
    );
  }
}
