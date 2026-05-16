import 'driver_flow_models.dart';

enum PerformancePeriod { today, thisWeek, thisMonth }

class PerformanceBucket {
  const PerformanceBucket({required this.tripCount, required this.earned});

  final int tripCount;
  final double earned;
}

/// Client-side aggregates from cached/display booking rows.
class DriverPerformanceStats {
  DriverPerformanceStats._();

  static DateTime? _bookingDate(DriverHistoryBooking b) {
    final iso = b.acceptedAtIso ?? b.createdAtIso;
    if (iso == null) return null;
    try {
      return DateTime.parse(iso).toLocal();
    } catch (_) {
      return null;
    }
  }

  static double _fare(DriverHistoryBooking b) => double.tryParse(b.fareAmount ?? '') ?? 0;

  static List<DriverHistoryBooking> completedInPeriod(
    List<DriverHistoryBooking> rows,
    PerformancePeriod period,
  ) {
    final now = DateTime.now();
    final completed = rows.where((b) => b.isCompleted).toList();
    switch (period) {
      case PerformancePeriod.today:
        return completed.where((b) {
          final d = _bookingDate(b);
          if (d == null) return false;
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }).toList();
      case PerformancePeriod.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day);
        return completed.where((b) {
          final d = _bookingDate(b);
          if (d == null) return false;
          return d.isAfter(start) || d.isAtSameMomentAs(start);
        }).toList();
      case PerformancePeriod.thisMonth:
        return completed.where((b) {
          final d = _bookingDate(b);
          if (d == null) return false;
          return d.year == now.year && d.month == now.month;
        }).toList();
    }
  }

  static PerformanceBucket forPeriod(List<DriverHistoryBooking> rows, PerformancePeriod period) {
    final filtered = completedInPeriod(rows, period);
    var earned = 0.0;
    for (final b in filtered) {
      earned += _fare(b);
    }
    return PerformanceBucket(tripCount: filtered.length, earned: earned);
  }

  /// Mon–Sun daily earnings for the current calendar week (7 values).
  static List<double> dailyEarningsThisWeek(List<DriverHistoryBooking> rows) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day);
    final totals = List<double>.filled(7, 0);

    for (final b in rows.where((x) => x.isCompleted)) {
      final d = _bookingDate(b);
      if (d == null) continue;
      if (d.isBefore(start)) continue;
      final dayIndex = d.difference(start).inDays;
      if (dayIndex < 0 || dayIndex > 6) continue;
      totals[dayIndex] += _fare(b);
    }
    return totals;
  }

  static double sumThisWeek(List<DriverHistoryBooking> rows) {
    return forPeriod(rows, PerformancePeriod.thisWeek).earned;
  }

  static double sumLastWeek(List<DriverHistoryBooking> rows) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfThisWeek = DateTime(monday.year, monday.month, monday.day);
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
    var sum = 0.0;
    for (final b in rows.where((x) => x.isCompleted)) {
      final d = _bookingDate(b);
      if (d == null) continue;
      if ((d.isAfter(startOfLastWeek) || d.isAtSameMomentAs(startOfLastWeek)) &&
          d.isBefore(startOfThisWeek)) {
        sum += _fare(b);
      }
    }
    return sum;
  }

  static String periodTitle(PerformancePeriod period) {
    switch (period) {
      case PerformancePeriod.today:
        return "Today's Performance";
      case PerformancePeriod.thisWeek:
        return "This Week's Performance";
      case PerformancePeriod.thisMonth:
        return "This Month's Performance";
    }
  }
}
