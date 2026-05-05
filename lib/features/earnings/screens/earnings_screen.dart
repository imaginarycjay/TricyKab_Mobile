import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../driver_flow/domain/driver_flow_models.dart';
import '../../driver_flow/driver_flow_scope.dart';

/// PRD §16 Earnings — derives totals client-side from completed bookings.
///
/// PRD §13 deferral: a dedicated payouts API ships post-pilot; until then the
/// driver app reconciles cash settlements locally.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late Future<List<DriverHistoryBooking>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = DriverFlowScope.of(context).repository.myBookings();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = DriverFlowScope.of(context).repository.myBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(showBackButton: true, onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<DriverHistoryBooking>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return ListView(children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Failed to load earnings.')),
                    ]);
                  }
                  final all = (snap.data ?? <DriverHistoryBooking>[])
                      .where((b) => b.isCompleted)
                      .toList();
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Earnings',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Calculated from /drivers/me/bookings — completed trips only',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      _summaryGrid(all),
                      const SizedBox(height: 16),
                      _SectionTitle('Recent completed trips'),
                      if (all.isEmpty)
                        const _EmptyCard()
                      else
                        ...all.take(8).map((b) => _CompletedRow(booking: b)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.subtleBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Detailed payouts API deferred — pilot uses cash settlement (PRD §13).',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid(List<DriverHistoryBooking> rows) {
    final now = DateTime.now();
    final today = rows.where((b) {
      final iso = b.acceptedAtIso ?? b.createdAtIso;
      if (iso == null) return false;
      try {
        final d = DateTime.parse(iso).toLocal();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      } catch (_) {
        return false;
      }
    }).toList();
    final week = rows.where((b) {
      final iso = b.acceptedAtIso ?? b.createdAtIso;
      if (iso == null) return false;
      try {
        final d = DateTime.parse(iso).toLocal();
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day);
        return d.isAfter(start);
      } catch (_) {
        return false;
      }
    }).toList();
    final month = rows.where((b) {
      final iso = b.acceptedAtIso ?? b.createdAtIso;
      if (iso == null) return false;
      try {
        final d = DateTime.parse(iso).toLocal();
        return d.year == now.year && d.month == now.month;
      } catch (_) {
        return false;
      }
    }).toList();

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
          Expanded(child: _Bucket(label: 'Today', rows: today)),
          Container(width: 1, height: 60, color: AppColors.borderLight),
          Expanded(child: _Bucket(label: 'This week', rows: week)),
          Container(width: 1, height: 60, color: AppColors.borderLight),
          Expanded(child: _Bucket(label: 'This month', rows: month)),
        ],
      ),
    );
  }
}

class _Bucket extends StatelessWidget {
  const _Bucket({required this.label, required this.rows});
  final String label;
  final List<DriverHistoryBooking> rows;

  String get _total {
    var sum = 0.0;
    for (final r in rows) {
      final raw = r.fareAmount;
      if (raw == null) continue;
      sum += double.tryParse(raw) ?? 0;
    }
    return 'PHP ${sum.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.6)),
        const SizedBox(height: 6),
        Text(_total,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('${rows.length} trip${rows.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }
}

class _CompletedRow extends StatelessWidget {
  const _CompletedRow({required this.booking});
  final DriverHistoryBooking booking;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.pickupAddress} → ${booking.destinationAddress}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.reference,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            booking.fareDisplay,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.subtleBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'No completed trips yet.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
