import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/info_row.dart';
import '../../driver_flow/driver_flow_scope.dart';
import '../../../navigation/app_router.dart';

/// End trip — parity with `mockups/driver/07-end-trip.html`.
class EndTripScreen extends StatefulWidget {
  const EndTripScreen({super.key});

  @override
  State<EndTripScreen> createState() => _EndTripScreenState();
}

class _EndTripScreenState extends State<EndTripScreen> {
  int _rating = 0;
  bool _ratingSubmitted = false;

  @override
  Widget build(BuildContext context) {
    final flow = DriverFlowScope.of(context);
    final summary = flow.tripSummary;
    if (summary == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed(AppRouter.home),
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
              const Text(
                'Trip Completed!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                summary.collectSubtitle,
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
                    InfoRow(label: 'Route', value: summary.routeLabel),
                    InfoRow(label: 'Duration', value: summary.duration),
                    InfoRow(label: 'Distance', value: summary.distance),
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Digital receipt sent to passenger\'s phone',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
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
                  children: [
                    const Text(
                      'Rate this passenger',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final filled = _rating > i;
                        return IconButton(
                          icon: Icon(
                            filled ? Icons.star_rounded : Icons.star_border_rounded,
                            color: filled ? AppColors.warning : AppColors.textMuted,
                            size: 32,
                          ),
                          onPressed: _ratingSubmitted ? null : () => setState(() => _rating = i + 1),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: (_rating == 0 || _ratingSubmitted)
                            ? null
                            : () {
                                setState(() => _ratingSubmitted = true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Rating endpoint deferred per PRD §15 — submitted locally only.',
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.send_outlined, size: 16),
                        label: Text(_ratingSubmitted ? 'Rating recorded locally' : 'Submit rating'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    flow.resetTripFlow();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.home,
                      (Route<dynamic> route) => false,
                    );
                  },
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: const Text('Done — Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
