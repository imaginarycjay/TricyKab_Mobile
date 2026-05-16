import 'package:flutter_test/flutter_test.dart';

import 'package:driver_app/features/driver_flow/domain/driver_flow_models.dart';
import 'package:driver_app/features/driver_flow/domain/driver_performance_stats.dart';

DriverHistoryBooking _completed({
  required int id,
  required String iso,
  String fare = '50.00',
}) {
  return DriverHistoryBooking(
    id: id,
    reference: 'TK-$id',
    status: 'COMPLETED',
    rideType: RideType.shared,
    pickupAddress: 'A',
    destinationAddress: 'B',
    fareAmount: fare,
    acceptedAtIso: iso,
  );
}

void main() {
  test('forPeriod filters today and week', () {
    final now = DateTime.now();
    final todayIso = DateTime(now.year, now.month, now.day, 12).toIso8601String();
    final lastWeekIso = now.subtract(const Duration(days: 10)).toIso8601String();

    final rows = [
      _completed(id: 1, iso: todayIso),
      _completed(id: 2, iso: lastWeekIso),
    ];

    final today = DriverPerformanceStats.forPeriod(rows, PerformancePeriod.today);
    expect(today.tripCount, 1);
    expect(today.earned, 50.0);

    final week = DriverPerformanceStats.forPeriod(rows, PerformancePeriod.thisWeek);
    expect(week.tripCount, greaterThanOrEqualTo(1));
  });

  test('dailyEarningsThisWeek returns seven buckets', () {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final iso = DateTime(monday.year, monday.month, monday.day, 14).toIso8601String();
    final daily = DriverPerformanceStats.dailyEarningsThisWeek([
      _completed(id: 1, iso: iso, fare: '30.00'),
    ]);
    expect(daily.length, 7);
    expect(daily.first, 30.0);
  });
}
