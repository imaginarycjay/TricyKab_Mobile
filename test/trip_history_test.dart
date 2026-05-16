import 'package:driver_app/core/cache/driver_bookings_cache.dart';
import 'package:driver_app/features/driver_flow/driver_flow_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_driver_flow_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('myBookings is called when loading from network', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeDriverFlowRepository();
    final controller = DriverFlowController(
      repository: fake,
      bookingsCache: DriverBookingsCache(prefs: prefs),
    );

    await controller.loadBookings(forceNetwork: true);
    expect(controller.bookings, isNotEmpty);
    expect(fake.calls.contains('myBookings:false'), isTrue);
  });

  test('loadBookings skips network when memory cache is warm', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeDriverFlowRepository();
    final controller = DriverFlowController(
      repository: fake,
      bookingsCache: DriverBookingsCache(prefs: prefs),
    );

    await controller.loadBookings(forceNetwork: true);
    fake.calls.clear();

    await controller.loadBookings(forceNetwork: false);
    expect(fake.calls.where((c) => c.startsWith('myBookings')), isEmpty);
    expect(controller.bookings, isNotEmpty);
  });

  test('bookingDetail by id resolves to a row from myBookings', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeDriverFlowRepository();
    final controller = DriverFlowController(
      repository: fake,
      bookingsCache: DriverBookingsCache(prefs: prefs),
    );

    await controller.loadBookings(forceNetwork: true);
    final first = controller.bookings!.first;

    final detail = await controller.bookingDetail(first.id, forceNetwork: false);
    expect(detail, isNotNull);
    expect(detail!.id, first.id);
    expect(detail.reference, first.reference);
  });
}
