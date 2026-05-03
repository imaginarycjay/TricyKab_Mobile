import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/driver_flow/data/mock_driver_flow_repository.dart';
import 'features/driver_flow/driver_flow_controller.dart';
import 'features/driver_flow/driver_flow_scope.dart';
import 'navigation/app_router.dart';

void main() {
  runApp(const TricyKabDriverApp());
}

/// TricyKab Driver App — Smart Tricycle Dispatch System
/// Kabacan, North Cotabato
class TricyKabDriverApp extends StatefulWidget {
  const TricyKabDriverApp({super.key});

  @override
  State<TricyKabDriverApp> createState() => _TricyKabDriverAppState();
}

class _TricyKabDriverAppState extends State<TricyKabDriverApp> {
  late final DriverFlowController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DriverFlowController(repository: MockDriverFlowRepository());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DriverFlowScope(
      controller: _controller,
      child: MaterialApp(
        title: 'TricyKab Driver',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRouter.login,
        routes: AppRouter.routes,
      ),
    );
  }
}
