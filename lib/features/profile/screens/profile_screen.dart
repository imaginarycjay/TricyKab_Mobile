import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../navigation/app_router.dart';
import '../../driver_flow/driver_flow_scope.dart';
import '../../driver_flow/domain/driver_performance_stats.dart';

/// PRD §16.1 driver profile + compliance.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedOnce) return;
    _loadedOnce = true;
    DriverFlowScope.of(context).loadBookings(forceNetwork: false);
  }

  @override
  Widget build(BuildContext context) {
    final flow = DriverFlowScope.of(context);
    final me = flow.me;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary10,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          me?.initials ?? '—',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              me?.fullName ?? 'Driver',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              me?.meta ?? '—',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 6),
                            StatusBadge.availability(flow.isOnline),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Compliance'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      InfoRow(label: 'Phone', value: me?.phone ?? '—'),
                      InfoRow(label: "Driver's License", value: me?.licenseNumber ?? '—'),
                      InfoRow(label: 'TODA', value: me?.todaName ?? '—'),
                      InfoRow(label: 'Plate Number', value: me?.tricyclePlateNumber ?? '—'),
                      InfoRow(label: 'Capacity', value: '${me?.tricycleCapacity ?? flow.capacity} passengers'),
                      const InfoRow(label: 'Verification', value: 'APPROVED', valueColor: AppColors.success, showBorder: false),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.subtleBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.textMuted, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Compliance edits are handled by your TODA admin per PRD §16.1.',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: _SectionTitle('Performance')),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed(AppRouter.earnings),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                ListenableBuilder(
                  listenable: flow,
                  builder: (context, _) {
                    final week = DriverPerformanceStats.forPeriod(
                      flow.bookings ?? const [],
                      PerformancePeriod.thisWeek,
                    );
                    final today = DriverPerformanceStats.forPeriod(
                      flow.bookings ?? const [],
                      PerformancePeriod.today,
                    );
                    final loading = flow.bookings == null && flow.bookingsLoadError == null;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Trips this week',
                              value: loading ? '…' : '${week.tripCount}',
                              color: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: _StatTile(
                              label: 'Earned this week',
                              value: loading ? '…' : 'PHP ${week.earned.toStringAsFixed(0)}',
                              color: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: _StatTile(
                              label: 'Today',
                              value: loading ? '…' : '${today.tripCount}',
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (me?.rating != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4),
                    child: Text(
                      '${me!.rating!.toStringAsFixed(1)}★ average rating',
                      style: const TextStyle(fontSize: 11, color: AppColors.warning),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const _SectionTitle('Account'),
                _LinkTile(
                  icon: Icons.history_outlined,
                  label: 'Trip history',
                  onTap: () => Navigator.of(context).pushNamed(AppRouter.tripHistory),
                ),
                _LinkTile(
                  icon: Icons.payments_outlined,
                  label: 'Earnings',
                  onTap: () => Navigator.of(context).pushNamed(AppRouter.earnings),
                ),
                _LinkTile(
                  icon: Icons.logout,
                  label: 'Sign out',
                  isDestructive: true,
                  onTap: () async {
                    await flow.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.login,
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          BottomNav(
            currentIndex: 2,
            onTap: (index) {
              if (index == 0) {
                AppRouter.navigateTab(context, fromIndex: 2, toIndex: 0, routeName: AppRouter.home);
              } else if (index == 1) {
                AppRouter.navigateTab(context, fromIndex: 2, toIndex: 1, routeName: AppRouter.tripHistory);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.danger : AppColors.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
