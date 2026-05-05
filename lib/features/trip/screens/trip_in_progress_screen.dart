import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
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
      flow.markPassengerCompleted(next.id);
      setState(() {});
      return;
    }
    await flow.endTrip();
    if (!mounted) return;
    if (flow.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(flow.lastError!)));
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRouter.endTrip);
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
            onPressed: () => Navigator.of(context).pushReplacementNamed(AppRouter.home),
            child: const Text('Return Home'),
          ),
        ),
      );
    }

    return Scaffold(
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
                    _buildTripMap(),
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
    );
  }

  Widget _buildTripMap() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8E6F0), Color(0xFFD4D0E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.navigation_rounded, color: AppColors.textMuted, size: 28),
                SizedBox(height: 4),
                Text(
                  'Optimized route to drop-offs',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Positioned(
            top: 72,
            left: 88,
            child: _MapDot(color: AppColors.primary, icon: Icons.electric_rickshaw_outlined),
          ),
          Positioned(
            bottom: 38,
            right: 46,
            child: _MapDot(label: 'Maria — USM', color: AppColors.danger, icon: Icons.flag_outlined),
          ),
          Positioned(
            bottom: 28,
            left: 52,
            child: _MapDot(label: 'Jose — Nongnongan', color: AppColors.danger, icon: Icons.flag_outlined),
          ),
          Positioned(
            top: 100,
            left: 100,
            child: Transform.rotate(
              angle: 0.26,
              child: Container(
                width: 90,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Positioned(
            top: 118,
            left: 72,
            child: Transform.rotate(
              angle: -0.17,
              child: Container(
                width: 70,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
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
              padding: const EdgeInsets.all(14),
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
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: passenger.completed ? AppColors.subtleBackground : AppColors.successLight,
                      borderRadius: BorderRadius.circular(10),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(passenger.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          passenger.routeSubtitle ??
                              '${passenger.pickupAddress} → ${passenger.dropoffAddress}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        passenger.fareDisplay ?? '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      TextButton.icon(
                        onPressed: passenger.completed
                            ? null
                            : () {
                                flow.markPassengerCompleted(passenger.id);
                                setState(() {});
                              },
                        icon: Icon(
                          passenger.completed ? Icons.done_all_outlined : Icons.check_outlined,
                          size: 12,
                        ),
                        label: Text(passenger.completed ? 'Done' : 'Complete'),
                        style: TextButton.styleFrom(
                          backgroundColor: passenger.completed ? AppColors.subtleBackground : AppColors.successLight,
                          foregroundColor: passenger.completed ? AppColors.textMuted : AppColors.success,
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
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

class _MapDot extends StatelessWidget {
  const _MapDot({this.label, required this.color, required this.icon});

  final String? label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        if (label != null) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label!,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}
