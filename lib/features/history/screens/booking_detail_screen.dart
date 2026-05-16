import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/driver_dispute_sheet.dart';
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
  DriverHistoryBooking? _booking;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(forceNetwork: false));
  }

  Future<void> _load({required bool forceNetwork}) async {
    final flow = DriverFlowScope.of(context);
    setState(() {
      if (_booking == null) _loading = true;
      _error = null;
    });
    final detail = await flow.bookingDetail(widget.bookingId, forceNetwork: forceNetwork);
    if (!mounted) return;
    setState(() {
      _booking = detail;
      _loading = false;
      if (detail == null) _error = 'Booking not found.';
    });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : () => _load(forceNetwork: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading && _booking == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(_booking!),
    );
  }

  Widget _buildBody(DriverHistoryBooking b) {
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
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final flow = DriverFlowScope.of(context);
            DriverDisputeSheet.show(
              context,
              onSubmit: (type, description) => flow.repository.submitDispute(
                bookingId: b.id,
                disputeType: type,
                description: description,
              ),
            );
          },
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Report issue'),
        ),
      ],
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
              StatusBadge.fromStatus(b.status),
              const SizedBox(width: 8),
              StatusBadge.rideType(b.rideType == RideType.special ? 'SPECIAL' : 'SHARED'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${b.pickupAddress} → ${b.destinationAddress}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(b.reference, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
      ),
      child: Column(
        children: [
          InfoRow(label: 'Fare', value: b.fareDisplay),
          InfoRow(label: 'Distance', value: b.distanceLabel),
          InfoRow(label: 'Duration', value: b.durationLabel, showBorder: false),
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
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary10,
            child: Text(
              b.passengerInitials ?? '?',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              b.passengerName ?? 'Passenger',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTimeline(DriverHistoryBooking b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.subtleBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Timeline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          if (b.createdAtIso != null) Text('Created: ${b.createdAtIso}', style: const TextStyle(fontSize: 11)),
          if (b.acceptedAtIso != null) Text('Accepted: ${b.acceptedAtIso}', style: const TextStyle(fontSize: 11)),
          if (b.cancelledAtIso != null) Text('Cancelled: ${b.cancelledAtIso}', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
