import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/mock_data.dart';
import '../../../navigation/app_router.dart';

/// Trip history screen — list of past trips.
/// PRD Section 15.4 style but for driver side.
class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            showBackButton: true,
            onBack: () => Navigator.of(context).pushReplacementNamed(AppRouter.home),
          ),
          // Title bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trip History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${MockTripHistory.trips.length} trips',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: MockTripHistory.trips.length,
                  itemBuilder: (context, index) {
                    final trip = MockTripHistory.trips[index];
                    return _TripItem(
                      from: trip['from']!,
                      to: trip['to']!,
                      date: trip['date']!,
                      fare: trip['fare']!,
                      status: trip['status']!,
                      type: trip['type']!,
                    );
                  },
                ),
              ),
            ),
          ),
          BottomNav(
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) {
                Navigator.of(context).pushReplacementNamed(AppRouter.home);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TripItem extends StatelessWidget {
  final String from;
  final String to;
  final String date;
  final String fare;
  final String status;
  final String type;

  const _TripItem({
    required this.from,
    required this.to,
    required this.date,
    required this.fare,
    required this.status,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Route icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.route_outlined,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Route info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$from → $to',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusBadge.rideType(type),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Fare + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fare,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              StatusBadge.fromStatus(status),
            ],
          ),
        ],
      ),
    );
  }
}
