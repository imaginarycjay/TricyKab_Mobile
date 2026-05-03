import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/info_row.dart';
import '../../driver_flow/domain/driver_flow_models.dart';
import '../../driver_flow/driver_flow_scope.dart';
import '../../../navigation/app_router.dart';

/// Assigned pickup — parity with `mockups/driver/04-assigned-pickup.html`.
class AssignedPickupScreen extends StatefulWidget {
  const AssignedPickupScreen({super.key});

  @override
  State<AssignedPickupScreen> createState() => _AssignedPickupScreenState();
}

class _AssignedPickupScreenState extends State<AssignedPickupScreen> {
  final Set<String> _expandedPassengers = <String>{};

  void _togglePassengerDetails(String passengerKey) {
    setState(() {
      if (_expandedPassengers.contains(passengerKey)) {
        _expandedPassengers.remove(passengerKey);
      } else {
        _expandedPassengers.add(passengerKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final flow = DriverFlowScope.of(context);

    if (flow.tripAnchorOffer == null &&
        flow.waitingPassengers.isEmpty &&
        flow.onboardPassengers.isEmpty) {
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

    final int paxCount = flow.waitingPassengers.length + flow.onboardPassengers.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
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
                          flow.pickupHeaderTask,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group_outlined, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '$paxCount PASSENGERS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (flow.showIncomingOfferBanner)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, color: Color(0xFF0369A1)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '1 incoming offer waiting',
                              style: TextStyle(
                                color: Color(0xFF0369A1),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              flow.openIncomingOffersFromPickup();
                              Navigator.of(context).pushNamed(
                                AppRouter.incomingOffer,
                                arguments: true,
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(88, 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Handle Now'),
                          ),
                        ],
                      ),
                    ),
                  if (flow.showIncomingOfferBanner) const SizedBox(height: 12),
                  _buildMapCard(),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.subtleBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.groups_outlined, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Passengers',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '$paxCount / ${flow.capacity} capacity',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _TripStackLabel(
                    icon: Icons.schedule_outlined,
                    label: 'Waiting for Pickup',
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 6),
                  ...flow.waitingPassengers.map(
                    (TripPassenger p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _WaitingPassengerCard(
                        passenger: p,
                        isActive: flow.activeWaitingPassengerId == p.id,
                        isExpanded: _expandedPassengers.contains(p.id),
                        onToggleDetails: () => _togglePassengerDetails(p.id),
                        onArrived: () {
                          flow.selectWaitingPassenger(p.id);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _TripStackLabel(
                    icon: Icons.check_circle_outline,
                    label: 'Onboard',
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 6),
                  ...flow.onboardPassengers.map(
                    (TripPassenger p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OnboardRow(passenger: p),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PickupNotesBanner(),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final bool goTrip = flow.advancePickupPrimary();
                        if (goTrip && context.mounted) {
                          Navigator.of(context).pushReplacementNamed(AppRouter.tripInProgress);
                        } else {
                          setState(() {});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(flow.pickupPrimaryIcon, size: 20),
                      label: Text(flow.pickupPrimaryLabel),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRouter.home,
                        (Route<dynamic> route) => false,
                      ),
                      child: const Text(
                        'Cancel Assignment',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: 220,
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
        clipBehavior: Clip.none,
        children: [
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_outlined, color: AppColors.textMuted, size: 28),
                SizedBox(height: 4),
                Text(
                  'Optimized route to all waypoints',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Positioned(
            top: 48,
            right: 64,
            child: _MapMarker(icon: Icons.electric_rickshaw_outlined, label: 'You', color: AppColors.primary),
          ),
          Positioned(
            top: 96,
            left: 46,
            child: _MapMarker(icon: Icons.person_pin_circle_outlined, label: 'Jose — Pickup', color: AppColors.success),
          ),
          Positioned(
            bottom: 48,
            right: 42,
            child: _MapMarker(icon: Icons.flag_outlined, label: 'Maria — USM', color: AppColors.danger),
          ),
          Positioned(
            bottom: 78,
            left: 94,
            child: _MapMarker(icon: Icons.flag_outlined, label: 'Jose — Nongnongan', color: AppColors.danger),
          ),
          Positioned(
            top: 88,
            left: 72,
            child: Transform.rotate(
              angle: -0.26,
              child: Container(
                width: 120,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupNotesBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.subtleBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                children: <InlineSpan>[
                  const TextSpan(text: 'Heading to '),
                  const TextSpan(
                    text: 'Poblacion Terminal',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const TextSpan(text: ' to pick up Jose Rizal. Estimated arrival in '),
                  const TextSpan(
                    text: '~3 min',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingPassengerCard extends StatelessWidget {
  const _WaitingPassengerCard({
    required this.passenger,
    required this.isActive,
    required this.isExpanded,
    required this.onToggleDetails,
    required this.onArrived,
  });

  final TripPassenger passenger;
  final bool isActive;
  final bool isExpanded;
  final VoidCallback onToggleDetails;
  final VoidCallback onArrived;

  @override
  Widget build(BuildContext context) {
    final String initials = passenger.initials ??
        passenger.name
            .split(' ')
            .map((String w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.warning, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary10,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onToggleDetails,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(passenger.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 12, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          passenger.pickupNotes ?? 'Tap card to view booking details',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        isExpanded ? 'Hide booking details' : 'Tap card to view booking details',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          if (passenger.rideType != null)
                            InfoRow(
                              label: 'Ride Type',
                              value: passenger.rideType == RideType.shared ? 'SHARED' : 'SPECIAL',
                            ),
                          InfoRow(label: 'Pickup', value: passenger.pickupAddress),
                          InfoRow(label: 'Destination', value: passenger.dropoffAddress),
                          InfoRow(label: 'Fare', value: passenger.fareDisplay ?? '-', showBorder: false),
                        ],
                      ),
                    ),
                    crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 180),
                    sizeCurve: Curves.easeInOut,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onArrived,
            style: TextButton.styleFrom(
              backgroundColor: isActive ? AppColors.warning : AppColors.warningLight,
              foregroundColor: isActive ? Colors.white : const Color(0xFF92400E),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFF3D48C)),
              ),
            ),
            child: const Text('Arrived', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _OnboardRow extends StatelessWidget {
  const _OnboardRow({required this.passenger});

  final TripPassenger passenger;

  @override
  Widget build(BuildContext context) {
    final String initials = passenger.initials ?? 'P';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.success, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.success),
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
                  passenger.routeSubtitle ?? '${passenger.pickupAddress} → ${passenger.dropoffAddress}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            passenger.fareDisplay ?? '',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _TripStackLabel extends StatelessWidget {
  const _TripStackLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

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
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
