import 'package:flutter/material.dart';
import '../features/auth/screens/otp_login_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/offer/screens/incoming_offer_screen.dart';
import '../features/pickup/screens/assigned_pickup_screen.dart';
import '../features/trip/screens/trip_in_progress_screen.dart';
import '../features/trip/screens/add_passenger_screen.dart';
import '../features/complete/screens/end_trip_screen.dart';
import '../features/history/screens/trip_history_screen.dart';
import '../features/history/screens/booking_detail_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/earnings/screens/earnings_screen.dart';
import '../features/driver_flow/driver_flow_controller.dart';

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
  static const String bookingDetail = '/history/detail';
  static const String profile = '/profile';
  static const String earnings = '/earnings';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const OtpLoginScreen(),
    home: (_) => const HomeScreen(),
    incomingOffer: (BuildContext context) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      return IncomingOfferScreen(returnToAssignedPickup: args == true);
    },
    assignedPickup: (_) => const AssignedPickupScreen(),
    tripInProgress: (_) => const TripInProgressScreen(),
    addPassenger: (_) => const AddPassengerScreen(),
    endTrip: (_) => const EndTripScreen(),
    tripHistory: (_) => const TripHistoryScreen(),
    bookingDetail: (BuildContext context) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      final id = args is int ? args : 0;
      return BookingDetailScreen(bookingId: id);
    },
    profile: (_) => const ProfileScreen(),
    earnings: (_) => const EarningsScreen(),
  };

  // ---------------------------------------------------------------------------
  // Context-aware navigation helpers
  // ---------------------------------------------------------------------------

  static Future<T?> navigateTab<T>(
    BuildContext context, {
    required int fromIndex,
    required int toIndex,
    required String routeName,
    Object? arguments,
    bool replace = true,
  }) {
    final builder = routes[routeName];
    if (builder == null) {
      return replace
          ? Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments)
          : Navigator.of(context).pushNamed(routeName, arguments: arguments);
    }

    final begin = toIndex > fromIndex ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
    final route = PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName, arguments: arguments),
      pageBuilder: (context, _, __) => builder(context),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: begin, end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
    );

    return replace ? Navigator.of(context).pushReplacement(route) : Navigator.of(context).push(route);
  }

  /// Forward navigation (offer → pickup → trip → complete).
  /// Slides the new screen in from the right.
  static Future<T?> navigateForward<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) {
    final builder = routes[routeName];
    if (builder == null) {
      return replace
          ? Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments)
          : Navigator.of(context).pushNamed(routeName, arguments: arguments);
    }
    final route = PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName, arguments: arguments),
      pageBuilder: (context, _, __) => builder(context),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.6)),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 280),
    );
    return replace
        ? Navigator.of(context).pushReplacement(route)
        : Navigator.of(context).push(route);
  }

  /// Navigate to home — fade transition, removes all previous routes.
  static Future<T?> navigateHome<T>(BuildContext context) {
    final route = PageRouteBuilder<T>(
      settings: const RouteSettings(name: home),
      pageBuilder: (context, _, __) => const HomeScreen(),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
    return Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
  }

  /// Modal overlay (e.g. pickup → offer mid-assignment).
  /// Slides the new screen in from the bottom.
  static Future<T?> navigateModal<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    final builder = routes[routeName];
    if (builder == null) {
      return Navigator.of(context).pushNamed(routeName, arguments: arguments);
    }
    final route = PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName, arguments: arguments),
      pageBuilder: (context, _, __) => builder(context),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 280),
    );
    return Navigator.of(context).push(route);
  }

  /// Resume the active trip by navigating to the correct screen based on phase.
  static void resumeActiveTrip(BuildContext context, DriverPhase phase) {
    switch (phase) {
      case DriverPhase.assigned:
      case DriverPhase.onTheWay:
      case DriverPhase.arrived:
        navigateForward(context, assignedPickup, replace: true);
        break;
      case DriverPhase.inProgress:
        navigateForward(context, tripInProgress, replace: true);
        break;
      case DriverPhase.completed:
        navigateForward(context, endTrip, replace: true);
        break;
      case DriverPhase.waitingOffers:
        break; // Already home, nothing to resume.
    }
  }
}
