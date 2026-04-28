import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Colored status badge matching the CSS badge system.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
  });

  /// Factory for booking/ride status badges.
  factory StatusBadge.fromStatus(String status) {
    final colors = _statusColors[status.toUpperCase()] ??
        _statusColors['DEFAULT']!;
    return StatusBadge(
      label: _formatLabel(status),
      backgroundColor: colors[0],
      textColor: colors[1],
    );
  }

  /// Factory for ride type badges.
  factory StatusBadge.rideType(String type) {
    if (type.toUpperCase() == 'SPECIAL') {
      return const StatusBadge(
        label: 'SPECIAL',
        backgroundColor: AppColors.badgeSpecialBg,
        textColor: AppColors.badgeSpecialText,
      );
    }
    return const StatusBadge(
      label: 'SHARED',
      backgroundColor: AppColors.badgeSharedBg,
      textColor: AppColors.badgeSharedText,
    );
  }

  /// Factory for online/offline badges.
  factory StatusBadge.availability(bool isOnline) {
    return StatusBadge(
      label: isOnline ? 'ONLINE' : 'OFFLINE',
      backgroundColor: isOnline ? AppColors.badgeOnlineBg : AppColors.badgeOfflineBg,
      textColor: isOnline ? AppColors.badgeOnlineText : AppColors.badgeOfflineText,
    );
  }

  /// Factory for cash payment badge.
  factory StatusBadge.cash() {
    return const StatusBadge(
      label: 'CASH',
      backgroundColor: AppColors.badgeCashBg,
      textColor: AppColors.badgeCashText,
    );
  }

  static String _formatLabel(String status) {
    return status.toUpperCase().replaceAll('_', ' ');
  }

  static final Map<String, List<Color>> _statusColors = {
    'CREATED': [AppColors.badgeSearchingBg, AppColors.badgeSearchingText],
    'SEARCHING_DRIVER': [AppColors.badgeSearchingBg, AppColors.badgeSearchingText],
    'DRIVER_ASSIGNED': [AppColors.badgeAssignedBg, AppColors.badgeAssignedText],
    'DRIVER_ON_THE_WAY': [AppColors.badgeAssignedBg, AppColors.badgeAssignedText],
    'DRIVER_ARRIVED': [AppColors.badgeInProgressBg, AppColors.badgeInProgressText],
    'TRIP_IN_PROGRESS': [AppColors.badgeInProgressBg, AppColors.badgeInProgressText],
    'COMPLETED': [AppColors.badgeCompletedBg, AppColors.badgeCompletedText],
    'CANCELLED_BY_PASSENGER': [AppColors.badgeCancelledBg, AppColors.badgeCancelledText],
    'CANCELLED_BY_DRIVER': [AppColors.badgeCancelledBg, AppColors.badgeCancelledText],
    'CANCELLED_NO_DRIVER': [AppColors.badgeCancelledBg, AppColors.badgeCancelledText],
    'NO_SHOW_PASSENGER': [AppColors.badgeCancelledBg, AppColors.badgeCancelledText],
    'NO_SHOW_DRIVER': [AppColors.badgeCancelledBg, AppColors.badgeCancelledText],
    'ONLINE': [AppColors.badgeOnlineBg, AppColors.badgeOnlineText],
    'OFFLINE': [AppColors.badgeOfflineBg, AppColors.badgeOfflineText],
    'DEFAULT': [AppColors.subtleBackground, AppColors.textSecondary],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.subtleBackground,
        borderRadius: BorderRadius.circular(100),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: textColor ?? AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
