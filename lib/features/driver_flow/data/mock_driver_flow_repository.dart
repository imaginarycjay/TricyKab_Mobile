import '../../../data/mock_data.dart';
import '../domain/driver_flow_models.dart';
import 'driver_flow_repository.dart';

class MockDriverFlowRepository implements DriverFlowRepository {
  @override
  Future<void> requestOtp(String phoneNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<bool> verifyOtp(String phoneNumber, String otpCode) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return otpCode == '123456';
  }

  @override
  Future<bool> updateAvailability(bool online) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return online;
  }

  @override
  Future<List<DriverOffer>> fetchIncomingOffers({bool midAssignment = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (midAssignment) {
      return <DriverOffer>[MockIncomingOffers.midAssignmentOffer];
    }
    return MockIncomingOffers.fullBatch
        .map(
          (DriverOffer o) => DriverOffer(
            id: o.id,
            reference: o.reference,
            rideType: o.rideType,
            passengerName: o.passengerName,
            passengerInitials: o.passengerInitials,
            pickupAddress: o.pickupAddress,
            destinationAddress: o.destinationAddress,
            pickupDistanceLabel: o.pickupDistanceLabel,
            estimatedFare: o.estimatedFare,
            estimatedDistance: o.estimatedDistance,
            estimatedDuration: o.estimatedDuration,
            countdownSeconds: o.countdownSeconds,
          ),
        )
        .toList();
  }

  @override
  Future<PickupLayout> buildPickupFromAccepted(List<DriverOffer> accepted) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (accepted.isEmpty) {
      return PickupLayout(waiting: <TripPassenger>[], onboard: <TripPassenger>[]);
    }

    final List<TripPassenger> waiting = <TripPassenger>[];
    for (final DriverOffer o in accepted) {
      waiting.add(
        TripPassenger(
          id: 'wait-${o.id}',
          name: o.passengerName,
          initials: o.passengerInitials,
          pickupAddress: o.pickupAddress,
          dropoffAddress: o.destinationAddress,
          rideType: o.rideType,
          fareDisplay: o.estimatedFare.replaceFirst('₱', 'PHP '),
          pickupNotes: 'Tap card to view booking details',
        ),
      );
    }

    final bool matchDemo = accepted.length == 2 &&
        accepted.any((DriverOffer o) => o.id == MockIncomingOffers.mariaOffer.id) &&
        accepted.any((DriverOffer o) => o.id == MockIncomingOffers.joseOffer.id);

    if (matchDemo) {
      return PickupLayout(
        waiting: <TripPassenger>[MockAssignedPickup.joseWaiting, MockAssignedPickup.mariaWaiting],
        onboard: <TripPassenger>[MockAssignedPickup.mariaOnboard],
        defaultSelectedWaitingId: MockAssignedPickup.mariaWaiting.id,
      );
    }

    return PickupLayout(
      waiting: waiting,
      onboard: <TripPassenger>[],
      defaultSelectedWaitingId: waiting.isNotEmpty ? waiting.first.id : null,
    );
  }

  @override
  Future<int> addWalkInPassengers({
    required int existingPassengerCount,
    required int quantity,
    required int capacity,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final int nextCount = existingPassengerCount + quantity;
    if (nextCount > capacity) {
      throw StateError('Passenger capacity exceeded.');
    }
    return nextCount;
  }

  @override
  Future<DriverTripSummary> completeTrip({
    required String bookingReference,
    required int passengerCount,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return DriverTripSummary(
      bookingReference: MockEndTrip.bookingRef,
      receiptNumber: MockEndTrip.receipt,
      finalFare: MockEndTrip.finalFare,
      distance: MockEndTrip.distance,
      duration: MockEndTrip.duration,
      startTime: MockTrip.startedAt,
      endTime: MockTrip.endedAt,
      passengerName: 'Maria Clara',
      routeLabel: MockEndTrip.routeShort,
      passengerCount: MockEndTrip.passengerCount,
      collectSubtitle: 'Collect cash payment from passenger',
    );
  }
}
