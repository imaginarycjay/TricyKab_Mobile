import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/mock_data.dart';
import '../../../navigation/app_router.dart';
import '../../driver_flow/driver_flow_scope.dart';

/// PRD §16.1 driver profile + compliance.
///
/// MVP scope: TODA, plate, license verification status are read-only because
/// the backend exposes no `GET /drivers/me` endpoint yet — admin Blade is
/// the source of truth.  This screen also hosts settings shortcuts (API base,
/// sign-out) so the operator does not need to re-enter through Login.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = DriverFlowScope.of(context);

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
                        child: const Text(
                          MockDriver.initials,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              MockDriver.fullName,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${MockDriver.todaName} · ${MockDriver.plateNumber}',
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
                _SectionTitle('Compliance'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Column(
                    children: [
                      InfoRow(label: 'Phone', value: MockDriver.phoneNumber),
                      InfoRow(label: "Driver's License", value: MockDriver.licenseNumber),
                      InfoRow(label: 'TODA', value: MockDriver.todaName),
                      InfoRow(label: 'Plate Number', value: MockDriver.plateNumber),
                      InfoRow(label: 'Capacity', value: '${MockDriver.capacity} passengers'),
                      InfoRow(label: 'Verification', value: 'APPROVED', valueColor: AppColors.success, showBorder: false),
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
                _SectionTitle('Performance'),
                Container(
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
                          label: 'Trips today',
                          value: '${MockDriver.todayTrips}',
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: _StatTile(
                          label: 'Accept rate',
                          value: MockDriver.acceptRate,
                          color: AppColors.success,
                        ),
                      ),
                      Expanded(
                        child: _StatTile(
                          label: 'Rating',
                          value: '${MockDriver.ratingAvg.toStringAsFixed(1)}★',
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle('Account'),
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
                  icon: Icons.settings_outlined,
                  label: 'API base / settings',
                  onTap: () => Navigator.of(context).pushNamed('/settings'),
                ),
                _LinkTile(
                  icon: Icons.logout,
                  label: 'Sign out',
                  isDestructive: true,
                  onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    '/settings',
                    (Route<dynamic> route) => false,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          BottomNav(
            currentIndex: 2,
            onTap: (index) {
              if (index == 0) {
                Navigator.of(context).pushReplacementNamed(AppRouter.home);
              } else if (index == 1) {
                Navigator.of(context).pushReplacementNamed(AppRouter.tripHistory);
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
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
