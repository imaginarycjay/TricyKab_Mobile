import 'package:driver_app/data/mock_data.dart';
import 'package:driver_app/features/driver_flow/data/mock_driver_flow_repository.dart';
import 'package:driver_app/features/driver_flow/driver_flow_controller.dart';
import 'package:driver_app/features/driver_flow/driver_flow_scope.dart';
import 'package:driver_app/navigation/driver_offer_auto_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('auto-presenter navigates to offer screen when idle offer deck appears', (tester) async {
    final controller = DriverFlowController(repository: MockDriverFlowRepository());
    final navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      DriverFlowScope(
        controller: controller,
        child: DriverOfferAutoPresenter(
          navigatorKey: navKey,
          child: MaterialApp(
            navigatorKey: navKey,
            routes: <String, WidgetBuilder>{
              '/': (_) => const Scaffold(body: Text('HOME')),
            },
          ),
        ),
      ),
    );

    expect(find.text('HOME'), findsOneWidget);
    controller.offers = MockIncomingOffers.fullBatch;
    controller.notifyListeners();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(navKey.currentState?.canPop(), isTrue);
  });

  testWidgets('auto-presenter does not navigate when offer surface is suppressed', (tester) async {
    final controller = DriverFlowController(repository: MockDriverFlowRepository());
    final navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      DriverFlowScope(
        controller: controller,
        child: DriverOfferAutoPresenter(
          navigatorKey: navKey,
          child: MaterialApp(
            navigatorKey: navKey,
            routes: <String, WidgetBuilder>{
              '/': (_) => const Scaffold(body: Text('HOME')),
            },
          ),
        ),
      ),
    );

    controller.offerSurfaceSuppressed = true;
    controller.offers = MockIncomingOffers.fullBatch;
    controller.notifyListeners();
    await tester.pump();
    await tester.pump();

    expect(find.text('HOME'), findsOneWidget);
    expect(navKey.currentState?.canPop(), isFalse);
  });
}

