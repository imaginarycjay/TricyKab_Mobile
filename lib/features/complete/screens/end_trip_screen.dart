import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/info_row.dart';
import '../../driver_flow/driver_flow_scope.dart';
import '../../../navigation/app_router.dart';

/// End trip / per-passenger receipt — parity with `mockups/driver/07-end-trip.html`.
///
/// Supports two modes:
///  1. **Per-passenger receipt** — shown after completing a single passenger mid-trip.
///     A "Continue Trip" button returns the driver to trip-in-progress if more
///     passengers remain.
///  2. **Final trip receipt** — shown after the last passenger is completed
///     and the backend trip has been ended.  "Done — Back to Home" resets flow.
class EndTripScreen extends StatefulWidget {
  const EndTripScreen({super.key});

  @override
  State<EndTripScreen> createState() => _EndTripScreenState();
}

class _EndTripScreenState extends State<EndTripScreen> {
  @override
  Widget build(BuildContext context) {
    final flow = DriverFlowScope.of(context);

    // Prefer per-passenger receipt over the global tripSummary
    final summary = flow.passengerTripSummary ?? flow.tripSummary;
    final bool hasMore = flow.hasRemainingPassengers;

    if (summary == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: ElevatedButton(
            onPressed: () => AppRouter.navigateHome(context),
            child: const Text('Back to Home'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.paid_rounded, color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 12),
              Text(
                hasMore ? "${summary.passengerName}'s Trip Completed!" : 'Trip Completed!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                summary.collectSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'COLLECT FROM PASSENGER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.06 * 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary.finalFare,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatusBadge.cash(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Summary',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    InfoRow(label: 'Reference', value: summary.bookingReference),
                    InfoRow(label: 'Passenger', value: summary.passengerName),
                    InfoRow(label: 'Route', value: summary.routeLabel),
                    InfoRow(label: 'Duration', value: summary.duration),
                    InfoRow(label: 'Distance', value: summary.distance),
                    if (!hasMore)
                      InfoRow(label: 'Passengers', value: '${summary.passengerCount}'),
                    InfoRow(
                      label: 'Receipt',
                      value: summary.receiptNumber,
                      valueColor: AppColors.primary,
                      showBorder: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.subtleBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasMore ? Icons.info_outline : Icons.receipt_long_outlined,
                      color: hasMore ? AppColors.primary : AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasMore
                            ? 'You have ${flow.onboardPassengers.where((p) => !p.completed).length} more passenger(s) to complete'
                            : 'Digital receipt sent to passenger\'s phone',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: hasMore ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: hasMore ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!hasMore) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.subtleBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star_outline_rounded, color: AppColors.warning, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Passengers rate you from their trip receipt after payment. '
                          'Driver-to-passenger ratings are not part of the MVP.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ---- Action Buttons ----
              if (hasMore) ...[
                // Continue trip — go back to trip in progress screen
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      flow.clearPassengerReceipt();
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          settings: const RouteSettings(name: AppRouter.tripInProgress),
                          pageBuilder: (c, _, __) => AppRouter.routes[AppRouter.tripInProgress]!(c),
                          transitionsBuilder: (_, animation, __, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                              child: FadeTransition(
                                opacity: CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.6)),
                                child: child,
                              ),
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Continue Trip — Next Passenger'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ] else ...[
                // Final — done, back to home
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      flow.clearPassengerReceipt();
                      flow.resetTripFlow();
                      AppRouter.navigateHome(context);
                    },
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: const Text('Done — Back to Home'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
