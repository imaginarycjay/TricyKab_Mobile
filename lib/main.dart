import 'package:flutter/material.dart';

import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/driver_flow/data/driver_flow_repository.dart';
import 'features/driver_flow/data/http_driver_flow_repository.dart';
import 'features/driver_flow/driver_flow_controller.dart';
import 'features/driver_flow/driver_flow_scope.dart';
import 'navigation/app_router.dart';
import 'navigation/driver_offer_auto_presenter.dart';

/// Fixed API base for the pilot tunnel.
const String kApiBase = 'https://satisfactory-flo-inarguably.ngrok-free.dev/api/v1';

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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _controller = DriverFlowController(repository: _buildRepository());
  }

  DriverFlowRepository _buildRepository() {
    return HttpDriverFlowRepository(
      baseUrl: kApiBase,
      initialAccessToken: widget.settings.accessToken,
      onTokensChanged: (access, refresh) async {
        await widget.settings.setAccessToken(access);
        await widget.settings.setRefreshToken(refresh);
      },
    );
  }

  /// Cold-start landing rule (mirrors the passenger app):
  ///  - no token  -> OTP login
  ///  - token set -> Home
  String _initialRoute() {
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
      child: DriverOfferAutoPresenter(
        navigatorKey: _navigatorKey,
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'TricyKab Driver',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: _initialRoute(),
          routes: {
            ...AppRouter.routes,
          },
        ),
      ),
    );
  }
}
