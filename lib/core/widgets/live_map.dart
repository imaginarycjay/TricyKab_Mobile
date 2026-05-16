import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import '../geo/osrm_service.dart';

// ignore: depend_on_referenced_packages (latlong2 is a transitive flutter_map dep)
const Distance _distance = Distance();

/// Real interactive map widget using OpenStreetMap tiles via flutter_map.
///
/// - Shows pickup (green), destination (red), and optional driver (blue) markers.
/// - Auto-fits camera bounds to contain all visible markers.
/// - Fetches a road-following route via OSRM when [showRoute] is true.
///   Falls back to a dashed straight line when the network call fails.
class LiveMap extends StatefulWidget {
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  final double? driverLat;
  final double? driverLng;
  final double height;
  final bool showRoute;
  /// Show a fullscreen expand button overlay in the top-right corner.
  final bool showFullscreenButton;
  /// When true, routes driver → destination (in-trip). When false, routes driver → pickup.
  final bool driverHasArrived;

  const LiveMap({
    super.key,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
    this.driverLat,
    this.driverLng,
    this.height = 220,
    this.showRoute = false,
    this.showFullscreenButton = false,
    this.driverHasArrived = false,
  });

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  final MapController _mapController = MapController();
  bool _fitted = false;

  // Route state
  List<LatLng>? _routePoints;
  bool _routeLoading = false;
  bool _routeFailed = false;

  // Track which endpoints we last fetched for, to avoid redundant calls
  LatLng? _lastRouteFrom;
  LatLng? _lastRouteTo;

  @override
  void initState() {
    super.initState();
    if (widget.showRoute) {
      _fetchRoute();
    }
  }

  @override
  void didUpdateWidget(covariant LiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showRoute) {
      final driverPt = _driverPoint;
      // PRD §5B — dynamic route: driver → next waypoint
      if (driverPt != null) {
        final target = widget.driverHasArrived ? _destinationPoint : _pickupPoint;
        if (target != null) {
          // Re-fetch only when driver moves >50m from last OSRM query origin
          final lastFrom = _lastRouteFrom;
          if (lastFrom == null ||
              _distance.as(LengthUnit.Meter, driverPt, lastFrom) > 50) {
            _fetchDriverRoute(driverPt, target);
          }
        }
      } else {
        // No driver position: fall back to pickup→destination route
        final from = _pickupPoint;
        final to = _destinationPoint;
        if (from != null && to != null) {
          if (from != _lastRouteFrom || to != _lastRouteTo) {
            _fetchRoute();
          }
        }
      }
    }
    if (widget.driverLat != oldWidget.driverLat ||
        widget.driverLng != oldWidget.driverLng) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitBounds();
      });
    }
  }

  Future<void> _fetchRoute() async {
    final from = _pickupPoint;
    final to = _destinationPoint;
    if (from == null || to == null) return;

    if (from == _lastRouteFrom && to == _lastRouteTo && _routePoints != null) {
      return;
    }

    setState(() {
      _routeLoading = true;
      _routeFailed = false;
    });
    _lastRouteFrom = from;
    _lastRouteTo = to;

    final points = await OsrmService.fetchRoute(from, to);

    if (!mounted) return;
    setState(() {
      _routeLoading = false;
      if (points != null && points.length >= 2) {
        _routePoints = points;
        _routeFailed = false;
      } else {
        _routePoints = null;
        _routeFailed = true;
      }
    });
  }

  /// PRD §5B — Fetch route from driver’s live position to the next waypoint.
  Future<void> _fetchDriverRoute(LatLng from, LatLng to) async {
    setState(() { _routeLoading = true; _routeFailed = false; });
    _lastRouteFrom = from;
    _lastRouteTo = to;

    final points = await OsrmService.fetchRoute(from, to);

    if (!mounted) return;
    setState(() {
      _routeLoading = false;
      if (points != null && points.length >= 2) {
        _routePoints = points;
        _routeFailed = false;
      } else {
        _routePoints = null;
        _routeFailed = true;
      }
    });
  }

  LatLng? get _pickupPoint {
    if (widget.pickupLat != null && widget.pickupLng != null) {
      return LatLng(widget.pickupLat!, widget.pickupLng!);
    }
    return null;
  }

  LatLng? get _destinationPoint {
    if (widget.destinationLat != null && widget.destinationLng != null) {
      return LatLng(widget.destinationLat!, widget.destinationLng!);
    }
    return null;
  }

  LatLng? get _driverPoint {
    if (widget.driverLat != null && widget.driverLng != null) {
      return LatLng(widget.driverLat!, widget.driverLng!);
    }
    return null;
  }

  LatLng get _fallbackCenter => const LatLng(7.1083, 124.8295); // Kabacan

  void _fitBounds() {
    final points = <LatLng>[
      if (_pickupPoint != null) _pickupPoint!,
      if (_destinationPoint != null) _destinationPoint!,
      if (_driverPoint != null) _driverPoint!,
    ];

    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 15.5);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(56),
        maxZoom: 17,
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Driver marker — blue pulsing dot (rendered first so pins appear on top)
    if (_driverPoint != null) {
      markers.add(Marker(
        point: _driverPoint!,
        width: 48,
        height: 48,
        child: _DriverDot(),
      ));
    }

    // Pickup marker — green
    if (_pickupPoint != null) {
      markers.add(Marker(
        point: _pickupPoint!,
        width: 44,
        height: 52,
        alignment: Alignment.topCenter,
        child: const _MapPin(
          color: AppColors.success,
          icon: Icons.location_on_rounded,
          label: 'P',
        ),
      ));
    }

    // Destination marker — red
    if (_destinationPoint != null) {
      markers.add(Marker(
        point: _destinationPoint!,
        width: 44,
        height: 52,
        alignment: Alignment.topCenter,
        child: const _MapPin(
          color: Color(0xFFEF4444),
          icon: Icons.flag_rounded,
          label: 'D',
        ),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final center = _driverPoint ?? _pickupPoint ?? _fallbackCenter;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: () {
                  if (!_fitted) {
                    _fitted = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _fitBounds();
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tricykab.driver_app',
                  maxZoom: 19,
                ),
                // Road-following route from OSRM (solid blue line)
                if (_routePoints != null && _routePoints!.length >= 2)
                  PolylineLayer<Object>(
                    polylines: [
                      Polyline<Object>(
                        points: _routePoints!,
                        color: AppColors.primary,
                        strokeWidth: 4.0,
                      ),
                    ],
                  )
                // Fallback: dashed straight line while loading or on error
                else if (_pickupPoint != null && _destinationPoint != null)
                  PolylineLayer<Object>(
                    polylines: [
                      Polyline<Object>(
                        points: [_pickupPoint!, _destinationPoint!],
                        color: AppColors.primary.withValues(alpha: 0.45),
                        strokeWidth: 3.0,
                        pattern: const StrokePattern.dotted(),
                      ),
                    ],
                  ),
                MarkerLayer(markers: _buildMarkers()),
                const SimpleAttributionWidget(
                  source: Text('OpenStreetMap'),
                  onTap: null,
                ),
              ],
            ),
            // Route-loading indicator (small pill in top-right)
            if (_routeLoading)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Loading route…',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            // PRD §5A — Fullscreen expand button
            if (widget.showFullscreenButton)
              Positioned(
                bottom: 10,
                right: 10,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  elevation: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _FullscreenMapPage(
                          pickupLat: widget.pickupLat,
                          pickupLng: widget.pickupLng,
                          destinationLat: widget.destinationLat,
                          destinationLng: widget.destinationLng,
                          driverLat: widget.driverLat,
                          driverLng: widget.driverLng,
                          driverHasArrived: widget.driverHasArrived,
                        ),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(Icons.fullscreen_rounded, size: 20, color: Color(0xFF334155)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen map page for expanded navigation view.
/// Pushed modally when the driver taps the fullscreen button on LiveMap.
class _FullscreenMapPage extends StatelessWidget {
  final double? pickupLat, pickupLng, destinationLat, destinationLng, driverLat, driverLng;
  final bool driverHasArrived;

  const _FullscreenMapPage({
    this.pickupLat, this.pickupLng,
    this.destinationLat, this.destinationLng,
    this.driverLat, this.driverLng,
    this.driverHasArrived = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            LiveMap(
              pickupLat: pickupLat,
              pickupLng: pickupLng,
              destinationLat: destinationLat,
              destinationLng: destinationLng,
              driverLat: driverLat,
              driverLng: driverLng,
              height: MediaQuery.of(context).size.height,
              showRoute: true,
              driverHasArrived: driverHasArrived,
            ),
            // Close/Done button
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                elevation: 4,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fullscreen_exit_rounded, size: 18, color: Color(0xFF334155)),
                        SizedBox(width: 6),
                        Text('Done', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Animated pulsing blue dot for the driver's current position.
class _DriverDot extends StatefulWidget {
  @override
  State<_DriverDot> createState() => _DriverDotState();
}

class _DriverDotState extends State<_DriverDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            Container(
              width: 44 * _pulse.value,
              height: 44 * _pulse.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.18 * _pulse.value),
              ),
            ),
            // Core dot
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.electric_rickshaw,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _MapPin({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        // Drop shadow tail
        Container(
          width: 3,
          height: 6,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
