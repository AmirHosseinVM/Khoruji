import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const OneSpeedApp());
}

class OneSpeedApp extends StatelessWidget {
  const OneSpeedApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneSpeed',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('fa'),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const SplashScreen(),
    );
  }
}
