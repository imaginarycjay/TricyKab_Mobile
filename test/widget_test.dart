import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/features/driver_flow/data/mock_driver_flow_repository.dart';
import 'package:driver_app/features/driver_flow/driver_flow_controller.dart';
import 'package:driver_app/main.dart';

void main() {
  testWidgets('driver flow navigates from login to home', (WidgetTester tester) async {
    await tester.pumpWidget(const TricyKabDriverApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign in with your registered number'), findsOneWidget);

    await tester.tap(find.text('Sign In as Driver'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Verify & Sign In'), findsOneWidget);

    await tester.tap(find.text('Verify & Sign In'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Today\'s Performance'), findsOneWidget);
  });

  test('add passenger updates onboard count after pickup phase', () async {
    final DriverFlowController controller = DriverFlowController(repository: MockDriverFlowRepository());
    await controller.loadOffers();
    await controller.acceptOffer(controller.offers.firstWhere((o) => o.id == 'offer-1'));
    while (controller.offers.isNotEmpty) {
      await controller.declineOffer(controller.offers.first);
    }
    expect(controller.tripAnchorOffer, isNotNull);
    final int before = controller.onboardPassengers.length;
    await controller.addPassengers(1);
    expect(controller.onboardPassengers.length, before + 1);
  });
}
