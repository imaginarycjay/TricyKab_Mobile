// TricyKab Driver App — mock data (parity with TricyKab/mockups/driver/*.html).

import '../features/driver_flow/domain/driver_flow_models.dart';

class MockDriver {
  static const String firstName = 'Mariano';
  static const String lastName = 'Ramos';
  static const String fullName = 'Mariano Ramos';
  static const String initials = 'MR';
  static const String todaName = 'Poblacion TODA';
  static const String plateNumber = 'KAB-1234';
  static const String licenseNumber = 'N12-34-567890';
  static const String phoneNumber = '+63 918 222 3333';
  static const String status = 'ONLINE';
  static const int capacity = 4;
  static const double ratingAvg = 4.8;

  static const int todayTrips = 8;
  static const String todayEarnings = '₱620';
  static const String onlineHours = '6.2h';
  static const String acceptRate = '92%';

  static const String weeklyEarnings = '₱4,380';
  static const String lastWeekEarnings = '₱3,920';
  static const List<double> weeklyBarHeights = [0.35, 0.55, 0.45, 0.70, 0.85, 0.60, 0.90];
  static const List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Today'];
}

/// `03-incoming-offer.html` — three carousel cards
class MockIncomingOffers {
  static const int countdownSeconds = 20;

  static DriverOffer mariaOffer = DriverOffer(
    id: 'offer-1',
    reference: 'BK-2026-0042',
    rideType: RideType.shared,
    passengerName: 'Maria Clara',
    passengerInitials: 'MC',
    pickupAddress: 'Kabacan Market',
    destinationAddress: 'USM Main Gate',
    pickupDistanceLabel: '1.2 km',
    estimatedFare: '₱35.00',
    estimatedDistance: '3.2 km',
    estimatedDuration: '~13 min',
    countdownSeconds: countdownSeconds,
  );

  static DriverOffer joseOffer = DriverOffer(
    id: 'offer-2',
    reference: 'BK-2026-0043',
    rideType: RideType.shared,
    passengerName: 'Jose Rizal',
    passengerInitials: 'JR',
    pickupAddress: 'Poblacion Terminal',
    destinationAddress: 'Nongnongan Brgy. Hall',
    pickupDistanceLabel: '0.8 km',
    estimatedFare: '₱45.00',
    estimatedDistance: '4.7 km',
    estimatedDuration: '~18 min',
    countdownSeconds: countdownSeconds,
  );

  static DriverOffer andresOffer = DriverOffer(
    id: 'offer-3',
    reference: 'BK-2026-0045',
    rideType: RideType.special,
    passengerName: 'Andres Bonifacio',
    passengerInitials: 'AB',
    pickupAddress: 'Osias Elementary',
    destinationAddress: 'Kabacan Bus Terminal',
    pickupDistanceLabel: '2.1 km',
    estimatedFare: '₱95.00',
    estimatedDistance: '5.8 km',
    estimatedDuration: '~22 min',
    countdownSeconds: countdownSeconds,
  );

  static List<DriverOffer> get fullBatch => <DriverOffer>[mariaOffer, joseOffer, andresOffer];

  /// Single offer when returning from assigned pickup (`sessionStorage` demo).
  static DriverOffer midAssignmentOffer = DriverOffer(
    id: 'offer-mid-1',
    reference: 'BK-2026-0048',
    rideType: RideType.shared,
    passengerName: 'Pedro Paterno',
    passengerInitials: 'PP',
    pickupAddress: 'USM Gate 2',
    destinationAddress: 'Kabacan Public Market',
    pickupDistanceLabel: '1.4 km',
    estimatedFare: '₱30.00',
    estimatedDistance: '2.7 km',
    estimatedDuration: '~11 min',
    countdownSeconds: countdownSeconds,
  );
}

/// `04-assigned-pickup.html` — static scenario + pickup notes
class MockAssignedPickup {
  static const String pickupNotes =
      'Heading to **Poblacion Terminal** to pick up Jose Rizal. Estimated arrival in **~3 min**.';

  static TripPassenger joseWaiting = TripPassenger(
    id: 'pax-jose-waiting',
    name: 'Jose Rizal',
    initials: 'JR',
    pickupAddress: 'Poblacion Terminal',
    dropoffAddress: 'Nongnongan Brgy. Hall',
    rideType: RideType.shared,
    fareDisplay: 'PHP 45',
    pickupNotes: 'Under the waiting shed, wearing a blue shirt.',
  );

  static TripPassenger mariaWaiting = TripPassenger(
    id: 'pax-maria-waiting',
    name: 'Maria Clara',
    initials: 'MC',
    pickupAddress: 'Kabacan Market',
    dropoffAddress: 'USM Main Gate',
    rideType: RideType.shared,
    fareDisplay: 'PHP 35',
    pickupNotes: 'Beside market gate waiting area.',
  );

  static TripPassenger mariaOnboard = TripPassenger(
    id: 'pax-maria-onboard',
    name: 'Maria Clara',
    initials: 'MC',
    pickupAddress: 'Kabacan Market',
    dropoffAddress: 'USM Main Gate',
    rideType: RideType.shared,
    fareDisplay: '₱35',
    routeSubtitle: 'Kabacan Market → USM Main Gate',
  );

  /// Default pick shown in HTML: Maria’s “Arrived” is active.
  static PickupLayout get staticLayout => PickupLayout(
        waiting: <TripPassenger>[joseWaiting, mariaWaiting],
        onboard: <TripPassenger>[mariaOnboard],
        defaultSelectedWaitingId: mariaWaiting.id,
      );
}

/// `05-trip-in-progress.html`
class MockTripInProgress {
  static const String totalRemainingKm = '2.8 km';
  static const String tripEarningsDisplay = '₱80.00';

  static List<TripPassenger> get onboardOrder => <TripPassenger>[
        TripPassenger(
          id: 'pax-maria-trip',
          name: 'Maria Clara',
          initials: 'MC',
          pickupAddress: 'Kabacan Market',
          dropoffAddress: 'USM Main Gate',
          routeSubtitle: 'Kabacan Market → USM Main Gate',
          fareDisplay: '₱35',
        ),
        TripPassenger(
          id: 'pax-jose-trip',
          name: 'Jose Rizal',
          initials: 'JR',
          pickupAddress: 'Poblacion Terminal',
          dropoffAddress: 'Nongnongan Brgy. Hall',
          routeSubtitle: 'Poblacion Terminal → Nongnongan Brgy. Hall',
          fareDisplay: '₱45',
        ),
      ];
}

/// `06-add-passenger.html` — capacity demo uses Maria as existing onboard
class MockAddPassenger {
  static TripPassenger sampleOnboard = TripPassenger(
    id: 'pax-maria-add',
    name: 'Maria Clara',
    initials: 'MC',
    pickupAddress: 'Kabacan Market',
    dropoffAddress: 'USM Main Gate',
    routeSubtitle: 'Market → USM',
  );
}

/// `07-end-trip.html`
class MockEndTrip {
  static const String bookingRef = 'BK-2026-0030';
  static const String receipt = 'RCT-2026-000042';
  static const String finalFare = '₱35.00';
  static const String routeShort = 'Market → USM';
  static const String duration = '13 min 23 sec';
  static const String distance = '3.2 km';
  static const int passengerCount = 1;
}

class MockPassenger {
  static const String name = 'Maria Santos';
  static const String initials = 'MS';
  static const String phoneNumber = '+639179876543';
}

class MockBooking {
  static const String reference = 'BK-2026-0042';
  static const String rideType = 'SHARED';
  static const String pickupAddress = 'Kabacan Public Market';
  static const String pickupNotes = 'Near south gate';
  static const double pickupLat = 7.1234567;
  static const double pickupLng = 124.1234567;
  static const String destinationAddress = 'University of Southern Mindanao';
  static const double destLat = 7.2234567;
  static const double destLng = 124.2234567;
  static const String estimatedFare = '₱35.00';
  static const String estimatedDistance = '3.2 km';
  static const String estimatedDuration = '13 min';
  static const String eta = '4 min';
  static const int offerCountdownSeconds = 20;
}

class MockSpecialBooking {
  static const String reference = 'BK-2026-0045';
  static const String rideType = 'SPECIAL';
  static const String pickupAddress = 'Osias, Kabacan';
  static const String destinationAddress = 'Nongnongan, Kabacan';
  static const String suggestedFare = '₱95.00';
  static const String proposedFare = '₱80.00';
  static const String agreedFare = '₱85.00';
  static const String estimatedDistance = '5.8 km';
}

class MockTrip {
  static const String receiptNumber = MockEndTrip.receipt;
  static const String finalFare = MockEndTrip.finalFare;
  static const String distance = MockEndTrip.distance;
  static const String duration = MockEndTrip.duration;
  static const String paymentMethod = 'CASH';
  static const int passengerCount = MockEndTrip.passengerCount;
  static const String startedAt = '2:20 PM';
  static const String endedAt = '2:33 PM';
}

class MockTripHistory {
  static final List<Map<String, String>> trips = [
    {
      'from': 'Kabacan Public Market',
      'to': 'USM Main Campus',
      'date': 'Apr 19, 2026 · 2:20 PM',
      'fare': '₱35.00',
      'status': 'COMPLETED',
      'type': 'SHARED',
      'ref': 'BK-2026-0042',
    },
    {
      'from': 'Osias, Kabacan',
      'to': 'Nongnongan, Kabacan',
      'date': 'Apr 19, 2026 · 1:05 PM',
      'fare': '₱85.00',
      'status': 'COMPLETED',
      'type': 'SPECIAL',
      'ref': 'BK-2026-0041',
    },
    {
      'from': 'Poblacion Terminal',
      'to': 'Kabacan National High School',
      'date': 'Apr 19, 2026 · 11:30 AM',
      'fare': '₱25.00',
      'status': 'COMPLETED',
      'type': 'SHARED',
      'ref': 'BK-2026-0040',
    },
    {
      'from': 'USM Gate 2',
      'to': 'Kabacan Public Market',
      'date': 'Apr 19, 2026 · 10:15 AM',
      'fare': '₱35.00',
      'status': 'COMPLETED',
      'type': 'SHARED',
      'ref': 'BK-2026-0039',
    },
    {
      'from': 'Nongnongan, Kabacan',
      'to': 'Poblacion Terminal',
      'date': 'Apr 19, 2026 · 9:00 AM',
      'fare': '₱45.00',
      'status': 'COMPLETED',
      'type': 'SHARED',
      'ref': 'BK-2026-0038',
    },
    {
      'from': 'Kabacan Bus Terminal',
      'to': 'Osias, Kabacan',
      'date': 'Apr 18, 2026 · 4:45 PM',
      'fare': '₱90.00',
      'status': 'COMPLETED',
      'type': 'SPECIAL',
      'ref': 'BK-2026-0035',
    },
    {
      'from': 'Poblacion Terminal',
      'to': 'USM Main Campus',
      'date': 'Apr 18, 2026 · 3:10 PM',
      'fare': '₱35.00',
      'status': 'CANCELLED_BY_PASSENGER',
      'type': 'SHARED',
      'ref': 'BK-2026-0034',
    },
    {
      'from': 'Kabacan Public Market',
      'to': 'Nongnongan, Kabacan',
      'date': 'Apr 18, 2026 · 1:20 PM',
      'fare': '₱45.00',
      'status': 'COMPLETED',
      'type': 'SHARED',
      'ref': 'BK-2026-0033',
    },
  ];
}
