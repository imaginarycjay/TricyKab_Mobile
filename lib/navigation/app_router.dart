import 'package:flutter/material.dart';
import '../features/auth/screens/otp_login_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/offer/screens/incoming_offer_screen.dart';
import '../features/pickup/screens/assigned_pickup_screen.dart';
import '../features/trip/screens/trip_in_progress_screen.dart';
import '../features/trip/screens/add_passenger_screen.dart';
import '../features/complete/screens/end_trip_screen.dart';
import '../features/history/screens/trip_history_screen.dart';
import '../features/profile/screens/profile_screen.dart';

/// Named route definitions for the Driver App.
class AppRouter {
  AppRouter._();

  static const String login = '/login';
  static const String home = '/home';
  static const String incomingOffer = '/offer';
  static const String assignedPickup = '/pickup';
  static const String tripInProgress = '/trip';
  static const String addPassenger = '/trip/add-passenger';
  static const String endTrip = '/complete';
  static const String tripHistory = '/history';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const OtpLoginScreen(),
    home: (_) => const HomeScreen(),
    incomingOffer: (_) => const IncomingOfferScreen(),
    assignedPickup: (_) => const AssignedPickupScreen(),
    tripInProgress: (_) => const TripInProgressScreen(),
    addPassenger: (_) => const AddPassengerScreen(),
    endTrip: (_) => const EndTripScreen(),
    tripHistory: (_) => const TripHistoryScreen(),
    profile: (_) => const ProfileScreen(),
  };
}
