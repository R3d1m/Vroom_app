import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/vroom_provider.dart';
import '../widgets/verification_badge.dart';
import '../widgets/vroom_map_widget.dart';
import '../rider/rider_requests_screen.dart';
import '../passenger/broadcast_status_hud.dart';

class RideDetailScreen extends StatelessWidget {
  final String ridePostId;

  const RideDetailScreen({super.key, required this.ridePostId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();
    final isRider = provider.activeMode == UserRoleMode.rider;

    final ridePost = provider.ridePosts.firstWhere(
      (r) => r.id == ridePostId,
      orElse: () => provider.ridePosts.first,
    );

    final isMyRide = ridePost.rider.id == provider.currentUser.id;

    // Check if current passenger has pending requests or bookings on this ride
    final pendingRequestsOnThisRide = provider.allGroupRequests.where(
      (g) => g.subRequests.any((s) => s.ridePostId == ridePost.id),
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isRider && isMyRide ? 'My Scheduled Trip Details' : 'Ride Post Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map with Primary and Alternate Corridors
            SizedBox(
              height: 250,
              child: VroomMapWidget(
                initialCenter: ridePost.origin.coordinates,
                initialZoom: 11.5,
                primaryRoute: ridePost.primaryRoute,
                alternateRoutes: ridePost.alternateRoutes,
                pickupPoint: ridePost.origin.coordinates,
                dropoffPoint: ridePost.destination.coordinates,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Schedule & Status Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: VroomColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ridePost.status.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: VroomColors.primary,
                          ),
                        ),
                      ),
                      Text(
                        '৳${ridePost.farePerSeat.toStringAsFixed(0)} / seat',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: VroomColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Route Title & Departure Time
                  Text(
                    '${ridePost.origin.name} → ${ridePost.destination.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: VroomColors.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: VroomColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy • hh:mm a').format(ridePost.departureTime),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: VroomColors.text,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Rider Profile Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VroomColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: VroomColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: VroomColors.surfaceMuted,
                              child: Text(
                                ridePost.rider.name[0],
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: VroomColors.text),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        ridePost.rider.name,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: VroomColors.surfaceMuted,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star, size: 12, color: VroomColors.warning),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${ridePost.rider.rating}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ridePost.rider.universityOrOrg,
                                    style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        VerificationBadge(
                          nidStatus: ridePost.rider.nidStatus,
                          studentIdStatus: ridePost.rider.studentIdStatus,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Specifications
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VroomColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: VroomColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Vehicle Information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        const Divider(height: 16),
                        _buildInfoRow('Type & Model', '${ridePost.vehicleType} • ${ridePost.vehicleModel}'),
                        _buildInfoRow('License Plate', ridePost.vehiclePlate),
                        _buildInfoRow('Seats Capacity', '${ridePost.availableSeats} of ${ridePost.totalSeats} seats available'),
                        _buildInfoRow('Detour Tolerance', 'Up to ${ridePost.detourToleranceKm} km along route'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Route Corridor Details
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VroomColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: VroomColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Route & Alternate Corridors', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        const Divider(height: 16),
                        Row(
                          children: [
                            Container(width: 10, height: 10, decoration: const BoxDecoration(color: VroomColors.primary, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Primary: ${ridePost.primaryRoute.name} (${ridePost.primaryRoute.viaRoadName})',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        if (ridePost.alternateRoutes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...ridePost.alternateRoutes.map((alt) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: VroomColors.secondary, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Alternate: ${alt.name} (${alt.viaRoadName})',
                                      style: const TextStyle(fontSize: 12, color: VroomColors.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Action Buttons depending on role
                  if (isRider && isMyRide) ...[
                    // Rider Options
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: VroomColors.text,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RiderRequestsScreen()),
                        );
                      },
                      icon: const Icon(Icons.inbox, size: 18),
                      label: Text('View Booking Requests (${pendingRequestsOnThisRide.length})'),
                    ),
                  ] else ...[
                    // Passenger Options
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: VroomColors.primary,
                      ),
                      onPressed: ridePost.availableSeats <= 0
                          ? null
                          : () {
                              provider.sendGroupRequest(
                                pickup: ridePost.origin,
                                dropoff: ridePost.destination,
                                scheduledDeparture: ridePost.departureTime,
                                targetRides: [ridePost],
                              );
                              final activeReq = provider.activeGroupRequest;
                              if (activeReq != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BroadcastStatusHud(requestId: activeReq.id),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.send, size: 18),
                      label: Text(
                        ridePost.availableSeats > 0 ? 'Request Seat on this Ride' : 'Ride Full',
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: VroomColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: VroomColors.text)),
        ],
      ),
    );
  }
}
