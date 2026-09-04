import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/route_model.dart';

class VroomMapWidget extends StatelessWidget {
  final MapController? mapController;
  final LatLng initialCenter;
  final double initialZoom;
  final RouteOption? primaryRoute;
  final List<RouteOption> alternateRoutes;
  final LatLng? pickupPoint;
  final LatLng? dropoffPoint;
  final LatLng? riderLocation;
  final String? vehicleType;
  final bool showControls;

  const VroomMapWidget({
    super.key,
    this.mapController,
    this.initialCenter = const LatLng(22.3750, 91.8350), // Chattogram center
    this.initialZoom = 11.5,
    this.primaryRoute,
    this.alternateRoutes = const [],
    this.pickupPoint,
    this.dropoffPoint,
    this.riderLocation,
    this.vehicleType,
    this.showControls = true,
  });

  @override
  Widget build(BuildContext context) {
    // Generate polylines
    final List<Polyline> polylines = [];

    // Alternate routes (drawn first so primary sits on top)
    for (final alt in alternateRoutes) {
      if (alt.isSelected && alt.polyline.isNotEmpty) {
        polylines.add(
          Polyline(
            points: alt.polyline,
            strokeWidth: 4.5,
            color: VroomColors.secondary.withValues(alpha: 0.9),
            pattern: StrokePattern.dashed(segments: const [12, 6]),
          ),
        );
      }
    }

    // Primary route (solid Leaf Green)
    if (primaryRoute != null && primaryRoute!.polyline.isNotEmpty) {
      polylines.add(
        Polyline(
          points: primaryRoute!.polyline,
          strokeWidth: 5.5,
          color: VroomColors.primary,
        ),
      );
    }

    // Generate markers
    final List<Marker> markers = [];

    // Primary Origin & Destination markers
    if (primaryRoute != null && primaryRoute!.polyline.isNotEmpty) {
      final start = primaryRoute!.polyline.first;
      final end = primaryRoute!.polyline.last;

      markers.add(
        Marker(
          point: start,
          width: 36,
          height: 36,
          child: _buildPin(label: 'A', color: VroomColors.primary, icon: Icons.trip_origin),
        ),
      );

      markers.add(
        Marker(
          point: end,
          width: 36,
          height: 36,
          child: _buildPin(label: 'B', color: VroomColors.text, icon: Icons.place),
        ),
      );
    }

    // Passenger Pickup & Dropoff markers
    if (pickupPoint != null) {
      markers.add(
        Marker(
          point: pickupPoint!,
          width: 36,
          height: 36,
          child: _buildPin(label: 'P', color: VroomColors.accent, icon: Icons.person_pin_circle),
        ),
      );
    }

    if (dropoffPoint != null) {
      markers.add(
        Marker(
          point: dropoffPoint!,
          width: 36,
          height: 36,
          child: _buildPin(label: 'D', color: VroomColors.danger, icon: Icons.flag),
        ),
      );
    }

    // Rider live location marker
    if (riderLocation != null) {
      markers.add(
        Marker(
          point: riderLocation!,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: VroomColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: VroomColors.primary, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              vehicleType == 'Car' ? Icons.directions_car : Icons.two_wheeler,
              color: VroomColors.primary,
              size: 24,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            minZoom: 5,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.vroom.app',
            ),
            PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),

        // Route Legend Badge (Top Left)
        if (primaryRoute != null || alternateRoutes.isNotEmpty)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: VroomColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: VroomColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 4,
                    decoration: BoxDecoration(
                      color: VroomColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text('Primary', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  if (alternateRoutes.any((r) => r.isSelected)) ...[
                    const SizedBox(width: 10),
                    Container(
                      width: 14,
                      height: 4,
                      decoration: BoxDecoration(
                        color: VroomColors.secondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('Alternate Corridors', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPin({required String label, required Color color, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
