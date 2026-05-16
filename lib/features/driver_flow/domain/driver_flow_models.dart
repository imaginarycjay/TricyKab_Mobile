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
    this.bookingId,
    this.tripId,
    this.candidateId,
    this.dispatchAttemptId,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.estimatedFareAmount,
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
  final int? bookingId;
  final int? tripId;
  final int? candidateId;
  final int? dispatchAttemptId;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  /// Server raw fare e.g. "25.00" for payment record.
  final String? estimatedFareAmount;

  DriverOffer copyWith({
    String? id,
    String? reference,
    RideType? rideType,
    String? passengerName,
    String? passengerInitials,
    String? pickupAddress,
    String? destinationAddress,
    String? pickupDistanceLabel,
    String? estimatedFare,
    String? estimatedDistance,
    String? estimatedDuration,
    int? countdownSeconds,
    int? bookingId,
    int? tripId,
    int? candidateId,
    int? dispatchAttemptId,
    double? pickupLatitude,
    double? pickupLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
    String? estimatedFareAmount,
  }) {
    return DriverOffer(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      rideType: rideType ?? this.rideType,
      passengerName: passengerName ?? this.passengerName,
      passengerInitials: passengerInitials ?? this.passengerInitials,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      pickupDistanceLabel: pickupDistanceLabel ?? this.pickupDistanceLabel,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      bookingId: bookingId ?? this.bookingId,
      tripId: tripId ?? this.tripId,
      candidateId: candidateId ?? this.candidateId,
      dispatchAttemptId: dispatchAttemptId ?? this.dispatchAttemptId,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      estimatedFareAmount: estimatedFareAmount ?? this.estimatedFareAmount,
    );
  }
}

class TripPassenger {
  TripPassenger({
    required this.id,
    required this.name,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.bookingId,
    this.initials,
    this.rideType,
    this.fareDisplay,
    this.pickupNotes,
    this.routeSubtitle,
    this.completed = false,
  });

  final String id;
  /// Server booking id when this row maps to the dispatched booking (walk-ins use null).
  final int? bookingId;
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
    int? bookingId,
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
      bookingId: bookingId ?? this.bookingId,
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

/// Driver-side booking row used by the trip history list and detail screen.
/// Mirrors the JSON returned by `GET /drivers/me/bookings`.
class DriverHistoryBooking {
  DriverHistoryBooking({
    required this.id,
    required this.reference,
    required this.status,
    required this.rideType,
    required this.pickupAddress,
    required this.destinationAddress,
    this.passengerName,
    this.passengerInitials,
    this.fareAmount,
    this.estimatedDistanceMeters,
    this.estimatedDurationSeconds,
    this.createdAtIso,
    this.acceptedAtIso,
    this.cancelledAtIso,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
  });

  final int id;
  final String reference;
  final String status;
  final RideType rideType;
  final String pickupAddress;
  final String destinationAddress;
  final String? passengerName;
  final String? passengerInitials;
  final String? fareAmount;
  final int? estimatedDistanceMeters;
  final int? estimatedDurationSeconds;
  final String? createdAtIso;
  final String? acceptedAtIso;
  final String? cancelledAtIso;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;

  String get statusLabel => status.toUpperCase().replaceAll('_', ' ');

  bool get isActive {
    switch (status.toUpperCase()) {
      case 'DRIVER_ASSIGNED':
      case 'DRIVER_ON_THE_WAY':
      case 'DRIVER_ARRIVED':
      case 'TRIP_IN_PROGRESS':
        return true;
      default:
        return false;
    }
  }

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  bool get isCancelled => status.toUpperCase().startsWith('CANCELLED') ||
      status.toUpperCase().startsWith('NO_SHOW');

  bool get isScheduled => status.toUpperCase() == 'SCHEDULED';

  String get fareDisplay {
    if (fareAmount == null || fareAmount!.isEmpty) return 'PHP —';
    return 'PHP $fareAmount';
  }

  String get distanceLabel {
    final m = estimatedDistanceMeters;
    if (m == null) return '—';
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)} km';
    return '$m m';
  }

  String get durationLabel {
    final s = estimatedDurationSeconds;
    if (s == null) return '—';
    if (s >= 60) return '~${(s / 60).round()} min';
    return '${s}s';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference': reference,
        'status': status,
        'ride_type': rideType == RideType.special ? 'SPECIAL' : 'SHARED',
        'pickup_address': pickupAddress,
        'destination_address': destinationAddress,
        'passenger_name': passengerName,
        'passenger_initials': passengerInitials,
        'fare_amount': fareAmount,
        'estimated_distance_meters': estimatedDistanceMeters,
        'estimated_duration_seconds': estimatedDurationSeconds,
        'created_at': createdAtIso,
        'accepted_at': acceptedAtIso,
        'cancelled_at': cancelledAtIso,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'destination_lat': destinationLat,
        'destination_lng': destinationLng,
      };

  static DriverHistoryBooking fromJson(Map<String, dynamic> json) {
    final rideRaw = '${json['ride_type'] ?? 'SHARED'}'.toUpperCase();
    return DriverHistoryBooking(
      id: (json['id'] as num).toInt(),
      reference: '${json['reference'] ?? ''}',
      status: '${json['status'] ?? ''}',
      rideType: rideRaw == 'SPECIAL' ? RideType.special : RideType.shared,
      pickupAddress: '${json['pickup_address'] ?? ''}',
      destinationAddress: '${json['destination_address'] ?? ''}',
      passengerName: json['passenger_name'] as String?,
      passengerInitials: json['passenger_initials'] as String?,
      fareAmount: json['fare_amount'] as String?,
      estimatedDistanceMeters: (json['estimated_distance_meters'] as num?)?.toInt(),
      estimatedDurationSeconds: (json['estimated_duration_seconds'] as num?)?.toInt(),
      createdAtIso: json['created_at'] as String?,
      acceptedAtIso: json['accepted_at'] as String?,
      cancelledAtIso: json['cancelled_at'] as String?,
      pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
      destinationLat: (json['destination_lat'] as num?)?.toDouble(),
      destinationLng: (json['destination_lng'] as num?)?.toDouble(),
    );
  }
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

class DriverMeProfile {
  const DriverMeProfile({
    required this.driverId,
    required this.fullName,
    required this.initials,
    this.phone,
    this.licenseNumber,
    this.rating,
    this.todaName,
    this.tricycleBodyNumber,
    this.tricyclePlateNumber,
    this.tricycleCapacity,
  });

  final int driverId;
  final String fullName;
  final String initials;
  final String? phone;
  final String? licenseNumber;
  final double? rating;
  final String? todaName;
  final String? tricycleBodyNumber;
  final String? tricyclePlateNumber;
  final int? tricycleCapacity;

  String get meta {
    final parts = <String>[];
    if ((todaName ?? '').isNotEmpty) parts.add(todaName!);
    final plate = (tricyclePlateNumber ?? '').trim();
    if (plate.isNotEmpty) parts.add(plate);
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}
