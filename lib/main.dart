import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';

void main() {
  runApp(const TricyKabDriverApp());
}

/// TricyKab Driver App — Smart Tricycle Dispatch System
/// Kabacan, North Cotabato
class TricyKabDriverApp extends StatelessWidget {
  const TricyKabDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TricyKab Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.login,
      routes: AppRouter.routes,
    );
  }
}
