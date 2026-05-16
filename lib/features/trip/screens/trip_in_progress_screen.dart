import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/live_map.dart';
import '../../../data/mock_data.dart';
import '../../../navigation/app_router.dart';
import '../../driver_flow/domain/driver_flow_models.dart';
import '../../driver_flow/driver_flow_controller.dart';
import '../../driver_flow/driver_flow_scope.dart';

/// Trip in progress — parity with `mockups/driver/05-trip-in-progress.html`.
class TripInProgressScreen extends StatefulWidget {
  const TripInProgressScreen({super.key});

  @override
  State<TripInProgressScreen> createState() => _TripInProgressScreenState();
}

class _TripInProgressScreenState extends State<TripInProgressScreen> {
  Timer? _elapsedTimer;
  int _elapsedSeconds = 262; // 4:22
  bool _gpsStarted = false;

  @override
  void initState() {
    super.initState();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gpsStarted) return;
    _gpsStarted = true;
    final flow = DriverFlowScope.of(context);
    flow.startLocationPing();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    DriverFlowScope.maybeOf(context)?.stopLocationPing();
    super.dispose();
  }

  String _formatElapsed(int totalSeconds) {
    final int m = totalSeconds ~/ 60;
    final int s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _onPrimary(DriverFlowController flow) async {
    final next = flow.nextIncompletePassenger;
    if (next != null) {
      await _completePassenger(flow, next.id);
      return;
    }
    // All passengers already done — end the trip fully
    await flow.endTrip();
    if (!mounted) return;
    if (flow.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(flow.lastError!)));
      return;
    }
    _navigateToEndTrip();
  }

  Future<void> _completePassenger(DriverFlowController flow, String passengerId) async {
    final success = await flow.completePassengerTrip(passengerId);
    if (!mounted) return;
    if (!success) {
      if (flow.lastError != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(flow.lastError!)));
      }
      return;
    }
    _navigateToEndTrip();
  }

  void _navigateToEndTrip() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        settings: const RouteSettings(name: AppRouter.endTrip),
        pageBuilder: (c, _, __) => AppRouter.routes[AppRouter.endTrip]!(c),
        transitionsBuilder: (_, animation, __, child) {
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
      ),
    );
  }

  Future<void> _showSosDialog(BuildContext context) async {
    final action = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Driver SOS'),
            ],
          ),
          content: const Text(
            'Pilot uses direct dial — driver-side SOS API deferred per PRD §22.\n\n'
            'Choose an emergency contact:',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.local_police_outlined),
              onPressed: () => Navigator.pop(ctx, '911'),
              label: const Text('Police 911'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
              icon: const Icon(Icons.support_agent),
              onPressed: () => Navigator.pop(ctx, 'TODA'),
              label: const Text('TODA dispatch'),
            ),
          ],
        );
      },
    );
    if (action == null || !context.mounted) return;
    final number = action == '911' ? '911' : '+639180000000';
    final uri = Uri(scheme: 'tel', path: number);
    try {
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open dialer for $number')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dialer unavailable. Call $number manually.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = DriverFlowScope.of(context);

    if (flow.tripAnchorOffer == null && flow.onboardPassengers.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: ElevatedButton(
            onPressed: () => AppRouter.navigateHome(context),
            child: const Text('Return Home'),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Leave active trip?'),
            content: const Text(
              'You have a trip in progress. Going back to home will not end it \u2014 you can resume from the home screen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          AppRouter.navigateHome(context);
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.danger,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.shield_outlined),
        label: const Text('SOS'),
        onPressed: () => _showSosDialog(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              color: AppColors.success,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Task',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          flow.tripHeaderTask,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group_outlined, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${flow.onboardPassengers.length} ONBOARD',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  children: [
                    _buildTripMap(flow),
                    const SizedBox(height: 12),
                    _buildOnboardSection(flow),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Text(
                                    _formatElapsed(_elapsedSeconds),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('Elapsed', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 56,
                            child: VerticalDivider(width: 1, thickness: 1, color: AppColors.borderLight),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Text(
                                    MockTripInProgress.totalRemainingKm,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Total Remaining',
                                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pushNamed(AppRouter.addPassenger),
                            icon: const Icon(Icons.person_add_outlined, size: 18),
                            label: const Text('Add Passenger'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _onPrimary(flow),
                            icon: Icon(
                              flow.nextIncompletePassenger == null ? Icons.stop_circle_outlined : Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: Text(flow.tripPrimaryLabel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: flow.nextIncompletePassenger == null
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF3B82F6),
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Trip Earnings',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                          Text(
                            MockTripInProgress.tripEarningsDisplay,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTripMap(DriverFlowController flow) {
    final offer = flow.tripAnchorOffer;
    return LiveMap(
      height: 210,
      pickupLat: offer?.pickupLatitude ?? 7.1083,
      pickupLng: offer?.pickupLongitude ?? 124.8295,
      destinationLat: offer?.destinationLatitude ?? 7.1117,
      destinationLng: offer?.destinationLongitude ?? 124.8419,
      showRoute: true,
      showFullscreenButton: true,   // PRD §5A — fullscreen map toggle
      driverHasArrived: true,       // PRD §5B — route driver → destination in-trip
      // Use real GPS from controller — updated every 10 s via startLocationPing.
      // Falls back to a position between pickup and destination when unavailable.
      driverLat: flow.lastLatitude ?? ((offer?.pickupLatitude ?? 7.1083) + (offer?.destinationLatitude ?? 7.1117)) / 2,
      driverLng: flow.lastLongitude ?? ((offer?.pickupLongitude ?? 124.8295) + (offer?.destinationLongitude ?? 124.8419)) / 2,
    );
  }

  Widget _buildOnboardSection(DriverFlowController flow) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Passengers Onboard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                '${flow.onboardPassengers.length} / ${flow.capacity}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (flow.onboardPassengers.length / flow.capacity).clamp(0.0, 1.0),
              backgroundColor: AppColors.subtleBackground,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
          const SizedBox(height: 12),
          ...flow.onboardPassengers.map(
            (TripPassenger passenger) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: passenger.completed ? AppColors.textMuted : AppColors.success,
                    width: 4,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: passenger.completed ? AppColors.subtleBackground : AppColors.successLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      passenger.initials ??
                          passenger.name.split(' ').map((String e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: passenger.completed ? AppColors.textMuted : AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passenger.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          passenger.routeSubtitle ??
                              '${passenger.pickupAddress} \u2192 ${passenger.dropoffAddress}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        passenger.fareDisplay ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: passenger.completed
                            ? null
                            : () => _completePassenger(flow, passenger.id),
                        icon: Icon(
                          passenger.completed ? Icons.done_all_outlined : Icons.check_outlined,
                          size: 12,
                        ),
                        label: Text(passenger.completed ? 'Done' : 'Complete'),
                        style: TextButton.styleFrom(
                          backgroundColor: passenger.completed ? AppColors.subtleBackground : AppColors.successLight,
                          foregroundColor: passenger.completed ? AppColors.textMuted : AppColors.success,
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


