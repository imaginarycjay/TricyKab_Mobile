import 'package:driver_app/features/driver_flow/domain/driver_flow_models.dart';
import 'package:driver_app/features/driver_flow/driver_flow_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_driver_flow_repository.dart';

DriverOffer _liveOffer() => DriverOffer(
      id: 'live-1',
      reference: 'BK-TEST-0002',
      rideType: RideType.shared,
      passengerName: 'Test Passenger',
      passengerInitials: 'TP',
      pickupAddress: 'Origin',
      destinationAddress: 'Destination',
      pickupDistanceLabel: '1 km',
      estimatedFare: 'PHP 35',
      estimatedDistance: '3 km',
      estimatedDuration: '~12 min',
      countdownSeconds: 20,
      bookingId: 99,
      candidateId: 7,
      dispatchAttemptId: 7,
    );

void main() {
  test('declineCurrentOffer fires POST /decline with the chosen reason code', () async {
    final fake = FakeDriverFlowRepository();
    final controller = DriverFlowController(repository: fake);
    await controller.loadOffers();
    final offer = controller.offers.first;
    await controller.declineCurrentOffer(offer, reasonCode: 'NOT_AVAILABLE');

    final declines = fake.calls.where((c) => c.startsWith('decline:')).toList();
    expect(declines, hasLength(1));
    expect(declines.first, 'decline:${offer.id}:NOT_AVAILABLE');
    expect(controller.offers.any((o) => o.id == offer.id), isFalse);
  });

  test('cancelAssignment fires POST /cancel with reason and clears trip state', () async {
    final fake = FakeDriverFlowRepository();
    final controller = DriverFlowController(repository: fake);
    await controller.acceptOffer(_liveOffer());
    expect(controller.phase, DriverPhase.assigned);

    await controller.cancelAssignment(reasonCode: 'PASSENGER_NO_SHOW', notes: 'Waited 10 min');

    final cancels = fake.calls.where((c) => c.startsWith('cancel:')).toList();
    expect(cancels, hasLength(1));
    expect(cancels.first, 'cancel:99:PASSENGER_NO_SHOW');

    expect(controller.tripAnchorOffer, isNull);
    expect(controller.phase, DriverPhase.waitingOffers);
  });
}
