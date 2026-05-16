import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/live_map.dart';
import '../../driver_flow/domain/driver_flow_models.dart';
import '../../driver_flow/driver_flow_controller.dart';
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
            onPressed: () => AppRouter.navigateHome(context),
            child: const Text('Back to Home'),
          ),
        ),
      );
    }

    final int paxCount = flow.waitingPassengers.length + flow.onboardPassengers.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Leave active trip?'),
            content: const Text(
              'You have an active assignment. Going back to home will not cancel it — you can resume from the home screen.',
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_phaseIcon(flow.phase), size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'PHASE · ${flow.phase.label}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
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
                              AppRouter.navigateModal(
                                context,
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
                  _buildMapCard(flow),
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
                        onArrived: () async {
                          flow.selectWaitingPassenger(p.id);
                          if (flow.phase == DriverPhase.assigned) {
                            flow.markOnTheWay();
                          }
                          if (flow.phase == DriverPhase.onTheWay) {
                            await flow.markArrived();
                          }
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
                  _PickupNotesBanner(flow: flow),
                  const SizedBox(height: 14),
                  if (flow.lastError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              flow.lastError!,
                              style: const TextStyle(fontSize: 12, color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: flow.isLoading ? null : () => _onPrimaryTap(context, flow),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: flow.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(flow.pickupPrimaryIcon, size: 20),
                      label: Text(flow.pickupPrimaryLabel),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton.icon(
                      onPressed: flow.isLoading ? null : () => _confirmCancelAssignment(context, flow),
                      icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
                      label: const Text(
                        'Cancel Assignment',
                        style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
                      ),
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

  IconData _phaseIcon(DriverPhase phase) {
    switch (phase) {
      case DriverPhase.assigned:
        return Icons.assignment_turned_in_outlined;
      case DriverPhase.onTheWay:
        return Icons.directions_rounded;
      case DriverPhase.arrived:
        return Icons.flag_outlined;
      case DriverPhase.inProgress:
        return Icons.play_arrow_rounded;
      case DriverPhase.completed:
        return Icons.check_circle_outline;
      case DriverPhase.waitingOffers:
        return Icons.hourglass_top_outlined;
    }
  }

  Future<void> _onPrimaryTap(BuildContext context, DriverFlowController flow) async {
    final messenger = ScaffoldMessenger.of(context);
    final goTrip = await flow.advancePickupPrimary();
    if (!mounted) return;
    if (goTrip) {
      AppRouter.navigateForward(context, AppRouter.tripInProgress, replace: true);
    } else {
      setState(() {});
      if (flow.lastError != null) {
        messenger.showSnackBar(SnackBar(content: Text(flow.lastError!)));
      }
    }
  }

  Future<void> _confirmCancelAssignment(BuildContext context, DriverFlowController flow) async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return _CancelReasonDialog();
      },
    );
    if (reason == null) return;
    await flow.cancelAssignment(reasonCode: reason);
    if (!mounted) return;
    if (flow.lastError != null) {
      messenger.showSnackBar(SnackBar(content: Text(flow.lastError!)));
      return;
    }
    AppRouter.navigateHome(context);
  }

  Widget _buildMapCard(DriverFlowController flow) {
    final offer = flow.tripAnchorOffer;
    return LiveMap(
      height: 240,
      pickupLat: offer?.pickupLatitude ?? 7.1083,
      pickupLng: offer?.pickupLongitude ?? 124.8295,
      destinationLat: offer?.destinationLatitude ?? 7.1117,
      destinationLng: offer?.destinationLongitude ?? 124.8419,
      showRoute: true,
      showFullscreenButton: true,   // PRD §5A — fullscreen map toggle
      // driverHasArrived defaults false: routes driver → pickup (en-route)
      // Use real GPS position from the flow controller (updated by
      // setAvailability, startLocationPing, and _bestEffortPosition).
      // Fall back to a position near the pickup when GPS is unavailable.
      driverLat: flow.lastLatitude ?? (offer?.pickupLatitude ?? 7.1083) - 0.002,
      driverLng: flow.lastLongitude ?? (offer?.pickupLongitude ?? 124.8295) - 0.002,
    );
  }
}

class _PickupNotesBanner extends StatelessWidget {
  const _PickupNotesBanner({required this.flow});
  final DriverFlowController flow;

  @override
  Widget build(BuildContext context) {
    final offer = flow.tripAnchorOffer;
    final firstPassenger = flow.waitingPassengers.isNotEmpty
        ? flow.waitingPassengers.first
        : null;
    final passengerName = firstPassenger?.name ?? offer?.passengerName ?? 'passenger';
    final pickupAddress = firstPassenger?.pickupAddress ?? offer?.pickupAddress ?? 'pickup';

    String taskText;
    switch (flow.phase) {
      case DriverPhase.assigned:
      case DriverPhase.onTheWay:
        taskText = 'Heading to $pickupAddress to pick up $passengerName.';
        break;
      case DriverPhase.arrived:
        taskText = 'Arrived at pickup. Waiting for $passengerName.';
        break;
      case DriverPhase.inProgress:
        taskText = 'Trip in progress with ${flow.onboardPassengers.length} passenger(s) onboard.';
        break;
      default:
        taskText = 'Ready — awaiting next task.';
    }

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
            child: Text(
              taskText,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar | name + notes | arrived button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary10,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onToggleDetails,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passenger.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (passenger.pickupNotes != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, size: 11, color: AppColors.warning),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                passenger.pickupNotes!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: [
                          Text(
                            isExpanded ? 'Hide details' : 'View booking details',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
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
                child: const Text(
                  'Arrived',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          // Expandable booking details
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.subtleBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Column(
                  children: [
                    if (passenger.rideType != null)
                      InfoRow(
                        label: 'Type',
                        value: passenger.rideType == RideType.shared ? 'SHARED' : 'SPECIAL',
                      ),
                    InfoRow(label: 'Pickup', value: passenger.pickupAddress),
                    InfoRow(label: 'Dest', value: passenger.dropoffAddress),
                    InfoRow(
                      label: 'Fare',
                      value: passenger.fareDisplay ?? '—',
                      valueColor: AppColors.primary,
                      showBorder: false,
                    ),
                  ],
                ),
              ),
            ),
            crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
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
    final String initials = passenger.initials ??
        passenger.name
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
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
                      '${passenger.pickupAddress} → ${passenger.dropoffAddress}',
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
          Text(
            passenger.fareDisplay ?? '',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
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



class _CancelReasonDialog extends StatefulWidget {
  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  String _selected = 'PASSENGER_NO_SHOW';

  Widget _option(String label, String value) {
    return InkWell(
      onTap: () => setState(() => _selected = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              _selected == value ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 18,
              color: _selected == value ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel assignment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pick a reason. Repeated cancellations affect your driver score (PRD §11.4).',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          _option('Passenger no-show', 'PASSENGER_NO_SHOW'),
          _option('Mechanical issue', 'MECHANICAL_ISSUE'),
          _option('Other', 'OTHER'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep assignment'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Cancel assignment'),
        ),
      ],
    );
  }
}
