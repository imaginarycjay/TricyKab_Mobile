import '../domain/driver_flow_models.dart';

abstract class DriverFlowRepository {
  Future<void> requestOtp(String phoneNumber);

  Future<bool> verifyOtp(String phoneNumber, String otpCode);

  Future<bool> updateAvailability(bool online);

  /// Main offer batch, or a single offer when [midAssignment] (from assigned pickup).
  Future<List<DriverOffer>> fetchIncomingOffers({bool midAssignment = false});

  /// Build waiting/onboard lists after the offer batch completes (may use [accepted] data).
  Future<PickupLayout> buildPickupFromAccepted(List<DriverOffer> accepted);

  Future<int> addWalkInPassengers({
    required int existingPassengerCount,
    required int quantity,
    required int capacity,
  });

  Future<DriverTripSummary> completeTrip({
    required String bookingReference,
    required int passengerCount,
  });
}
