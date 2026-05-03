import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Circular countdown matching mockup ring colors: safe / warning / danger.
class CountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback? onExpired;
  final double size;

  const CountdownTimer({
    super.key,
    required this.seconds,
    this.onExpired,
    this.size = 64,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) {
        setState(() => _remaining--);
      } else {
        _timer?.cancel();
        widget.onExpired?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _ringColor(int total, int remaining) {
    if (remaining <= 5) return AppColors.danger;
    if (remaining <= 10) return AppColors.warning;
    return AppColors.success;
  }

  Color _textColor(int total, int remaining) {
    if (remaining <= 5) return AppColors.danger;
    if (remaining <= 10) return AppColors.warning;
    return AppColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.seconds;
    final double progress = total > 0 ? _remaining / total : 0;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 4,
              color: AppColors.border,
              strokeCap: StrokeCap.round,
            ),
          ),
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              color: _ringColor(total, _remaining),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '$_remaining',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _textColor(total, _remaining),
            ),
          ),
        ],
      ),
    );
  }
}
