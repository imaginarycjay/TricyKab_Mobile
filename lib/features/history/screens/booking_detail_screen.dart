import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/status_badge.dart';
import '../../driver_flow/domain/driver_flow_models.dart';
import '../../driver_flow/driver_flow_scope.dart';

/// PRD §16 — Driver booking detail (read-only).  Backed by
/// `GET /drivers/me/bookings/{booking}`.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late Future<DriverHistoryBooking?> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = DriverFlowScope.of(context).repository.bookingDetail(widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking detail'),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: FutureBuilder<DriverHistoryBooking?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final b = snap.data;
          if (b == null) {
            return const Center(child: Text('Booking not found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _routeCard(b),
              const SizedBox(height: 12),
              _detailsCard(b),
              const SizedBox(height: 12),
              _passengerCard(b),
              const SizedBox(height: 12),
              _statusTimeline(b),
            ],
          );
        },
      ),
    );
  }

  Widget _routeCard(DriverHistoryBooking b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                b.reference,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              StatusBadge.fromStatus(b.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.trip_origin, color: AppColors.success, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  b.pickupAddress,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7, top: 4, bottom: 4),
            child: Container(width: 2, height: 18, color: AppColors.borderLight),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place, color: AppColors.danger, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  b.destinationAddress,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailsCard(DriverHistoryBooking b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trip Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          InfoRow(
            label: 'Ride Type',
            value: b.rideType == RideType.special ? 'SPECIAL' : 'SHARED',
          ),
          InfoRow(label: 'Distance', value: b.distanceLabel),
          InfoRow(label: 'Duration (est.)', value: b.durationLabel),
          InfoRow(label: 'Fare', value: b.fareDisplay, valueColor: AppColors.primary, showBorder: false),
        ],
      ),
    );
  }

  Widget _passengerCard(DriverHistoryBooking b) {
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary10,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              b.passengerInitials ?? '?',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.passengerName ?? 'Passenger',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Direct contact deferred (PRD §15.3)',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTimeline(DriverHistoryBooking b) {
    final entries = <_TimelineEntry>[
      _TimelineEntry('Created', b.createdAtIso),
      _TimelineEntry('Accepted', b.acceptedAtIso),
      if (b.cancelledAtIso != null) _TimelineEntry('Cancelled', b.cancelledAtIso),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Timeline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final e in entries) _timelineRow(e),
        ],
      ),
    );
  }

  Widget _timelineRow(_TimelineEntry e) {
    final dt = e.iso;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record, size: 10, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              e.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            dt == null ? '—' : _short(dt),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  String _short(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $h:${dt.minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return iso;
    }
  }
}

class _TimelineEntry {
  const _TimelineEntry(this.label, this.iso);
  final String label;
  final String? iso;
}
