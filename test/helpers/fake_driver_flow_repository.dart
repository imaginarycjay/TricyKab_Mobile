import 'package:driver_app/features/driver_flow/data/driver_flow_repository.dart';
import 'package:driver_app/features/driver_flow/data/mock_driver_flow_repository.dart';
import 'package:driver_app/features/driver_flow/domain/driver_flow_models.dart';

/// Test double that records every mutation call so phase-transition and
/// decline/cancel tests can assert ordering + uniqueness invariants.
///
/// Forward-only: most read methods delegate to [MockDriverFlowRepository] so
/// existing widget-test fixtures still compose passenger lists, history rows,
/// etc.
class FakeDriverFlowRepository implements DriverFlowRepository {
  FakeDriverFlowRepository();

  final MockDriverFlowRepository _mock = MockDriverFlowRepository();
  final List<String> calls = <String>[];

  /// Tracks all idempotency keys ever observed on outgoing mutations.  We
  /// pull from the `Idempotency-Key` header by mocking the helper at call
  /// time below — controllers do not send headers directly, so we record a
  /// synthetic key per call.
  final List<String> idempotencyKeys = <String>[];

  @override
  bool get supportsPolling => false;

  String _nextKey(String prefix) {
    final k = '$prefix-${calls.length}-${DateTime.now().microsecondsSinceEpoch}';
    idempotencyKeys.add(k);
    return k;
  }

  @override
  Future<void> requestOtp(String phoneNumber) => _mock.requestOtp(phoneNumber);

  @override
  Future<bool> verifyOtp(String phoneNumber, String otpCode) => _mock.verifyOtp(phoneNumber, otpCode);

  @override
  Future<bool> updateAvailability(bool online, {double? latitude, double? longitude}) async {
    calls.add('availability:$online');
    return online;
  }

  @override
  Future<DriverOffer> acceptAssignment(DriverOffer offer) async {
    _nextKey('accept-${offer.bookingId}');
    calls.add('accept:${offer.id}');
    return offer.copyWith(tripId: 555);
  }

  @override
  Future<void> declineOffer(DriverOffer offer, {String reasonCode = 'NOT_AVAILABLE'}) async {
    calls.add('decline:${offer.id}:$reasonCode');
  }

  @override
  Future<DriverBookingCancelResult> cancelBooking(int bookingId, {required String reasonCode, String? notes}) async {
    _nextKey('cancel-$bookingId');
    calls.add('cancel:$bookingId:$reasonCode');
    return DriverBookingCancelResult(bookingId: bookingId, status: 'CANCELLED_BY_DRIVER');
  }

  @override
  Future<void> markArrived({
    required int tripId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    _nextKey('arrive-$tripId');
    calls.add('arrive:$tripId');
  }

  @override
  Future<void> startTrip({
    required int tripId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    _nextKey('start-$tripId');
    calls.add('start:$tripId');
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
    _nextKey('end-$tripId');
    _nextKey('payment-$bookingId');
    calls.add('end:$tripId');
    calls.add('payment:$bookingId');
    return DriverTripSummary(
      bookingReference: bookingReference,
      receiptNumber: 'RCT-TEST-0001',
      finalFare: 'PHP ${fareAmount ?? '0.00'}',
      distance: '—',
      duration: '—',
      startTime: DateTime.now().toIso8601String(),
      endTime: DateTime.now().toIso8601String(),
      passengerName: 'Tester',
      routeLabel: 'A → B',
      passengerCount: passengerCount,
    );
  }

  @override
  Future<void> sendDriverLocation({
    required int tripId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    calls.add('ping:$tripId');
  }

  @override
  Future<List<DriverOffer>> fetchIncomingOffers({bool midAssignment = false}) =>
      _mock.fetchIncomingOffers(midAssignment: midAssignment);

  @override
  Future<PickupLayout> buildPickupFromAccepted(List<DriverOffer> accepted) =>
      _mock.buildPickupFromAccepted(accepted);

  @override
  Future<int> addWalkInPassengers({
    required int existingPassengerCount,
    required int quantity,
    required int capacity,
  }) =>
      _mock.addWalkInPassengers(
        existingPassengerCount: existingPassengerCount,
        quantity: quantity,
        capacity: capacity,
      );

  @override
  Future<List<DriverHistoryBooking>> myBookings({bool active = false}) async {
    calls.add('myBookings:$active');
    return _mock.myBookings(active: active);
  }

  @override
  Future<DriverHistoryBooking?> bookingDetail(int bookingId) async {
    calls.add('bookingDetail:$bookingId');
    return _mock.bookingDetail(bookingId);
  }
}
