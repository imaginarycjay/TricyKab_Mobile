import 'package:flutter/widgets.dart';

import 'driver_flow_controller.dart';

class DriverFlowScope extends InheritedNotifier<DriverFlowController> {
  const DriverFlowScope({
    super.key,
    required DriverFlowController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static DriverFlowController of(BuildContext context) {
    final DriverFlowScope? scope =
        context.dependOnInheritedWidgetOfExactType<DriverFlowScope>();
    assert(scope != null, 'DriverFlowScope not found in widget tree.');
    return scope!.notifier!;
  }

  static DriverFlowController? maybeOf(BuildContext context) {
    final DriverFlowScope? scope =
        context.dependOnInheritedWidgetOfExactType<DriverFlowScope>();
    return scope?.notifier;
  }
}
