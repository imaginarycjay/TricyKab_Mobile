import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/countdown_timer.dart';
import '../../../core/widgets/map_placeholder.dart';
import '../../../core/widgets/info_row.dart';
import '../../../data/mock_data.dart';
import '../../../navigation/app_router.dart';

/// Incoming booking offer screen using a swipable card interface.
/// PRD Section 16.2: Offer handling, Section 12.5: 15s offer TTL.
class IncomingOfferScreen extends StatefulWidget {
  const IncomingOfferScreen({super.key});

  @override
  State<IncomingOfferScreen> createState() => _IncomingOfferScreenState();
}

class _IncomingOfferScreenState extends State<IncomingOfferScreen> {
  List<Map<String, dynamic>> offers = List.from(MockIncomingOffers.offers);

  void _onDismissed(DismissDirection direction) {
    if (direction == DismissDirection.endToStart) {
      // Reject
    } else {
      // Accept
      Navigator.of(context).pushReplacementNamed(AppRouter.assignedPickup);
      return;
    }

    setState(() {
      offers.removeLast();
    });

    if (offers.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasOffers = offers.isNotEmpty;
    final topOffer = hasOffers ? offers.last : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            showBackButton: true,
            trailing: topOffer != null ? StatusBadge.rideType(topOffer['rideType']) : null,
          ),
          Expanded(
            child: !hasOffers
                ? const Center(child: Text("No more offers"))
                : Stack(
                    children: [
                      // Render cards from bottom to top of stack
                      for (int i = 0; i < offers.length; i++)
                        _buildCard(offers[i], i == offers.length - 1),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> offer, bool isTop) {
    final cardWidget = Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Countdown + title
            Container(
              padding: const EdgeInsets.all(24),
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
                  Text(
                    'New Ride Request — ${offer['passengerName']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Swipe Right to Accept, Left to Decline',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isTop)
                    CountdownTimer(
                      key: ValueKey(offer['id']),
                      seconds: offer['offerCountdownSeconds'],
                      onExpired: () {
                        if (mounted) {
                          _onDismissed(DismissDirection.endToStart);
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Route card
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
                  // Pickup
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBackground, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PICKUP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              offer['pickupAddress'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Connector line
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      width: 2,
                      height: 20,
                      color: AppColors.border,
                    ),
                  ),
                  // Destination
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBackground, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.danger.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DESTINATION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              offer['destinationAddress'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Map
            const MapPlaceholder(
              height: 160,
              label: 'Route Preview',
              icon: Icons.route_outlined,
            ),
            const SizedBox(height: 12),

            // Details
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
                  InfoRow(
                    label: 'Estimated Fare',
                    value: offer['estimatedFare'],
                    valueColor: AppColors.primary,
                  ),
                  InfoRow(
                    label: 'Distance',
                    value: offer['estimatedDistance'],
                  ),
                  InfoRow(
                    label: 'Duration',
                    value: offer['estimatedDuration'],
                  ),
                  InfoRow(
                    label: 'Ride Type',
                    value: '',
                    showBorder: false,
                    trailing: StatusBadge.rideType(offer['rideType']),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Helpful text
            const Text(
               'Swipe Card',
               style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold)
            )
          ],
        ),
      ),
    );

    if (!isTop) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
        child: cardWidget,
      );
    }

    return Dismissible(
      key: ValueKey(offer['id']),
      onDismissed: _onDismissed,
      background: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(16)
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.check_rounded, color: Colors.white, size: 48),
             Text('ACCEPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]
        ),
      ),
      secondaryBackground: Container(
         margin: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: AppColors.danger,
           borderRadius: BorderRadius.circular(16)
         ),
         alignment: Alignment.centerRight,
         padding: const EdgeInsets.symmetric(horizontal: 32),
         child: const Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
              Icon(Icons.close_rounded, color: Colors.white, size: 48),
              Text('REJECT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
           ]
         ),
       ),
      child: cardWidget,
    );
  }
}
