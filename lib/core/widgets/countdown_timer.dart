import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Circular countdown timer matching the CSS countdown style.
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

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / widget.seconds;
    final color = _remaining <= 5 ? AppColors.danger : AppColors.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
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
          // Progress ring
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Number
          Text(
            '$_remaining',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
