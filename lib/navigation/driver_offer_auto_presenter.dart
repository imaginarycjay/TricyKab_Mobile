import 'package:flutter/material.dart';

import '../features/driver_flow/driver_flow_controller.dart';
import '../features/driver_flow/driver_flow_scope.dart';
import 'app_router.dart';

class DriverOfferAutoPresenter extends StatefulWidget {
  const DriverOfferAutoPresenter({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<DriverOfferAutoPresenter> createState() => _DriverOfferAutoPresenterState();
}

class _DriverOfferAutoPresenterState extends State<DriverOfferAutoPresenter> {
  DriverFlowController? _flow;
  String _lastOfferSignature = '';
  bool _navScheduled = false;
  bool _retryScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = DriverFlowScope.maybeOf(context);
    if (next == _flow) return;
    _flow?.removeListener(_onFlowChanged);
    _flow = next;
    _flow?.addListener(_onFlowChanged);
  }

  @override
  void dispose() {
    _flow?.removeListener(_onFlowChanged);
    super.dispose();
  }

  void _onFlowChanged() {
    if (_navScheduled) return;
    _navScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navScheduled = false;
      if (!mounted) return;
      _maybePresentOffer();
    });
  }

  bool _shouldAutoPresent(DriverFlowController flow) {
    if (!flow.isOnline) return false;
    if (flow.isLoading) return false;
    if (flow.offerSurfaceSuppressed) return false;
    if (flow.acceptedOffers.isNotEmpty) return false;
    if (flow.tripAnchorOffer != null) return false;
    if (flow.phase != DriverPhase.waitingOffers) return false;
    return flow.offers.isNotEmpty;
  }

  void _maybePresentOffer() {
    final flow = _flow;
    if (flow == null) return;
    if (!_shouldAutoPresent(flow)) return;

    final nav = widget.navigatorKey.currentState;
    final ctx = nav?.context;
    if (nav == null || ctx == null) {
      if (_retryScheduled) return;
      _retryScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _retryScheduled = false;
        if (!mounted) return;
        _maybePresentOffer();
      });
      return;
    }

    final routeName = ModalRoute.of(ctx)?.settings.name;
    if (routeName == AppRouter.incomingOffer) return;

    final signature = flow.offers.map((o) => o.id).join('|');
    if (signature.isEmpty) return;
    if (signature == _lastOfferSignature) return;
    _lastOfferSignature = signature;

    AppRouter.navigateForward(ctx, AppRouter.incomingOffer);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

