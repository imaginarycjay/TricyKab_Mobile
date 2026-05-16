import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driver_app/core/cache/driver_bookings_cache.dart';
import 'package:driver_app/features/driver_flow/domain/driver_flow_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DriverBookingsCache round-trips list and detail JSON', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = DriverBookingsCache(prefs: prefs)..scopeKey = 'test_driver';

    final row = DriverHistoryBooking(
      id: 1,
      reference: 'TK-001',
      status: 'COMPLETED',
      rideType: RideType.shared,
      pickupAddress: 'A',
      destinationAddress: 'B',
      fareAmount: '25.00',
      createdAtIso: '2026-05-16T10:00:00Z',
    );

    await cache.writeList([row]);
    final list = await cache.readList();
    expect(list, isNotNull);
    expect(list!.rows.length, 1);
    expect(list.rows.first.reference, 'TK-001');

    await cache.writeDetail(row);
    final detail = await cache.readDetail(1);
    expect(detail?.id, 1);
    expect(detail?.fareAmount, '25.00');

    await cache.clear();
    expect(await cache.readList(), isNull);
    expect(await cache.readDetail(1), isNull);
  });
}
