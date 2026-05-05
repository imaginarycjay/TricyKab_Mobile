import 'package:driver_app/data/mock_data.dart';
import 'package:driver_app/features/driver_flow/data/mock_driver_flow_repository.dart';
import 'package:driver_app/features/driver_flow/driver_flow_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declining all offers leaves empty accepted list and no pickup anchor', () async {
    final DriverFlowController controller = DriverFlowController(
      repository: MockDriverFlowRepository(),
    );
    await controller.loadOffers();
    final int n = controller.offers.length;
    expect(n, 3);
    for (int i = 0; i < n; i++) {
      await controller.declineCurrentOffer(controller.offers.first);
    }
    expect(controller.offers, isEmpty);
    expect(controller.acceptedOffers, isEmpty);
    expect(controller.tripAnchorOffer, isNull);
    expect(controller.phase, DriverPhase.waitingOffers);
  });

  test('accepting an offer transitions to assigned phase and builds pickup layout', () async {
    final DriverFlowController controller = DriverFlowController(
      repository: MockDriverFlowRepository(),
    );
    await controller.loadOffers();
    await controller.acceptOffer(controller.offers.firstWhere((o) => o.id == 'offer-1'));
    expect(controller.tripAnchorOffer, isNotNull);
    expect(controller.acceptedOffers.length, 1);
    expect(controller.waitingPassengers.length, greaterThanOrEqualTo(1));
    expect(controller.phase, DriverPhase.assigned);
  });

  test('special offer cannot queue after shared accept', () async {
    final DriverFlowController controller = DriverFlowController(
      repository: MockDriverFlowRepository(),
    );
    await controller.loadOffers();
    await controller.acceptOffer(controller.offers.firstWhere((o) => o.id == 'offer-1'));
    final String? err = controller.validateAccept(MockIncomingOffers.andresOffer);
    expect(err, isNotNull);
  });
}
