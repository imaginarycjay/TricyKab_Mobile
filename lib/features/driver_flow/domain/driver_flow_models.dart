enum RideType { shared, special }

/// Single incoming booking offer (mockup card).
class DriverOffer {
  DriverOffer({
    required this.id,
    required this.reference,
    required this.rideType,
    required this.passengerName,
    required this.passengerInitials,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupDistanceLabel,
    required this.estimatedFare,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.countdownSeconds,
  });

  final String id;
  final String reference;
  final RideType rideType;
  final String passengerName;
  final String passengerInitials;
  final String pickupAddress;
  final String destinationAddress;
  final String pickupDistanceLabel;
  final String estimatedFare;
  final String estimatedDistance;
  final String estimatedDuration;
  final int countdownSeconds;
}

class TripPassenger {
  TripPassenger({
    required this.id,
    required this.name,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.initials,
    this.rideType,
    this.fareDisplay,
    this.pickupNotes,
    this.routeSubtitle,
    this.completed = false,
  });

  final String id;
  final String name;
  final String pickupAddress;
  final String dropoffAddress;
  final String? initials;
  final RideType? rideType;
  final String? fareDisplay;
  final String? pickupNotes;
  /// e.g. "Kabacan Market → USM Main Gate" for onboard rows
  final String? routeSubtitle;
  final bool completed;

  TripPassenger copyWith({
    String? id,
    String? name,
    String? pickupAddress,
    String? dropoffAddress,
    String? initials,
    RideType? rideType,
    String? fareDisplay,
    String? pickupNotes,
    String? routeSubtitle,
    bool? completed,
  }) {
    return TripPassenger(
      id: id ?? this.id,
      name: name ?? this.name,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      initials: initials ?? this.initials,
      rideType: rideType ?? this.rideType,
      fareDisplay: fareDisplay ?? this.fareDisplay,
      pickupNotes: pickupNotes ?? this.pickupNotes,
      routeSubtitle: routeSubtitle ?? this.routeSubtitle,
      completed: completed ?? this.completed,
    );
  }
}

class PickupLayout {
  PickupLayout({
    required this.waiting,
    required this.onboard,
    this.defaultSelectedWaitingId,
  });

  final List<TripPassenger> waiting;
  final List<TripPassenger> onboard;
  final String? defaultSelectedWaitingId;
}

class DriverTripSummary {
  DriverTripSummary({
    required this.bookingReference,
    required this.receiptNumber,
    required this.finalFare,
    required this.distance,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.passengerName,
    required this.routeLabel,
    required this.passengerCount,
    this.collectSubtitle = 'Collect cash payment from passenger',
  });

  final String bookingReference;
  final String receiptNumber;
  final String finalFare;
  final String distance;
  final String duration;
  final String startTime;
  final String endTime;
  final String passengerName;
  final String routeLabel;
  final int passengerCount;
  final String collectSubtitle;
}
