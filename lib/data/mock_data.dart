/// TricyKab Driver App — Mock Data
/// PRD-aligned Kabacan content for presentation mockups.

class MockDriver {
  static const String firstName = 'Mariano';
  static const String lastName = 'Ramos';
  static const String fullName = 'Mariano Ramos';
  static const String initials = 'MR';
  static const String todaName = 'Poblacion TODA';
  static const String plateNumber = 'KAB-1234';
  static const String licenseNumber = 'N12-34-567890';
  static const String phoneNumber = '+639171111111';
  static const String status = 'ONLINE';
  static const int capacity = 4;
  static const double ratingAvg = 4.8;

  // Today's stats
  static const int todayTrips = 8;
  static const String todayEarnings = '₱620';
  static const String onlineHours = '6.2h';
  static const String acceptRate = '92%';

  // Weekly
  static const String weeklyEarnings = '₱4,380';
  static const String lastWeekEarnings = '₱3,920';
  static const List<double> weeklyBarHeights = [0.35, 0.55, 0.45, 0.70, 0.85, 0.60, 0.90];
  static const List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Today'];
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
  static const int offerCountdownSeconds = 15;
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
  static const String receiptNumber = 'RCT-2026-000042';
  static const String finalFare = '₱35.00';
  static const String distance = '3.2 km';
  static const String duration = '13 min';
  static const String paymentMethod = 'CASH';
  static const int passengerCount = 1;
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
