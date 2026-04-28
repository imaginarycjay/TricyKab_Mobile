import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/map_placeholder.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/driver_card.dart';
import '../../../data/mock_data.dart';
import '../../../navigation/app_router.dart';

/// Assigned pickup screen — driver navigates to passenger.
/// PRD Section 16.3: Pickup and Start flow.
class AssignedPickupScreen extends StatelessWidget {
  const AssignedPickupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            showBackButton: true,
            onBack: () => Navigator.of(context).pushReplacementNamed(AppRouter.home),
            trailing: StatusBadge.fromStatus('DRIVER_ASSIGNED'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map
                  const MapPlaceholder(
                    height: 200,
                    label: 'Navigate to Pickup',
                    icon: Icons.navigation_outlined,
                  ),
                  const SizedBox(height: 12),

                  // Passenger card
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PASSENGER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ProfileCard(
                              initials: MockPassenger.initials,
                              name: MockPassenger.name,
                              meta: MockPassenger.phoneNumber,
                              avatarColor: AppColors.info,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.phone_outlined, size: 16),
                                label: const Text('Call'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.message_outlined, size: 16),
                                label: const Text('SMS'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Trip details
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
                      children: [
                        InfoRow(label: 'Booking', value: MockBooking.reference),
                        InfoRow(
                          label: 'Ride Type',
                          value: '',
                          trailing: StatusBadge.rideType(MockBooking.rideType),
                        ),
                        InfoRow(label: 'Pickup', value: MockBooking.pickupAddress),
                        InfoRow(label: 'Notes', value: MockBooking.pickupNotes),
                        InfoRow(label: 'Destination', value: MockBooking.destinationAddress),
                        InfoRow(
                          label: 'ETA to Pickup',
                          value: MockBooking.eta,
                          valueColor: AppColors.primary,
                          showBorder: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Arrive CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed(AppRouter.tripInProgress);
                      },
                      icon: const Icon(Icons.place_outlined, size: 20),
                      label: const Text('I\'ve Arrived'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
