import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/cache/driver_bookings_cache.dart';
import '../../data/mock_data.dart';
import 'data/driver_flow_repository.dart';
import 'data/http_driver_flow_repository.dart';
import 'domain/driver_flow_models.dart';

/// Booking-state phases as PRD §11 enumerates them, exposed to the driver
/// app UI so each transition fires its own backend call.
///
/// `waitingOffers` is the offline/no-deck idle state.  Each subsequent phase
/// maps 1:1 to a button on the pickup / trip-in-progress screens.
enum DriverPhase {
  waitingOffers,
  assigned,
  onTheWay,
  arrived,
  inProgress,
  completed,
}

extension DriverPhaseLabel on DriverPhase {
  String get label {
    switch (this) {
      case DriverPhase.waitingOffers:
        return 'WAITING';
      case DriverPhase.assigned:
        return 'ASSIGNED';
      case DriverPhase.onTheWay:
        return 'ON THE WAY';
      case DriverPhase.arrived:
        return 'ARRIVED';
      case DriverPhase.inProgress:
        return 'IN PROGRESS';
      case DriverPhase.completed:
        return 'COMPLETED';
    }
  }
}

class DriverFlowController extends ChangeNotifier {
  DriverFlowController({
    required DriverFlowRepository repository,
    DriverBookingsCache? bookingsCache,
  })  : _repository = repository,
        _bookingsCache = bookingsCache ?? DriverBookingsCache();

  DriverFlowRepository _repository;
  final DriverBookingsCache _bookingsCache;
  Timer? _offerPollTimer;
  Timer? _locationPingTimer;
  Timer? _idleAvailabilityTimer;
  bool _isPollingOffers = false;
  bool _isPingingLocation = false;
  bool _isPingingIdle = false;

  /// Allow swapping the underlying repository (e.g. when API base changes in Settings).
  void replaceRepository(DriverFlowRepository repository) {
    stopOfferPolling();
    stopLocationPing();
    stopIdleAvailabilityPing();
    _repository = repository;
    notifyListeners();
  }

  DriverFlowRepository get repository => _repository;

  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;
  bool otpSent = false;
  int resendSeconds = 60;
  Timer? _resendTimer;

  bool isOnline = true;

  /// Last known driver position; refreshed by online toggle, the in-trip ping,
  /// and the idle-availability ping.  Used as a fallback for arrive/end calls
  /// when GPS retrieval times out.
  double? lastLatitude;
  double? lastLongitude;

  /// PRD §11 phase. Drives the explicit-button stack on assigned pickup +
  /// trip-in-progress screens.
  DriverPhase phase = DriverPhase.waitingOffers;

  /// Visible offer cards (mockup carousel deck).
  List<DriverOffer> offers = <DriverOffer>[];

  /// When the driver dismisses the offer surface while offers are still pending,
  /// we suppress auto-navigation and instead show attention cues on the home UI.
  bool offerSurfaceSuppressed = false;

  void suppressAutoOfferSurface() {
    offerSurfaceSuppressed = true;
    notifyListeners();
  }

  void clearOfferSurfaceSuppression() {
    if (!offerSurfaceSuppressed) return;
    offerSurfaceSuppressed = false;
    notifyListeners();
  }

  /// Accepted during current batch; persists until pickup/trip reset.
  List<DriverOffer> acceptedOffers = <DriverOffer>[];

  /// When offer batch completes mid-assignment, UI returns to pickup without clearing state.
  bool returnToAssignedPickupAfterBatch = false;

  /// First-assigned booking reference for screens that need a single anchor.
  DriverOffer? tripAnchorOffer;

  List<TripPassenger> waitingPassengers = <TripPassenger>[];
  List<TripPassenger> onboardPassengers = <TripPassenger>[];

  /// Selected waiting passenger for arrived-pickup highlight.
  String? activeWaitingPassengerId;

  int capacity = 4;
  DriverMeProfile? me;
  DriverTripSummary? tripSummary;

  /// Display cache for trip history, earnings, and dashboard stats.
  List<DriverHistoryBooking>? bookings;
  DateTime? bookingsFetchedAt;
  bool bookingsRefreshing = false;
  String? bookingsLoadError;

  /// Per-passenger receipt shown after completing an individual passenger.
  DriverTripSummary? passengerTripSummary;

  /// The passenger whose trip was just completed (for the receipt screen).
  TripPassenger? lastCompletedPassenger;

  String? errorMessage;
  String? lastError;

  /// Shown once on assigned pickup until user opens incoming offers (mockup session behavior).
  bool showIncomingOfferBanner = true;

  /// Optional destination from Add Passenger screen (walk-in).
  String? destinationWalkIn;

  Future<void> requestOtp() async {
    final String phone = phoneController.text.trim();
    if (phone.isEmpty) {
      errorMessage = 'Enter your mobile number first.';
      notifyListeners();
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.requestOtp(phone);
      otpSent = true;
      resendSeconds = 60;
      _startResendTimer();
    } catch (_) {
      errorMessage = 'Unable to request OTP. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String otpCode) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final bool ok = await _repository.verifyOtp(phoneController.text.trim(), otpCode);
      if (!ok) {
        errorMessage = 'Invalid OTP code.';
        return false;
      }
      // Fetch driver identity/profile from backend (name, tricycle, TODA).
      me = await _repository.myProfile();
      _syncBookingsCacheScope();
      if (me?.tricycleCapacity != null) {
        capacity = me!.tricycleCapacity!;
      }
      return ok;
    } catch (e) {
      if (e is StateError) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Verification failed. Please retry.';
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setErrorMessage(String message) {
    errorMessage = message;
    notifyListeners();
  }

  Future<void> resendOtp() async {
    if (resendSeconds > 0 || isLoading) {
      return;
    }
    await requestOtp();
  }

  void resetOtpFlow() {
    otpSent = false;
    resendSeconds = 0;
    errorMessage = null;
    _resendTimer?.cancel();
    _resendTimer = null;
    notifyListeners();
  }

  /// PRD §14.1 — request a fresh GPS sample, then post availability with the
  /// real coordinates.  Returns the result message so screens can surface
  /// permission denials etc.
  Future<String?> setAvailability({required bool desiredOnline}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    String? result;
    try {
      double? lat;
      double? lng;
      if (desiredOnline) {
        try {
          LocationPermission perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied) {
            perm = await Geolocator.requestPermission();
          }
          if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
            result = 'Location permission denied — going online with last known position.';
          } else {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
            );
            lat = pos.latitude;
            lng = pos.longitude;
            lastLatitude = lat;
            lastLongitude = lng;
          }
        } catch (_) {
          result = 'GPS unavailable — going online with last known position.';
        }

        // Always provide a usable coordinate when turning online so the backend
        // can accept the transition even if GPS/permission is unavailable.
        lat ??= lastLatitude ?? 7.114;
        lng ??= lastLongitude ?? 124.836;
      }
      isOnline = await _repository.updateAvailability(
        desiredOnline,
        latitude: lat,
        longitude: lng,
      );
      if (isOnline) {
        startIdleAvailabilityPing();
      } else {
        stopIdleAvailabilityPing();
      }
    } catch (e) {
      final String msg =
          (e is StateError) ? e.message : 'Unable to update availability.';
      errorMessage = msg;
      result = msg;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return result;
  }

  /// Loads offers. Use [midAssignment] when opening from assigned pickup “Handle Now”.
  Future<void> loadOffers({bool midAssignment = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      offers = await _repository.fetchIncomingOffers(midAssignment: midAssignment);
      if (offers.isEmpty) {
        offerSurfaceSuppressed = false;
      }
      if (!midAssignment) {
        acceptedOffers = <DriverOffer>[];
      }
    } catch (_) {
      errorMessage = 'Failed to load offers.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Special vs shared mutual exclusion (mockup `03-incoming-offer.html`).
  String? validateAccept(DriverOffer offer) {
    if (offer.rideType == RideType.special && acceptedOffers.isNotEmpty) {
      return 'Special ride cannot be queued with other accepted offers. Please decline this special offer or handle others first.';
    }
    if (offer.rideType == RideType.shared &&
        acceptedOffers.any((DriverOffer o) => o.rideType == RideType.special)) {
      return 'You already accepted a special ride. Additional accepts are disabled for this batch.';
    }
    return null;
  }

  Future<void> acceptOffer(DriverOffer offer) async {
    isLoading = true;
    errorMessage = null;
    lastError = null;
    notifyListeners();
    try {
      final DriverOffer resolved = await _repository.acceptAssignment(offer);
      acceptedOffers.add(resolved);
      final List<DriverOffer> losers = offers.where((DriverOffer o) => o.id != offer.id).toList();
      offers = <DriverOffer>[];

      // PRD §11 single-winner: on a real backend, auto-decline every other queued
      // offer so dispatch sees consistent driver state.  Mock repos no-op.
      for (final DriverOffer lost in losers) {
        unawaited(_repository.declineOffer(lost, reasonCode: 'CANCELLED_LOCAL'));
      }
      phase = DriverPhase.assigned;
      await _afterOfferDeckChanged();
    } catch (_) {
      errorMessage = 'Could not accept offer. Check connection and try again.';
      lastError = errorMessage;
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---- offer polling ----

  void startOfferPolling({Duration interval = const Duration(seconds: 6)}) {
    if (!_repository.supportsPolling) return;
    if (_offerPollTimer != null) return;
    _offerPollTimer = Timer.periodic(interval, (_) async {
      if (!isOnline || _isPollingOffers) return;
      _isPollingOffers = true;
      try {
        final fresh = await _repository.fetchIncomingOffers();
        if (acceptedOffers.isEmpty) {
          final knownIds = offers.map((o) => o.id).toSet();
          final freshIds = fresh.map((o) => o.id).toSet();
          if (knownIds.length != freshIds.length || knownIds.difference(freshIds).isNotEmpty) {
            offers = fresh;
            if (offers.isEmpty) {
              offerSurfaceSuppressed = false;
            }
            notifyListeners();
          }
        }
      } catch (_) {
      } finally {
        _isPollingOffers = false;
      }
    });
  }

  void stopOfferPolling() {
    _offerPollTimer?.cancel();
    _offerPollTimer = null;
  }

  // ---- live GPS ping while trip in progress ----

  Future<void> startLocationPing({Duration interval = const Duration(seconds: 10)}) async {
    final repo = _repository;
    if (repo is! HttpDriverFlowRepository) return;
    final ctx = repo.tripContext;
    final tripId = ctx?.tripId;
    if (tripId == null) return;
    if (_locationPingTimer != null) return;

    if (!await _ensureLocationPermission()) {
      return;
    }

    _locationPingTimer = Timer.periodic(interval, (_) async {
      if (_isPingingLocation) return;
      _isPingingLocation = true;
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        lastLatitude = pos.latitude;
        lastLongitude = pos.longitude;
        await repo.sendDriverLocation(
          tripId: tripId,
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
        );
      } catch (_) {
      } finally {
        _isPingingLocation = false;
      }
    });
  }

  void stopLocationPing() {
    _locationPingTimer?.cancel();
    _locationPingTimer = null;
  }

  /// PRD §14.1 — when online and idle (no trip), keep refreshing the
  /// driver's last-known position every 30s so dispatch can rank.
  void startIdleAvailabilityPing({Duration interval = const Duration(seconds: 30)}) {
    if (!_repository.supportsPolling) return;
    if (_idleAvailabilityTimer != null) return;
    _idleAvailabilityTimer = Timer.periodic(interval, (_) async {
      if (!isOnline) return;
      if (phase != DriverPhase.waitingOffers && phase != DriverPhase.assigned) return;
      if (_isPingingIdle) return;
      _isPingingIdle = true;
      try {
        if (!await _ensureLocationPermission()) {
          return;
        }
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        lastLatitude = pos.latitude;
        lastLongitude = pos.longitude;
        await _repository.updateAvailability(true, latitude: pos.latitude, longitude: pos.longitude);
      } catch (_) {
      } finally {
        _isPingingIdle = false;
      }
    });
  }

  void stopIdleAvailabilityPing() {
    _idleAvailabilityTimer?.cancel();
    _idleAvailabilityTimer = null;
  }

  Future<bool> _ensureLocationPermission() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// User-tap decline of a single offer (PRD §12 — fires `POST /decline`).
  Future<void> declineCurrentOffer(DriverOffer offer, {String reasonCode = 'NOT_AVAILABLE'}) async {
    lastError = null;
    try {
      await _repository.declineOffer(offer, reasonCode: reasonCode);
    } catch (_) {
      lastError = 'Decline failed; offer dismissed locally.';
    }
    offers = offers.where((DriverOffer o) => o.id != offer.id).toList();
    await _afterOfferDeckChanged();
  }

  Future<void> expireOffer(DriverOffer offer) async {
    offers = offers.where((DriverOffer o) => o.id != offer.id).toList();
    await _afterOfferDeckChanged();
  }

  Future<void> _afterOfferDeckChanged() async {
    if (offers.isNotEmpty) {
      notifyListeners();
      return;
    }

    if (returnToAssignedPickupAfterBatch) {
      notifyListeners();
      return;
    }

    if (acceptedOffers.isNotEmpty) {
      final PickupLayout layout = await _repository.buildPickupFromAccepted(acceptedOffers);
      waitingPassengers = layout.waiting;
      onboardPassengers = layout.onboard;
      activeWaitingPassengerId = layout.defaultSelectedWaitingId ??
          (layout.waiting.isNotEmpty ? layout.waiting.first.id : null);
      tripAnchorOffer = acceptedOffers.first;
      showIncomingOfferBanner = true;
      phase = DriverPhase.assigned;
    }

    notifyListeners();
  }

  void setReturnToAssignedPickup(bool value) {
    returnToAssignedPickupAfterBatch = value;
  }

  void clearReturnToAssignedPickup() {
    returnToAssignedPickupAfterBatch = false;
    notifyListeners();
  }

  void dismissIncomingOfferBanner() {
    showIncomingOfferBanner = false;
    notifyListeners();
  }

  void openIncomingOffersFromPickup() {
    showIncomingOfferBanner = false;
    notifyListeners();
  }

  /// Select which waiting passenger is the active pickup target (mockup `setActivePickup`).
  void selectWaitingPassenger(String passengerId) {
    activeWaitingPassengerId = passengerId;
    notifyListeners();
  }

  // ----- explicit booking phase transitions (PRD §11) -----

  /// `assigned` → `onTheWay`.
  ///
  /// PRD §11 has no dedicated "on the way" endpoint (the booking already
  /// flips to `DRIVER_ON_THE_WAY` at accept time on the backend); this is a
  /// purely UX state that gates the next button.
  void markOnTheWay() {
    if (phase != DriverPhase.assigned) return;
    lastError = null;
    phase = DriverPhase.onTheWay;
    notifyListeners();
  }

  /// `onTheWay` → `arrived`.  POST /drivers/trips/{trip}/arrive.
  Future<void> markArrived() async {
    if (phase != DriverPhase.onTheWay) return;
    final ctx = tripAnchorOffer;
    final tripId = ctx?.tripId;
    if (ctx == null || tripId == null) {
      lastError = 'No trip in progress.';
      notifyListeners();
      return;
    }
    isLoading = true;
    errorMessage = null;
    lastError = null;
    notifyListeners();
    final previous = phase;
    phase = DriverPhase.arrived;
    notifyListeners();
    try {
      final pos = await _bestEffortPosition();
      await _repository.markArrived(
        tripId: tripId,
        latitude: pos.$1 ?? ctx.pickupLatitude ?? 7.1083,
        longitude: pos.$2 ?? ctx.pickupLongitude ?? 124.8295,
        accuracy: 6,
      );
    } catch (_) {
      lastError = 'Failed to mark arrived. Please retry.';
      phase = previous;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// `arrived` → `inProgress`.  POST /drivers/trips/{trip}/start.
  Future<void> startTrip() async {
    if (phase != DriverPhase.arrived) return;
    final ctx = tripAnchorOffer;
    final tripId = ctx?.tripId;
    if (ctx == null || tripId == null) {
      lastError = 'No trip in progress.';
      notifyListeners();
      return;
    }
    isLoading = true;
    errorMessage = null;
    lastError = null;
    notifyListeners();
    final previous = phase;
    phase = DriverPhase.inProgress;
    notifyListeners();
    try {
      final pos = await _bestEffortPosition();
      await _repository.startTrip(
        tripId: tripId,
        latitude: pos.$1 ?? ctx.pickupLatitude ?? 7.1083,
        longitude: pos.$2 ?? ctx.pickupLongitude ?? 124.8295,
        accuracy: 6,
      );
      _ensureOnboardSeed();
    } catch (_) {
      lastError = 'Failed to start trip. Please retry.';
      phase = previous;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// `inProgress` → `completed`.  POST /drivers/trips/{trip}/end +
  /// /payments/{booking}/record.
  Future<void> endTrip({bool forceCompletePhase = true}) async {
    if (phase != DriverPhase.inProgress) {
      // Allow a manual recovery: still attempt end if we have a trip context.
    }
    final ctx = tripAnchorOffer;
    final tripId = ctx?.tripId;
    final bookingId = ctx?.bookingId;
    if (ctx == null || tripId == null || bookingId == null) {
      lastError = 'No trip in progress.';
      notifyListeners();
      return;
    }
    isLoading = true;
    errorMessage = null;
    lastError = null;
    notifyListeners();
    final previous = phase;
    try {
      final pos = await _bestEffortPosition();
      tripSummary = await _repository.endTrip(
        tripId: tripId,
        bookingId: bookingId,
        bookingReference: ctx.reference,
        passengerCount: onboardPassengers.length.clamp(1, capacity),
        endLatitude: pos.$1 ?? ctx.destinationLatitude ?? 7.1117,
        endLongitude: pos.$2 ?? ctx.destinationLongitude ?? 124.8419,
        fareAmount: ctx.estimatedFareAmount,
        accuracy: 8,
        preserveContext: !forceCompletePhase,
      );
      if (forceCompletePhase) {
        phase = DriverPhase.completed;
        stopLocationPing();
        unawaited(loadBookings(forceNetwork: true));
      }
    } catch (_) {
      lastError = 'Failed to end trip. Please retry.';
      phase = previous;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _syncBookingsCacheScope() {
    final id = me?.driverId;
    _bookingsCache.scopeKey = id != null ? 'driver_$id' : 'default';
  }

  /// Load bookings for display screens. Uses memory/disk cache unless [forceNetwork].
  Future<void> loadBookings({required bool forceNetwork}) async {
    _syncBookingsCacheScope();
    bookingsLoadError = null;

    if (!forceNetwork) {
      if (bookings != null) return;

      final cached = await _bookingsCache.readList();
      if (cached != null && cached.rows.isNotEmpty) {
        bookings = cached.rows;
        bookingsFetchedAt = cached.fetchedAt;
        notifyListeners();
        return;
      }
    }

    final hadData = bookings != null;
    bookingsRefreshing = hadData;
    if (!hadData) notifyListeners();

    try {
      final rows = await _repository.myBookings();
      bookings = rows;
      bookingsFetchedAt = DateTime.now();
      await _bookingsCache.writeList(rows);
    } catch (e) {
      bookingsLoadError = e.toString();
      if (!hadData) bookings = null;
    } finally {
      bookingsRefreshing = false;
      notifyListeners();
    }
  }

  Future<DriverHistoryBooking?> bookingDetail(int bookingId, {required bool forceNetwork}) async {
    _syncBookingsCacheScope();

    if (!forceNetwork) {
      final fromList = bookings?.where((b) => b.id == bookingId).cast<DriverHistoryBooking?>().firstOrNull;
      if (fromList != null) return fromList;
      final cached = await _bookingsCache.readDetail(bookingId);
      if (cached != null) return cached;
    }

    try {
      final detail = await _repository.bookingDetail(bookingId);
      if (detail != null) {
        await _bookingsCache.writeDetail(detail);
      }
      return detail;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearBookingsCache() async {
    bookings = null;
    bookingsFetchedAt = null;
    bookingsLoadError = null;
    bookingsRefreshing = false;
    await _bookingsCache.clear();
    notifyListeners();
  }

  Future<void> signOut() async {
    stopOfferPolling();
    stopLocationPing();
    stopIdleAvailabilityPing();
    await clearBookingsCache();
    if (_repository is HttpDriverFlowRepository) {
      await (_repository as HttpDriverFlowRepository).clearAuthLocally();
    }
    me = null;
    resetTripFlow();
    otpSent = false;
    notifyListeners();
  }

  Future<void> cancelAssignment({required String reasonCode, String? notes}) async {
    final ctx = tripAnchorOffer;
    final bookingId = ctx?.bookingId;
    if (ctx == null || bookingId == null) {
      lastError = 'No assignment to cancel.';
      notifyListeners();
      return;
    }
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      await _repository.cancelBooking(bookingId, reasonCode: reasonCode, notes: notes);
      resetTripFlow();
    } catch (_) {
      lastError = 'Cancel failed; please retry.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<(double?, double?)> _bestEffortPosition() async {
    try {
      if (await _ensureLocationPermission()) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        lastLatitude = pos.latitude;
        lastLongitude = pos.longitude;
        return (pos.latitude, pos.longitude);
      }
    } catch (_) {}
    return (lastLatitude, lastLongitude);
  }

  /// Materialise a default onboard list once trip starts when running on the
  /// HTTP repo (mock already provides one via `MockTripInProgress`).
  void _ensureOnboardSeed() {
    if (onboardPassengers.isNotEmpty) return;
    final ctx = tripAnchorOffer;
    if (ctx == null) {
      onboardPassengers = MockTripInProgress.onboardOrder
          .map((TripPassenger p) => TripPassenger(
                id: p.id,
                name: p.name,
                initials: p.initials,
                pickupAddress: p.pickupAddress,
                dropoffAddress: p.dropoffAddress,
                routeSubtitle: p.routeSubtitle,
                fareDisplay: p.fareDisplay,
              ))
          .toList();
      return;
    }
    onboardPassengers = <TripPassenger>[
      TripPassenger(
        id: 'live-${ctx.id}',
        bookingId: ctx.bookingId,
        name: ctx.passengerName,
        initials: ctx.passengerInitials,
        pickupAddress: ctx.pickupAddress,
        dropoffAddress: ctx.destinationAddress,
        routeSubtitle: '${ctx.pickupAddress} → ${ctx.destinationAddress}',
        fareDisplay: ctx.estimatedFare.replaceFirst('₱', 'PHP '),
      ),
    ];
    waitingPassengers = <TripPassenger>[];
  }

  TripPassenger? get _activeWaitingPassenger {
    final String? id = activeWaitingPassengerId;
    if (id == null) return null;
    for (final TripPassenger p in waitingPassengers) {
      if (p.id == id) return p;
    }
    return null;
  }

  String get pickupHeaderTask {
    final TripPassenger? active = _activeWaitingPassenger;
    switch (phase) {
      case DriverPhase.assigned:
        final String firstName = waitingPassengers.isNotEmpty
            ? waitingPassengers.first.name
            : (active?.name ?? 'Passenger');
        return 'Heading to $firstName';
      case DriverPhase.onTheWay:
        return 'On the way to ${active?.name ?? 'passenger'}';
      case DriverPhase.arrived:
        return active != null ? "Arrived at ${active.name}'s pickup" : 'Arrived at pickup';
      case DriverPhase.inProgress:
        return 'Trip in progress';
      case DriverPhase.completed:
        return 'Trip completed';
      case DriverPhase.waitingOffers:
        return 'Waiting for offers';
    }
  }

  /// Label for the explicit primary CTA on the pickup screen.
  String get pickupPrimaryLabel {
    switch (phase) {
      case DriverPhase.assigned:
        return 'On the way';
      case DriverPhase.onTheWay:
        return 'Mark Arrived';
      case DriverPhase.arrived:
        return 'Start Trip';
      case DriverPhase.inProgress:
        return 'In progress';
      default:
        return 'Continue';
    }
  }

  IconData get pickupPrimaryIcon {
    switch (phase) {
      case DriverPhase.assigned:
        return Icons.directions_rounded;
      case DriverPhase.onTheWay:
        return Icons.flag_outlined;
      case DriverPhase.arrived:
        return Icons.play_arrow_rounded;
      default:
        return Icons.navigation_rounded;
    }
  }

  /// Single dispatcher for the pickup screen primary CTA.  Returns true when
  /// the trip-in-progress screen should be opened by the caller.
  Future<bool> advancePickupPrimary() async {
    switch (phase) {
      case DriverPhase.assigned:
        markOnTheWay();
        return false;
      case DriverPhase.onTheWay:
        await markArrived();
        return false;
      case DriverPhase.arrived:
        await startTrip();
        return phase == DriverPhase.inProgress;
      default:
        return false;
    }
  }

  void markPassengerCompleted(String passengerId) {
    onboardPassengers = onboardPassengers
        .map(
          (TripPassenger p) =>
              p.id == passengerId ? p.copyWith(completed: true) : p,
        )
        .toList();
    notifyListeners();
  }

  int get currentPassengerCount => onboardPassengers.length;

  int get completedPassengerCount =>
      onboardPassengers.where((TripPassenger p) => p.completed).length;

  bool get canCompleteTrip =>
      onboardPassengers.isNotEmpty && completedPassengerCount == onboardPassengers.length;

  /// True when there are still passengers who have not been completed.
  bool get hasRemainingPassengers => nextIncompletePassenger != null;

  TripPassenger? get nextIncompletePassenger {
    for (final TripPassenger p in onboardPassengers) {
      if (!p.completed) return p;
    }
    return null;
  }

  String get tripHeaderTask {
    final TripPassenger? next = nextIncompletePassenger;
    if (next == null) {
      return 'All passengers dropped off';
    }
    return 'Drop off ${next.name}';
  }

  String get tripPrimaryLabel {
    final TripPassenger? next = nextIncompletePassenger;
    if (next == null) {
      return 'End Trip';
    }
    final String first = next.name.split(' ').first;
    return "Complete $first's Trip";
  }

  /// Complete a single passenger's trip — marks them done, generates a
  /// per-passenger receipt summary.  If this was the last passenger,
  /// calls [endTrip] to finalize the backend state.
  ///
  /// Returns `true` when the caller should navigate to the receipt screen.
  Future<bool> completePassengerTrip(String passengerId) async {
    // Find the passenger before marking them done
    final TripPassenger? passenger = onboardPassengers
        .where((TripPassenger p) => p.id == passengerId)
        .cast<TripPassenger?>()
        .firstOrNull;
    if (passenger == null || passenger.completed) return false;

    // Mark completed in local state
    markPassengerCompleted(passengerId);
    lastCompletedPassenger = passenger;

    final ctx = tripAnchorOffer;
    final String reference = ctx?.reference ?? 'TK-XXXXXXX';
    final String pickupAddr = passenger.pickupAddress;
    final String dropoffAddr = passenger.dropoffAddress;
    final String fare = passenger.fareDisplay ?? ctx?.estimatedFare ?? 'PHP 0.00';

    // Check if all passengers are now completed
    final bool allDone = !hasRemainingPassengers;
    final bool isAnchor = ctx != null &&
        ctx.bookingId != null &&
        passenger.bookingId != null &&
        passenger.bookingId == ctx.bookingId;

    if (allDone || isAnchor) {
      // Anchor passenger or last passenger — call endTrip to finalize on the backend
      // But only force phase completion and clear context if all passengers are done
      await endTrip(forceCompletePhase: allDone);
      if (lastError != null) return false;

      // Use the official tripSummary from endTrip but override passenger-specific fields
      passengerTripSummary = tripSummary ?? DriverTripSummary(
        bookingReference: reference,
        receiptNumber: 'RCP-${DateTime.now().millisecondsSinceEpoch}',
        finalFare: fare,
        distance: ctx?.estimatedDistance ?? '—',
        duration: ctx?.estimatedDuration ?? '—',
        startTime: DateTime.now().toIso8601String(),
        endTime: DateTime.now().toIso8601String(),
        passengerName: passenger.name,
        routeLabel: '$pickupAddr → $dropoffAddr',
        passengerCount: allDone ? onboardPassengers.length : 1,
        collectSubtitle: 'Collect cash payment from ${passenger.name}',
      );
    } else {
      // Mid-trip passenger completion (walk-ins) — generate a local receipt summary
      passengerTripSummary = DriverTripSummary(
        bookingReference: reference,
        receiptNumber: 'RCP-${DateTime.now().millisecondsSinceEpoch}',
        finalFare: fare,
        distance: ctx?.estimatedDistance ?? '—',
        duration: ctx?.estimatedDuration ?? '—',
        startTime: DateTime.now().toIso8601String(),
        endTime: DateTime.now().toIso8601String(),
        passengerName: passenger.name,
        routeLabel: '$pickupAddr → $dropoffAddr',
        passengerCount: 1,
        collectSubtitle: 'Collect cash payment from ${passenger.name}',
      );
    }

    notifyListeners();
    return true;
  }

  /// Clear the per-passenger receipt so the driver can return to trip screen.
  void clearPassengerReceipt() {
    passengerTripSummary = null;
    lastCompletedPassenger = null;
    notifyListeners();
  }

  Future<void> completeNextTripLeg() async {
    final TripPassenger? next = nextIncompletePassenger;
    if (next != null) {
      await completePassengerTrip(next.id);
    }
  }

  Future<void> addPassengers(int quantity) async {
    if (tripAnchorOffer == null) return;
    final int nextCount = await _repository.addWalkInPassengers(
      existingPassengerCount: onboardPassengers.length,
      quantity: quantity,
      capacity: capacity,
    );
    final int toCreate = nextCount - onboardPassengers.length;
    for (int i = 0; i < toCreate; i++) {
      onboardPassengers = <TripPassenger>[
        ...onboardPassengers,
        TripPassenger(
          id: 'walkin-${DateTime.now().millisecondsSinceEpoch}-$i',
          name: 'Walk-in Passenger ${onboardPassengers.length + 1}',
          pickupAddress: tripAnchorOffer!.pickupAddress,
          dropoffAddress: destinationWalkIn ?? tripAnchorOffer!.destinationAddress,
        ),
      ];
    }
    notifyListeners();
  }

  void resetTripFlow() {
    acceptedOffers = <DriverOffer>[];
    tripAnchorOffer = null;
    waitingPassengers = <TripPassenger>[];
    onboardPassengers = <TripPassenger>[];
    tripSummary = null;
    passengerTripSummary = null;
    lastCompletedPassenger = null;
    activeWaitingPassengerId = null;
    offerSurfaceSuppressed = false;
    phase = DriverPhase.waitingOffers;
    stopLocationPing();
    notifyListeners();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (resendSeconds <= 0) {
        timer.cancel();
      } else {
        resendSeconds--;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _offerPollTimer?.cancel();
    _locationPingTimer?.cancel();
    _idleAvailabilityTimer?.cancel();
    phoneController.dispose();
    super.dispose();
  }
}
