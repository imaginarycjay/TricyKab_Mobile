import '../../../data/mock_data.dart';
import '../domain/driver_flow_models.dart';
import 'driver_flow_repository.dart';

class MockDriverFlowRepository implements DriverFlowRepository {
  @override
  bool get supportsPolling => false;

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
  Future<bool> updateAvailability(bool online, {double? latitude, double? longitude}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return online;
  }

  @override
  Future<DriverOffer> acceptAssignment(DriverOffer offer) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return offer;
  }

  @override
  Future<void> declineOffer(DriverOffer offer, {String reasonCode = 'NOT_AVAILABLE'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<DriverBookingCancelResult> cancelBooking(int bookingId, {required String reasonCode, String? notes}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return DriverBookingCancelResult(
      bookingId: bookingId,
      status: 'CANCELLED_BY_DRIVER',
      cancelledAtIso: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> markArrived({
    required int tripId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<void> startTrip({
    required int tripId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<DriverTripSummary> endTrip({
    required int tripId,
    required int bookingId,
    required String bookingReference,
    required int passengerCount,
    required double endLatitude,
    required double endLongitude,
    String? fareAmount,
    double? accuracy,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return DriverTripSummary(
      bookingReference: bookingReference,
      receiptNumber: MockEndTrip.receipt,
      finalFare: fareAmount == null ? MockEndTrip.finalFare : 'PHP $fareAmount',
      distance: MockEndTrip.distance,
      duration: MockEndTrip.duration,
      startTime: MockTrip.startedAt,
      endTime: MockTrip.endedAt,
      passengerName: 'Maria Clara',
      routeLabel: MockEndTrip.routeShort,
      passengerCount: passengerCount,
      collectSubtitle: 'Collect cash payment from passenger',
    );
  }

  @override
  Future<void> sendDriverLocation({
    required int tripId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
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
            bookingId: o.bookingId,
            tripId: o.tripId,
            candidateId: o.candidateId,
            dispatchAttemptId: o.dispatchAttemptId,
            pickupLatitude: o.pickupLatitude,
            pickupLongitude: o.pickupLongitude,
            destinationLatitude: o.destinationLatitude,
            destinationLongitude: o.destinationLongitude,
            estimatedFareAmount: o.estimatedFareAmount,
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
  Future<List<DriverHistoryBooking>> myBookings({bool active = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final List<DriverHistoryBooking> rows = <DriverHistoryBooking>[];
    var id = 9000;
    for (final t in MockTripHistory.trips) {
      id++;
      final type = (t['type'] ?? 'SHARED').toUpperCase();
      rows.add(DriverHistoryBooking(
        id: id,
        reference: t['ref'] ?? 'BK-$id',
        status: t['status'] ?? 'COMPLETED',
        rideType: type == 'SPECIAL' ? RideType.special : RideType.shared,
        pickupAddress: t['from'] ?? '',
        destinationAddress: t['to'] ?? '',
        passengerName: 'Mock Passenger',
        passengerInitials: 'MP',
        fareAmount: (t['fare'] ?? '').replaceAll(RegExp(r'[^0-9.]'), ''),
        estimatedDistanceMeters: 3200,
        estimatedDurationSeconds: 13 * 60,
        createdAtIso: DateTime.now().toUtc().toIso8601String(),
      ));
    }
    if (active) {
      return rows.where((r) => r.isActive).toList();
    }
    return rows;
  }

  @override
  Future<DriverHistoryBooking?> bookingDetail(int bookingId) async {
    final all = await myBookings();
    for (final r in all) {
      if (r.id == bookingId) return r;
    }
    return null;
  }
}
