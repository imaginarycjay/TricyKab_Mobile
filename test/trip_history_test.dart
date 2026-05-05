import 'package:driver_app/features/driver_flow/driver_flow_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_driver_flow_repository.dart';

void main() {
  test('myBookings is called when the trip history future is awaited', () async {
    final fake = FakeDriverFlowRepository();
    final controller = DriverFlowController(repository: fake);

    final rows = await controller.repository.myBookings();
    expect(rows, isNotEmpty, reason: 'Mock repo returns trip history fixtures.');
    expect(fake.calls.contains('myBookings:false'), isTrue);
  });

  test('bookingDetail by id resolves to a row from myBookings', () async {
    final fake = FakeDriverFlowRepository();
    final controller = DriverFlowController(repository: fake);

    final all = await controller.repository.myBookings();
    expect(all, isNotEmpty);
    final first = all.first;

    final detail = await controller.repository.bookingDetail(first.id);
    expect(detail, isNotNull);
    expect(detail!.id, first.id);
    expect(detail.reference, first.reference);
    expect(fake.calls.contains('bookingDetail:${first.id}'), isTrue);
  });
}
