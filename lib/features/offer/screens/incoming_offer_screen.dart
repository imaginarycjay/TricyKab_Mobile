import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/countdown_timer.dart';
import '../../../core/widgets/map_placeholder.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../navigation/app_router.dart';
import '../../driver_flow/domain/driver_flow_models.dart';
import '../../driver_flow/driver_flow_controller.dart';
import '../../driver_flow/driver_flow_scope.dart';

/// Booking offers carousel — parity with `mockups/driver/03-incoming-offer.html`.
class IncomingOfferScreen extends StatefulWidget {
  const IncomingOfferScreen({
    super.key,
    this.returnToAssignedPickup = false,
  });

  final bool returnToAssignedPickup;

  @override
  State<IncomingOfferScreen> createState() => _IncomingOfferScreenState();
}

class _IncomingOfferScreenState extends State<IncomingOfferScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final flow = DriverFlowScope.of(context);
      if (widget.returnToAssignedPickup) {
        flow.setReturnToAssignedPickup(true);
      }
      if (flow.offers.isEmpty) {
        await flow.loadOffers(midAssignment: widget.returnToAssignedPickup);
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleDeckComplete(DriverFlowController flow) async {
    if (!mounted) return;
    if (flow.offers.isNotEmpty) return;

    if (flow.returnToAssignedPickupAfterBatch) {
      flow.clearReturnToAssignedPickup();
      Navigator.of(context).pop();
      return;
    }

    if (flow.acceptedOffers.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed(AppRouter.assignedPickup);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    }
  }

  Future<void> _onAccept(DriverFlowController flow, DriverOffer offer) async {
    final String? err = flow.validateAccept(offer);
    if (err != null) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Cannot accept'),
          content: Text(err),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    await flow.acceptOffer(offer);
    if (_pageController.hasClients && flow.offers.isNotEmpty) {
      await _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    setState(() => _activeIndex = 0);
    await _handleDeckComplete(flow);
    if (mounted) setState(() {});
  }

  Future<void> _onDecline(DriverFlowController flow, DriverOffer offer) async {
    await flow.declineCurrentOffer(offer);
    setState(() => _activeIndex = 0);
    await _handleDeckComplete(flow);
    if (mounted) setState(() {});
  }

  Future<void> _onExpire(DriverFlowController flow, DriverOffer offer) async {
    await flow.expireOffer(offer);
    setState(() => _activeIndex = 0);
    await _handleDeckComplete(flow);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final flow = DriverFlowScope.of(context);
    final offers = flow.offers;

    if (offers.isEmpty && flow.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (offers.isEmpty) {
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

    final int acceptedCount = flow.acceptedOffers.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: const Color(0xFF1E1B4B),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEW RIDE REQUESTS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Booking Offers',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer_outlined, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '${offers.length} ${offers.length == 1 ? 'offer' : 'offers'}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                key: ValueKey<int>(offers.length),
                controller: _pageController,
                itemCount: offers.length,
                onPageChanged: (int index) => setState(() => _activeIndex = index),
                itemBuilder: (BuildContext context, int index) {
                  final DriverOffer offer = offers[index];
                  return _OfferCard(
                    offer: offer,
                    onDecline: () => _onDecline(flow, offer),
                    onAccept: () => _onAccept(flow, offer),
                    onExpire: () => _onExpire(flow, offer),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _summaryRow('Accepted', '$acceptedCount'),
                    const Divider(height: 1, color: AppColors.borderLight),
                    _summaryRow('Remaining', '${offers.length}', isLast: true),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                offers.length,
                (int i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _activeIndex == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _activeIndex == i ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(top: isLast ? 8 : 8, bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.onDecline,
    required this.onAccept,
    required this.onExpire,
  });

  final DriverOffer offer;
  final VoidCallback onDecline;
  final VoidCallback onAccept;
  final VoidCallback onExpire;

  @override
  Widget build(BuildContext context) {
    final bool isShared = offer.rideType == RideType.shared;
    final String typeLabel = isShared ? 'SHARED' : 'SPECIAL';
    final Color avatarBg = isShared ? AppColors.successLight : const Color(0xFFFCE7F3);
    final Color avatarFg = isShared ? AppColors.success : const Color(0xFF9D174D);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CountdownTimer(
                seconds: offer.countdownSeconds,
                size: 68,
                onExpired: onExpire,
              ),
              const SizedBox(height: 4),
              const Text(
                'seconds to respond',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      offer.passengerInitials,
                      style: TextStyle(fontWeight: FontWeight.w800, color: avatarFg, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      offer.passengerName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.near_me_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 2),
                  Text(
                    offer.pickupDistanceLabel,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      offer.destinationAddress,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                offer.estimatedFare,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RIDE TYPE', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        StatusBadge.rideType(typeLabel),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('EST. DURATION', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          offer.estimatedDuration,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TRIP DISTANCE', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          offer.estimatedDistance,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('PICKUP', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          offer.pickupAddress,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const MapPlaceholder(height: 110, label: 'Route preview', icon: Icons.map_outlined),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDecline,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Decline'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
