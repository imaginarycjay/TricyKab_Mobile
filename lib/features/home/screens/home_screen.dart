import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/driver_card.dart';
import '../../driver_flow/driver_flow_controller.dart';
import '../../driver_flow/driver_flow_scope.dart';
import '../../driver_flow/domain/driver_flow_models.dart';
import '../../driver_flow/domain/driver_performance_stats.dart';
import '../../../navigation/app_router.dart';

/// Driver Home screen.
/// PRD Section 16.1: Online/Offline flow, PRD Section 16 driver home requirements.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _polledOnce = false;
  PerformancePeriod _performancePeriod = PerformancePeriod.today;
  late final AnimationController _attentionPulse;

  @override
  void initState() {
    super.initState();
    _attentionPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_polledOnce) return;
    _polledOnce = true;
    final flow = DriverFlowScope.of(context);
    flow.startOfferPolling();
    if (flow.isOnline) flow.startIdleAvailabilityPing();
    flow.loadBookings(forceNetwork: false);
  }

  @override
  void dispose() {
    _attentionPulse.dispose();
    super.dispose();
  }

  Future<void> _refreshBookings() async {
    await DriverFlowScope.of(context).loadBookings(forceNetwork: true);
  }

  @override
  Widget build(BuildContext context) {
    final flow = DriverFlowScope.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    _syncAttentionPulse(
      enabled: !reduceMotion && flow.offerSurfaceSuppressed && flow.offers.isNotEmpty,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            trailing: IconButton(
              icon: Icon(Icons.settings_outlined, color: AppColors.textMuted),
              tooltip: 'Settings',
              onPressed: null,
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: flow,
              builder: (context, _) {
                return RefreshIndicator(
                  onRefresh: _refreshBookings,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileCard(flow),
                        const SizedBox(height: 16),
                        if (flow.phase != DriverPhase.waitingOffers || flow.tripAnchorOffer != null)
                          _buildActiveTripBanner(flow),
                        if (flow.phase != DriverPhase.waitingOffers || flow.tripAnchorOffer != null)
                          const SizedBox(height: 16),
                        _buildSectionTitle(DriverPerformanceStats.periodTitle(_performancePeriod)),
                        _buildPeriodSelector(),
                        const SizedBox(height: 8),
                        _buildStatsGrid(flow),
                        const SizedBox(height: 8),
                        const Text(
                          'Based on your last 50 trips.',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionTitle('Weekly Earnings'),
                        _buildEarningsCard(flow),
                        const SizedBox(height: 12),
                        _buildOfferHotZone(flow),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          BottomNav(
            currentIndex: 0,
            onTap: (index) {
              if (index == 1) {
                AppRouter.navigateTab(context, fromIndex: 0, toIndex: 1, routeName: AppRouter.tripHistory);
              } else if (index == 2) {
                AppRouter.navigateTab(context, fromIndex: 0, toIndex: 2, routeName: AppRouter.profile);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: PerformancePeriod.values.map((p) {
          final selected = p == _performancePeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(switch (p) {
                PerformancePeriod.today => 'Today',
                PerformancePeriod.thisWeek => 'This week',
                PerformancePeriod.thisMonth => 'This month',
              }),
              selected: selected,
              onSelected: (_) => setState(() => _performancePeriod = p),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProfileCard(DriverFlowController flow) {
    final me = flow.me;
    final bool needsAttention = flow.offerSurfaceSuppressed && flow.offers.isNotEmpty;
    return Container(
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
          ProfileCard(
            initials: me?.initials ?? '—',
            name: me?.fullName ?? 'Driver',
            meta: me?.meta ?? '—',
            trailing: StatusBadge.availability(flow.isOnline),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _attentionPulse,
            builder: (context, child) {
              final double t = Curves.easeInOut.transform(_attentionPulse.value);
              final double glow = needsAttention ? (0.12 + (t * 0.18)) : 0.0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.subtleBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: needsAttention ? Border.all(color: AppColors.primary.withValues(alpha: 0.45)) : null,
                  boxShadow: needsAttention
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: glow),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          needsAttention ? 'Availability · Action needed' : 'Availability',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          flow.isOnline ? 'You\'re accepting rides' : 'You\'re offline',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: flow.isLoading
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final msg = await flow.setAvailability(desiredOnline: !flow.isOnline);
                              if (msg != null) {
                                messenger.showSnackBar(SnackBar(content: Text(msg)));
                              }
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 52,
                        height: 28,
                        decoration: BoxDecoration(
                          color: flow.isOnline ? AppColors.success : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 300),
                          alignment: flow.isOnline ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _syncAttentionPulse({required bool enabled}) {
    if (!enabled) {
      if (_attentionPulse.isAnimating) _attentionPulse.stop();
      if (_attentionPulse.value != 0.0) _attentionPulse.value = 0.0;
      return;
    }
    if (_attentionPulse.isAnimating) return;
    _attentionPulse.repeat(reverse: true);
  }

  Widget _buildOfferHotZone(DriverFlowController flow) {
    final bool hasSuppressedOffer = flow.offerSurfaceSuppressed && flow.offers.isNotEmpty;
    if (!hasSuppressedOffer) {
      return const SizedBox(height: 4);
    }
    final int count = flow.offers.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Color(0xFF92400E)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE OFFER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 1 ? '1 offer waiting for your action.' : '$count offers waiting for your action.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              flow.clearOfferSurfaceSuppression();
              AppRouter.navigateForward(context, AppRouter.incomingOffer);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(44, 44),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripBanner(DriverFlowController flow) {
    final String phaseLabel = flow.phase.label;
    final String? ref = flow.tripAnchorOffer?.reference;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF312E81).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE TRIP',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Phase: $phaseLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (ref != null)
                  Text(
                    ref,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => AppRouter.resumeActiveTrip(context, flow.phase),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Resume'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DriverFlowController flow) {
    final rows = flow.bookings;
    if (rows == null && flow.bookingsLoadError == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bucket = DriverPerformanceStats.forPeriod(rows ?? const [], _performancePeriod);
    final loading = flow.bookingsRefreshing;

    return Opacity(
      opacity: loading ? 0.7 : 1,
      child: Container(
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
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppColors.borderLight),
                        bottom: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    child: StatCard(value: '${bucket.tripCount}', label: 'Trips'),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    child: StatCard(
                      value: 'PHP ${bucket.earned.toStringAsFixed(2)}',
                      label: 'Earned',
                      valueColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Row(
              children: [
                Expanded(
                  child: StatCard(value: '—', label: 'Online'),
                ),
                Expanded(
                  child: StatCard(
                    value: '—',
                    label: 'Accept Rate',
                    valueColor: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard(DriverFlowController flow) {
    final rows = flow.bookings ?? const <DriverHistoryBooking>[];
    final sumThisWeek = DriverPerformanceStats.sumThisWeek(rows);
    final sumLastWeek = DriverPerformanceStats.sumLastWeek(rows);
    final daily = DriverPerformanceStats.dailyEarningsThisWeek(rows);
    final maxDay = daily.fold<double>(0, (a, b) => a > b ? a : b);
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THIS WEEK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'PHP ${sumThisWeek.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'LAST WEEK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'PHP ${sumLastWeek.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isToday = i == todayIndex;
                final amount = daily[i];
                final heightFactor = maxDay > 0 ? (amount / maxDay).clamp(0.08, 1.0) : 0.08;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 6 ? 6 : 0),
                    height: 60 * heightFactor,
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.primary : AppColors.primary20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isToday = i == todayIndex;
              return Expanded(
                child: Text(
                  const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isToday ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
