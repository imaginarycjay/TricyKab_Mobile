import 'package:flutter/material.dart';

import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/driver_flow/data/driver_flow_repository.dart';
import 'features/driver_flow/data/http_driver_flow_repository.dart';
import 'features/driver_flow/data/mock_driver_flow_repository.dart';
import 'features/driver_flow/driver_flow_controller.dart';
import 'features/driver_flow/driver_flow_scope.dart';
import 'features/settings/screens/settings_screen.dart';
import 'navigation/app_router.dart';

/// Compile-time fallback when the user hasn't configured settings yet.
const String kBuildTimeApiBase = String.fromEnvironment('TRICYKAB_API_BASE', defaultValue: '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(TricyKabDriverApp(settings: settings));
}

class TricyKabDriverApp extends StatefulWidget {
  const TricyKabDriverApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<TricyKabDriverApp> createState() => _TricyKabDriverAppState();
}

class _TricyKabDriverAppState extends State<TricyKabDriverApp> {
  late DriverFlowController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DriverFlowController(repository: _buildRepository());
  }

  DriverFlowRepository _buildRepository() {
    final base = widget.settings.apiBase.isNotEmpty
        ? widget.settings.apiBase
        : kBuildTimeApiBase;
    if (base.isEmpty) {
      return MockDriverFlowRepository();
    }
    return HttpDriverFlowRepository(
      baseUrl: base,
      initialAccessToken: widget.settings.accessToken,
      onTokensChanged: (access, refresh) async {
        await widget.settings.setAccessToken(access);
        await widget.settings.setRefreshToken(refresh);
      },
    );
  }

  void _onSettingsChanged() {
    setState(() {
      _controller.replaceRepository(_buildRepository());
    });
  }

  /// Cold-start landing rule (mirrors the passenger app):
  ///  - no API base configured  -> Settings (operator must point app at backend)
  ///  - API base set, no token  -> OTP login
  ///  - API base set, token set -> Home
  String _initialRoute() {
    final base = widget.settings.apiBase.isNotEmpty
        ? widget.settings.apiBase
        : kBuildTimeApiBase;
    if (base.isEmpty) return '/settings';
    final token = widget.settings.accessToken;
    if (token == null || token.isEmpty) return AppRouter.login;
    return AppRouter.home;
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
        initialRoute: _initialRoute(),
        routes: {
          ...AppRouter.routes,
          '/settings': (_) => SettingsScreen(
                settings: widget.settings,
                onSaved: _onSettingsChanged,
              ),
        },
      ),
    );
  }
}
