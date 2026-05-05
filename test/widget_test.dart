import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/core/settings/app_settings.dart';
import 'package:driver_app/features/driver_flow/data/mock_driver_flow_repository.dart';
import 'package:driver_app/features/driver_flow/driver_flow_controller.dart';
import 'package:driver_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('driver app boots into Settings when no API base is set', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final settings = await AppSettings.load();
    await tester.pumpWidget(TricyKabDriverApp(settings: settings));
    await tester.pump();
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('driver app boots into Login when API base is set but no token', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tricykab_api_base': 'http://10.0.2.2:8000/api/v1',
    });
    final settings = await AppSettings.load();
    await tester.pumpWidget(TricyKabDriverApp(settings: settings));
    await tester.pump();
    expect(find.text('TricyKab'), findsWidgets);
    expect(find.text('Sign in with your registered number'), findsOneWidget);
  });

  test('add passenger updates onboard count after pickup phase', () async {
    final DriverFlowController controller = DriverFlowController(repository: MockDriverFlowRepository());
    await controller.loadOffers();
    await controller.acceptOffer(controller.offers.firstWhere((o) => o.id == 'offer-1'));
    while (controller.offers.isNotEmpty) {
      await controller.declineCurrentOffer(controller.offers.first);
    }
    expect(controller.tripAnchorOffer, isNotNull);
    final int before = controller.onboardPassengers.length;
    await controller.addPassengers(1);
    expect(controller.onboardPassengers.length, before + 1);
  });
}
