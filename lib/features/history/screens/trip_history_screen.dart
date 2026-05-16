import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../navigation/app_router.dart';
import '../../driver_flow/domain/driver_flow_models.dart';
import '../../driver_flow/driver_flow_scope.dart';

/// PRD §16 driver-side trip history — backed by `GET /drivers/me/bookings`.
class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

enum _HistoryFilter { all, active, completed, cancelled, scheduled }

extension on _HistoryFilter {
  String get label {
    switch (this) {
      case _HistoryFilter.all:
        return 'All';
      case _HistoryFilter.active:
        return 'Active';
      case _HistoryFilter.completed:
        return 'Completed';
      case _HistoryFilter.cancelled:
        return 'Cancelled';
      case _HistoryFilter.scheduled:
        return 'Scheduled';
    }
  }
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedOnce) return;
    _loadedOnce = true;
    DriverFlowScope.of(context).loadBookings(forceNetwork: false);
  }

  Future<void> _refresh() async {
    await DriverFlowScope.of(context).loadBookings(forceNetwork: true);
  }

  List<DriverHistoryBooking> _apply(List<DriverHistoryBooking> raw) {
    switch (_filter) {
      case _HistoryFilter.all:
        return raw;
      case _HistoryFilter.active:
        return raw.where((b) => b.isActive).toList();
      case _HistoryFilter.completed:
        return raw.where((b) => b.isCompleted).toList();
      case _HistoryFilter.cancelled:
        return raw.where((b) => b.isCancelled).toList();
      case _HistoryFilter.scheduled:
        return raw.where((b) => b.isScheduled).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = DriverFlowScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            showBackButton: true,
            onBack: () => AppRouter.navigateTab(context, fromIndex: 1, toIndex: 0, routeName: AppRouter.home),
          ),
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
                  flow.bookingsFetchedAt != null
                      ? 'Pull down to refresh'
                      : 'Loading your trips…',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: _HistoryFilter.values.map((f) {
                final selected = f == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListenableBuilder(
              listenable: flow,
              builder: (context, _) {
                final bookings = flow.bookings;
                if (bookings == null && flow.bookingsLoadError == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (flow.bookingsLoadError != null && bookings == null) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(child: Text('Failed to load trip history.\n${flow.bookingsLoadError}')),
                      ],
                    ),
                  );
                }
                final rows = _apply(bookings ?? const <DriverHistoryBooking>[]);
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: rows.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            if (_filter == _HistoryFilter.scheduled)
                              const _DeferredCard(
                                title: 'Scheduled bookings',
                                body: 'Coming after pilot. PRD audit deferral.',
                              )
                            else
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Text(
                                    'No bookings match this filter yet.',
                                    style: TextStyle(color: AppColors.textMuted),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(
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
                              itemCount: rows.length,
                              itemBuilder: (context, i) => _TripItem(
                                booking: rows[i],
                                onTap: () => Navigator.of(context).pushNamed(
                                  AppRouter.bookingDetail,
                                  arguments: rows[i].id,
                                ),
                              ),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
          BottomNav(
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) {
                AppRouter.navigateTab(context, fromIndex: 1, toIndex: 0, routeName: AppRouter.home);
              } else if (index == 2) {
                AppRouter.navigateTab(context, fromIndex: 1, toIndex: 2, routeName: AppRouter.profile);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TripItem extends StatelessWidget {
  const _TripItem({required this.booking, required this.onTap});

  final DriverHistoryBooking booking;
  final VoidCallback onTap;

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $h:${dt.minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.route_outlined, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${booking.pickupAddress} → ${booking.destinationAddress}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _formatDate(booking.acceptedAtIso ?? booking.createdAtIso),
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      StatusBadge.rideType(booking.rideType == RideType.special ? 'SPECIAL' : 'SHARED'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  booking.fareDisplay,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge.fromStatus(booking.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeferredCard extends StatelessWidget {
  const _DeferredCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.subtleBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_outlined, color: AppColors.textMuted, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
