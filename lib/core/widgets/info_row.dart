import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Label-value horizontal row with optional bottom border, matching CSS info-row.
///
/// The value text is wrapped in [Flexible] so long strings (e.g. addresses)
/// wrap to a second line instead of overflowing horizontally.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool showBorder;
  final Widget? trailing;

  const InfoRow({
    super.key,
    required this.label,
    this.value = '',
    this.valueColor,
    this.showBorder = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: showBorder
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight, width: 1),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed-width label so value column doesn't fight for space
          SizedBox(
            width: 70,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (trailing != null)
            Flexible(child: Align(alignment: Alignment.centerRight, child: trailing!))
          else
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                  height: 1.35,
                ),
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }
}
