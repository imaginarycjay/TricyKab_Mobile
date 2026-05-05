import 'package:driver_app/features/driver_flow/domain/driver_flow_models.dart';
import 'package:driver_app/features/driver_flow/driver_flow_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_driver_flow_repository.dart';

DriverOffer _liveOffer() => DriverOffer(
      id: 'live-1',
      reference: 'BK-TEST-0001',
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
      bookingId: 42,
      candidateId: 1,
      dispatchAttemptId: 1,
      pickupLatitude: 7.114,
      pickupLongitude: 124.836,
      destinationLatitude: 7.130,
      destinationLongitude: 124.844,
      estimatedFareAmount: '35.00',
    );

void main() {
  test('On the way → Mark Arrived → Start Trip → End Trip fires the right repo calls in order', () async {
    final fake = FakeDriverFlowRepository();
    final controller = DriverFlowController(repository: fake);

    await controller.acceptOffer(_liveOffer());
    expect(controller.phase, DriverPhase.assigned);

    controller.markOnTheWay();
    expect(controller.phase, DriverPhase.onTheWay);

    await controller.markArrived();
    expect(controller.phase, DriverPhase.arrived);

    await controller.startTrip();
    expect(controller.phase, DriverPhase.inProgress);

    await controller.endTrip();
    expect(controller.phase, DriverPhase.completed);

    final mutations = fake.calls
        .where((c) => c.startsWith('accept:') ||
            c.startsWith('arrive:') ||
            c.startsWith('start:') ||
            c.startsWith('end:') ||
            c.startsWith('payment:'))
        .toList();

    expect(mutations.first, startsWith('accept:'));
    expect(
      mutations,
      containsAllInOrder([
        'arrive:555',
        'start:555',
        'end:555',
        'payment:42',
      ]),
    );
  });

  test('every mutation generates a unique idempotency key', () async {
    final fake = FakeDriverFlowRepository();
    final controller = DriverFlowController(repository: fake);

    await controller.acceptOffer(_liveOffer());
    controller.markOnTheWay();
    await controller.markArrived();
    await controller.startTrip();
    await controller.endTrip();

    expect(fake.idempotencyKeys.length, 5);
    expect(fake.idempotencyKeys.toSet().length, fake.idempotencyKeys.length);
    for (final key in fake.idempotencyKeys) {
      expect(key, isNotEmpty);
    }
  });

  test('phases are gated — calling actions out of order is a no-op', () async {
    final fake = FakeDriverFlowRepository();
    final controller = DriverFlowController(repository: fake);

    await controller.markArrived();
    expect(controller.phase, DriverPhase.waitingOffers);
    expect(fake.calls.where((c) => c.startsWith('arrive:')).length, 0);

    await controller.startTrip();
    expect(controller.phase, DriverPhase.waitingOffers);
    expect(fake.calls.where((c) => c.startsWith('start:')).length, 0);
  });
}
