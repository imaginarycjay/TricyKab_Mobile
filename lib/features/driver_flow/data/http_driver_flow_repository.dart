import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/idempotency/idempotency.dart';
import '../domain/driver_flow_models.dart';
import 'driver_flow_repository.dart';

/// Live Laravel `/api/v1` wiring. Set `TRICYKAB_API_BASE=http://10.0.2.2/api/v1` (Android emulator).
typedef PersistTokenCallback = Future<void> Function(String? accessToken, String? refreshToken);

class HttpDriverFlowRepository implements DriverFlowRepository {
  HttpDriverFlowRepository({
    required this.baseUrl,
    String? initialAccessToken,
    PersistTokenCallback? onTokensChanged,
  })  : _accessToken = initialAccessToken,
        _onTokensChanged = onTokensChanged;

  final String baseUrl;
  String? _accessToken;
  String? _refreshToken;
  DriverOffer? _tripContext;
  final PersistTokenCallback? _onTokensChanged;

  String? get accessToken => _accessToken;
  DriverOffer? get tripContext => _tripContext;

  @override
  bool get supportsPolling => true;

  Uri _u(String path) {
    final root = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$root$p');
  }

  Map<String, String> _headers({bool jsonBody = false, String? idempotencyKey}) {
    final h = <String, String>{
      'Accept': 'application/json',
    };
    if (jsonBody) {
      h['Content-Type'] = 'application/json';
    }
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_accessToken';
    }
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      h['Idempotency-Key'] = idempotencyKey;
    }
    return h;
  }

  Future<Map<String, dynamic>> _decode(http.Response r) async {
    final body = r.body.isEmpty ? '{}' : r.body;
    final map = jsonDecode(body);
    if (map is Map<String, dynamic>) {
      return map;
    }
    return <String, dynamic>{};
  }

  RideType _parseRideType(String raw) {
    final u = raw.toUpperCase();
    if (u == 'SPECIAL') {
      return RideType.special;
    }
    return RideType.shared;
  }

  DriverOffer _offerFromApi(Map<String, dynamic> o) {
    final booking = (o['booking'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final display = (o['display'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final passenger = (booking['passenger'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final pickup = (booking['pickup'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final destination = (booking['destination'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    final fareRaw = booking['estimated_fare'];
    final fareStr = fareRaw == null ? 'PHP 0.00' : 'PHP $fareRaw';

    return DriverOffer(
      id: '${o['candidate_id']}',
      reference: '${booking['reference'] ?? ''}',
      rideType: _parseRideType('${booking['ride_type'] ?? 'SHARED'}'),
      passengerName: '${passenger['display_name'] ?? 'Passenger'}',
      passengerInitials: '${passenger['initials'] ?? '?'}',
      pickupAddress: '${pickup['address'] ?? ''}',
      destinationAddress: '${destination['address'] ?? ''}',
      pickupDistanceLabel: '${display['pickup_distance'] ?? ''}',
      estimatedFare: fareStr,
      estimatedDistance: '${display['estimated_distance'] ?? ''}',
      estimatedDuration: '${display['estimated_duration'] ?? ''}',
      countdownSeconds: (o['countdown_seconds'] as num?)?.toInt() ?? 0,
      bookingId: (booking['id'] as num?)?.toInt(),
      candidateId: (o['candidate_id'] as num?)?.toInt(),
      dispatchAttemptId: (o['dispatch_attempt_id'] as num?)?.toInt(),
      pickupLatitude: (pickup['latitude'] as num?)?.toDouble(),
      pickupLongitude: (pickup['longitude'] as num?)?.toDouble(),
      destinationLatitude: (destination['latitude'] as num?)?.toDouble(),
      destinationLongitude: (destination['longitude'] as num?)?.toDouble(),
      estimatedFareAmount: fareRaw == null ? null : '$fareRaw',
    );
  }

  DriverHistoryBooking _historyFromApi(Map<String, dynamic> b) {
    final passenger = (b['passenger'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final pickup = (b['pickup'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final destination = (b['destination'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    return DriverHistoryBooking(
      id: (b['id'] as num).toInt(),
      reference: '${b['reference'] ?? ''}',
      status: '${b['status'] ?? ''}',
      rideType: _parseRideType('${b['ride_type'] ?? 'SHARED'}'),
      pickupAddress: '${pickup['address'] ?? ''}',
      destinationAddress: '${destination['address'] ?? ''}',
      passengerName: passenger['display_name'] as String?,
      passengerInitials: passenger['initials'] as String?,
      fareAmount: b['estimated_fare'] as String?,
      estimatedDistanceMeters: (b['estimated_distance_meters'] as num?)?.toInt(),
      estimatedDurationSeconds: (b['estimated_duration_seconds'] as num?)?.toInt(),
      createdAtIso: b['created_at'] as String?,
      acceptedAtIso: b['accepted_at'] as String?,
      cancelledAtIso: b['cancelled_at'] as String?,
      pickupLat: (pickup['latitude'] as num?)?.toDouble(),
      pickupLng: (pickup['longitude'] as num?)?.toDouble(),
      destinationLat: (destination['latitude'] as num?)?.toDouble(),
      destinationLng: (destination['longitude'] as num?)?.toDouble(),
    );
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {
    final r = await http.post(
      _u('/auth/otp/request'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({
        'phone_number': phoneNumber,
        'role_hint': 'DRIVER',
      }),
    );
    final map = await _decode(r);
    if (r.statusCode >= 400 || map['success'] != true) {
      final err = map['error'];
      final msg = err is Map<String, dynamic> ? err['message'] : null;
      throw StateError(msg is String && msg.isNotEmpty ? msg : 'OTP request failed (${r.statusCode})');
    }
  }

  @override
  Future<bool> verifyOtp(String phoneNumber, String otpCode) async {
    final r = await http.post(
      _u('/auth/otp/verify'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({
        'phone_number': phoneNumber,
        'otp_code': otpCode,
      }),
    );
    final map = await _decode(r);
    if (r.statusCode >= 400 || map['success'] != true) {
      final err = map['error'];
      final msg = err is Map<String, dynamic> ? err['message'] : null;
      throw StateError(msg is String && msg.isNotEmpty ? msg : 'OTP verification failed (${r.statusCode})');
    }
    final data = map['data'];
    if (data is Map<String, dynamic>) {
      final token = data['access_token'];
      if (token is String && token.isNotEmpty) {
        _accessToken = token;
      }
      final refresh = data['refresh_token'];
      if (refresh is String && refresh.isNotEmpty) {
        _refreshToken = refresh;
      }
      final cb = _onTokensChanged;
      if (cb != null) {
        await cb(_accessToken, _refreshToken);
      }
    }
    return _accessToken != null;
  }

  @override
  Future<void> declineOffer(DriverOffer offer, {String reasonCode = 'NOT_AVAILABLE'}) async {
    final bid = offer.bookingId;
    final cid = offer.candidateId;
    final aid = offer.dispatchAttemptId;
    if (bid == null || cid == null || aid == null) {
      return;
    }
    await http.post(
      _u('/drivers/bookings/$bid/decline'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({
        'dispatch_attempt_id': aid,
        'candidate_id': cid,
        'reason_code': reasonCode,
      }),
    );
  }

  @override
  Future<DriverBookingCancelResult> cancelBooking(int bookingId, {required String reasonCode, String? notes}) async {
    final body = <String, dynamic>{'reason_code': reasonCode};
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }
    final r = await http.post(
      _u('/drivers/bookings/$bookingId/cancel'),
      headers: _headers(jsonBody: true, idempotencyKey: newIdempotencyKey('cancel-$bookingId')),
      body: jsonEncode(body),
    );
    final map = await _decode(r);
    if (r.statusCode >= 400 || map['success'] != true) {
      throw StateError('Cancel failed (${r.statusCode})');
    }
    final data = (map['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final ctx = _tripContext;
    if (ctx?.bookingId == bookingId) {
      _tripContext = null;
    }
    return DriverBookingCancelResult(
      bookingId: (data['booking_id'] as num?)?.toInt() ?? bookingId,
      status: '${data['status'] ?? 'CANCELLED_BY_DRIVER'}',
      cancelledAtIso: data['cancelled_at'] as String?,
    );
  }

  @override
  Future<void> markArrived({
    required int tripId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    await _postGeo(
      '/drivers/trips/$tripId/arrive',
      latitude,
      longitude,
      accuracy: accuracy,
      idempotencyKey: newIdempotencyKey('arrive-$tripId'),
    );
  }

  @override
  Future<void> startTrip({
    required int tripId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    await _postGeo(
      '/drivers/trips/$tripId/start',
      latitude,
      longitude,
      accuracy: accuracy,
      idempotencyKey: newIdempotencyKey('start-$tripId'),
    );
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
    await _postGeo(
      '/drivers/trips/$tripId/end',
      endLatitude,
      endLongitude,
      accuracy: accuracy,
      idempotencyKey: newIdempotencyKey('end-$tripId'),
    );

    final fare = (fareAmount == null || fareAmount.isEmpty) ? '0.00' : fareAmount;
    final pay = await http.post(
      _u('/payments/$bookingId/record'),
      headers: _headers(jsonBody: true, idempotencyKey: newIdempotencyKey('payment-$bookingId')),
      body: jsonEncode({
        'amount': fare,
        'method': 'CASH',
        'recorded_by_role': 'DRIVER',
        'notes': 'Recorded from driver app',
      }),
    );
    final payMap = await _decode(pay);
    if (pay.statusCode >= 400 || payMap['success'] != true) {
      throw StateError('Payment record failed (${pay.statusCode})');
    }
    final pdata = payMap['data'];
    String receiptNo = '—';
    if (pdata is Map<String, dynamic>) {
      final rc = pdata['receipt'];
      if (rc is Map<String, dynamic>) {
        receiptNo = '${rc['receipt_number'] ?? '—'}';
      }
    }

    final ctx = _tripContext;
    final pickupAddr = ctx?.pickupAddress ?? '';
    final destAddr = ctx?.destinationAddress ?? '';
    final passengerName = ctx?.passengerName ?? 'Passenger';
    _tripContext = null;

    return DriverTripSummary(
      bookingReference: bookingReference,
      receiptNumber: receiptNo,
      finalFare: 'PHP $fare',
      distance: ctx?.estimatedDistance ?? '—',
      duration: ctx?.estimatedDuration ?? '—',
      startTime: DateTime.now().toIso8601String(),
      endTime: DateTime.now().toIso8601String(),
      passengerName: passengerName,
      routeLabel: '$pickupAddr → $destAddr',
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
    await _postGeo('/drivers/trips/$tripId/location', latitude, longitude, accuracy: accuracy);
  }

  Future<void> clearAuthLocally() async {
    _accessToken = null;
    _refreshToken = null;
    final cb = _onTokensChanged;
    if (cb != null) {
      await cb(null, null);
    }
  }

  @override
  Future<bool> updateAvailability(bool online, {double? latitude, double? longitude}) async {
    final body = <String, dynamic>{
      'driver_status': online ? 'ONLINE' : 'OFFLINE',
    };
    if (online) {
      body['latitude'] = latitude ?? 7.114;
      body['longitude'] = longitude ?? 124.836;
    }
    final r = await http.post(
      _u('/drivers/me/availability'),
      headers: _headers(jsonBody: true),
      body: jsonEncode(body),
    );
    final map = await _decode(r);
    return r.statusCode < 400 && map['success'] == true;
  }

  @override
  Future<DriverOffer> acceptAssignment(DriverOffer offer) async {
    final bid = offer.bookingId;
    final cid = offer.candidateId;
    final aid = offer.dispatchAttemptId;
    if (bid == null || cid == null || aid == null) {
      throw StateError('Offer missing booking/candidate ids — reload dispatch offers from API.');
    }
    final r = await http.post(
      _u('/drivers/bookings/$bid/accept'),
      headers: _headers(jsonBody: true, idempotencyKey: newIdempotencyKey('accept-$bid')),
      body: jsonEncode({
        'dispatch_attempt_id': aid,
        'candidate_id': cid,
      }),
    );
    final map = await _decode(r);
    if (r.statusCode >= 400 || map['success'] != true) {
      throw StateError('Accept failed (${r.statusCode})');
    }
    final data = map['data'];
    final tripId = data is Map<String, dynamic> ? (data['trip_id'] as num?)?.toInt() : null;

    final merged = offer.copyWith(tripId: tripId);
    _tripContext = merged;
    return merged;
  }

  @override
  Future<List<DriverOffer>> fetchIncomingOffers({bool midAssignment = false}) async {
    final r = await http.get(_u('/drivers/me/dispatch-offers'), headers: _headers());
    final map = await _decode(r);
    if (r.statusCode >= 400 || map['success'] != true) {
      return <DriverOffer>[];
    }
    final data = map['data'];
    final offersRaw = data is Map<String, dynamic> ? data['offers'] : null;
    if (offersRaw is! List) {
      return <DriverOffer>[];
    }
    return offersRaw
        .whereType<Map>()
        .map((e) => _offerFromApi(e.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<PickupLayout> buildPickupFromAccepted(List<DriverOffer> accepted) async {
    if (accepted.isEmpty) {
      return PickupLayout(waiting: <TripPassenger>[], onboard: <TripPassenger>[]);
    }
    final DriverOffer o = accepted.first;
    final TripPassenger tp = TripPassenger(
      id: 'wait-${o.id}',
      name: o.passengerName,
      initials: o.passengerInitials,
      pickupAddress: o.pickupAddress,
      dropoffAddress: o.destinationAddress,
      rideType: o.rideType,
      fareDisplay: o.estimatedFare.replaceFirst('₱', 'PHP '),
      pickupNotes: 'Backend-assigned booking',
    );
    return PickupLayout(
      waiting: <TripPassenger>[tp],
      onboard: <TripPassenger>[],
      defaultSelectedWaitingId: tp.id,
    );
  }

  @override
  Future<int> addWalkInPassengers({
    required int existingPassengerCount,
    required int quantity,
    required int capacity,
  }) async {
    final tid = _tripContext?.tripId;
    if (tid == null) {
      throw StateError('No trip id — accept an offer first.');
    }
    final next = existingPassengerCount + quantity;
    if (next > capacity) {
      throw StateError('Passenger capacity exceeded.');
    }
    final r = await http.post(
      _u('/drivers/trips/$tid/add-passengers'),
      headers: _headers(jsonBody: true, idempotencyKey: newIdempotencyKey('addpax-$tid')),
      body: jsonEncode({'quantity': quantity}),
    );
    final map = await _decode(r);
    if (r.statusCode >= 400 || map['success'] != true) {
      throw StateError('add-passengers failed (${r.statusCode})');
    }
    return next;
  }

  Future<void> _postGeo(
    String path,
    double lat,
    double lng, {
    double? accuracy,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'latitude': lat,
      'longitude': lng,
    };
    if (accuracy != null) body['accuracy_meters'] = accuracy;
    final r = await http.post(
      _u(path),
      headers: _headers(jsonBody: true, idempotencyKey: idempotencyKey),
      body: jsonEncode(body),
    );
    final map = await _decode(r);
    if (r.statusCode >= 400 || map['success'] != true) {
      throw StateError('Request failed $path (${r.statusCode})');
    }
  }

  @override
  Future<List<DriverHistoryBooking>> myBookings({bool active = false}) async {
    final qp = active ? '?active=1' : '';
    final r = await http.get(_u('/drivers/me/bookings$qp'), headers: _headers());
    final map = await _decode(r);
    if (r.statusCode >= 400 || map['success'] != true) {
      return <DriverHistoryBooking>[];
    }
    final data = map['data'];
    final raw = data is Map<String, dynamic> ? data['bookings'] : null;
    if (raw is! List) return <DriverHistoryBooking>[];
    return raw
        .whereType<Map>()
        .map((e) => _historyFromApi(e.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<DriverHistoryBooking?> bookingDetail(int bookingId) async {
    final r = await http.get(_u('/drivers/me/bookings/$bookingId'), headers: _headers());
    final map = await _decode(r);
    if (r.statusCode >= 400 || map['success'] != true) {
      return null;
    }
    final data = map['data'];
    final raw = data is Map<String, dynamic> ? data['booking'] : null;
    if (raw is! Map) return null;
    return _historyFromApi(raw.cast<String, dynamic>());
  }
}
