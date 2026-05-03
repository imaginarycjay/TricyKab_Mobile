import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import 'data/driver_flow_repository.dart';
import 'domain/driver_flow_models.dart';

class DriverFlowController extends ChangeNotifier {
  DriverFlowController({required DriverFlowRepository repository}) : _repository = repository;

  final DriverFlowRepository _repository;

  final TextEditingController phoneController = TextEditingController(
    text: MockDriver.phoneNumber,
  );

  bool isLoading = false;
  bool otpSent = false;
  int resendSeconds = 60;
  Timer? _resendTimer;

  bool isOnline = true;

  /// Visible offer cards (mockup carousel deck).
  List<DriverOffer> offers = <DriverOffer>[];

  /// Accepted during current batch; persists until pickup/trip reset.
  List<DriverOffer> acceptedOffers = <DriverOffer>[];

  /// When offer batch completes mid-assignment, UI returns to pickup without clearing state.
  bool returnToAssignedPickupAfterBatch = false;

  /// First-assigned booking reference for screens that need a single anchor.
  DriverOffer? tripAnchorOffer;

  List<TripPassenger> waitingPassengers = <TripPassenger>[];
  List<TripPassenger> onboardPassengers = <TripPassenger>[];

  /// Selected waiting passenger for “Arrived” highlight + header copy.
  String? activeWaitingPassengerId;

  /// 0–3 matches mockup primary button cycle on assigned pickup.
  int pickupPrimaryStep = 0;

  int capacity = MockDriver.capacity;
  DriverTripSummary? tripSummary;
  String? errorMessage;

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
      }
      return ok;
    } catch (_) {
      errorMessage = 'Verification failed. Please retry.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendOtp() async {
    if (resendSeconds > 0 || isLoading) {
      return;
    }
    await requestOtp();
  }

  Future<void> toggleAvailability() async {
    isLoading = true;
    notifyListeners();
    final bool nextValue = !isOnline;
    try {
      isOnline = await _repository.updateAvailability(nextValue);
    } catch (_) {
      errorMessage = 'Unable to update availability.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Loads offers. Use [midAssignment] when opening from assigned pickup “Handle Now”.
  Future<void> loadOffers({bool midAssignment = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      offers = await _repository.fetchIncomingOffers(midAssignment: midAssignment);
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
    acceptedOffers.add(offer);
    offers = offers.where((DriverOffer o) => o.id != offer.id).toList();
    await _afterOfferDeckChanged();
  }

  Future<void> declineOffer(DriverOffer offer) async {
    offers = offers.where((DriverOffer o) => o.id != offer.id).toList();
    await _afterOfferDeckChanged();
  }

  Future<void> expireOffer(DriverOffer offer) async {
    await declineOffer(offer);
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
      pickupPrimaryStep = 0;
      tripAnchorOffer = acceptedOffers.first;
      showIncomingOfferBanner = true;
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
    pickupPrimaryStep = 1;
    notifyListeners();
  }

  /// Advance primary CTA through mockup states; returns true when trip-in-progress should open.
  bool advancePickupPrimary() {
    pickupPrimaryStep++;
    if (pickupPrimaryStep <= 3) {
      notifyListeners();
      return false;
    }
    startTripPhaseFromPickup();
    pickupPrimaryStep = 0;
    notifyListeners();
    return true;
  }

  /// Loads onboard passengers for trip-in-progress (after pickup phase completes).
  void startTripPhaseFromPickup() {
    onboardPassengers = MockTripInProgress.onboardOrder
        .map(
          (TripPassenger p) => TripPassenger(
            id: p.id,
            name: p.name,
            initials: p.initials,
            pickupAddress: p.pickupAddress,
            dropoffAddress: p.dropoffAddress,
            routeSubtitle: p.routeSubtitle,
            fareDisplay: p.fareDisplay,
          ),
        )
        .toList();
    waitingPassengers = <TripPassenger>[];
    pickupPrimaryStep = 0;
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
    if (pickupPrimaryStep == 1 && active != null) {
      return "Arrived at ${active.name}'s pickup";
    }
    switch (pickupPrimaryStep) {
      case 0:
        final String firstName =
            waitingPassengers.isNotEmpty ? waitingPassengers.first.name : (active?.name ?? 'Passenger');
        return 'Pick up $firstName';
      case 1:
        return "Starting ${active?.name ?? 'Passenger'}'s Trip";
      case 2:
        return 'Next: Pick up more passengers';
      case 3:
        return 'Heading to destinations';
      default:
        return 'Pick up passenger';
    }
  }

  String get pickupPrimaryLabel {
    final TripPassenger? active = _activeWaitingPassenger;
    final String name = active?.name ?? (waitingPassengers.isNotEmpty ? waitingPassengers.first.name : 'Passenger');

    switch (pickupPrimaryStep) {
      case 0:
        return 'Arrived at Pickup';
      case 1:
        return "Start $name's Trip";
      case 2:
        return 'Navigate to Next Pickup';
      case 3:
        return 'Continue to Destinations';
      default:
        return 'Arrived at Pickup';
    }
  }

  IconData get pickupPrimaryIcon {
    switch (pickupPrimaryStep.clamp(0, 3)) {
      case 0:
        return Icons.flag_outlined;
      case 1:
        return Icons.play_arrow_rounded;
      case 2:
        return Icons.navigation_rounded;
      case 3:
      default:
        return Icons.directions_rounded;
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
      return 'End All Trips';
    }
    final String first = next.name.split(' ').first;
    return "Complete $first's Trip";
  }

  Future<void> completeNextTripLeg() async {
    final TripPassenger? next = nextIncompletePassenger;
    if (next != null) {
      markPassengerCompleted(next.id);
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

  Future<void> endTrip() async {
    final DriverOffer? anchor = tripAnchorOffer;
    if (anchor == null) return;
    isLoading = true;
    notifyListeners();
    try {
      tripSummary = await _repository.completeTrip(
        bookingReference: anchor.reference,
        passengerCount: onboardPassengers.length,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void resetTripFlow() {
    acceptedOffers = <DriverOffer>[];
    tripAnchorOffer = null;
    waitingPassengers = <TripPassenger>[];
    onboardPassengers = <TripPassenger>[];
    tripSummary = null;
    activeWaitingPassengerId = null;
    pickupPrimaryStep = 0;
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
    phoneController.dispose();
    super.dispose();
  }
}
