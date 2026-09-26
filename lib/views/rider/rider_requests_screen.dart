import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/trip_request.dart';
import '../../core/models/ride_post.dart';
import '../../core/providers/vroom_provider.dart';
import '../widgets/verification_badge.dart';

class RiderRequestsScreen extends StatelessWidget {
  const RiderRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();
    final pendingRequests = provider.getPendingRequestsForRider(provider.currentUser.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Booking Requests'),
      ),
      body: pendingRequests.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingRequests.length,
              itemBuilder: (context, index) {
                final item = pendingRequests[index];
                final GroupTripRequest groupReq = item['groupRequest'];
                final SubRequestItem sub = item['subRequest'];
                final RidePost ridePost = item['ridePost'];

                return _buildRequestCard(context, provider, groupReq, sub, ridePost);
              },
            ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    VroomProvider provider,
    GroupTripRequest groupReq,
    SubRequestItem sub,
    RidePost ridePost,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: VroomColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VroomColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Passenger Profile Row
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: VroomColors.surfaceMuted,
                  child: Text(
                    groupReq.passenger.name[0],
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: VroomColors.text),
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
                            groupReq.passenger.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: VroomColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 12, color: VroomColors.warning),
                                const SizedBox(width: 2),
                                Text(
                                  '${groupReq.passenger.rating}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        groupReq.passenger.universityOrOrg,
                        style: const TextStyle(color: VroomColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Broadcast Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: VroomColors.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: VroomColors.primary, width: 1),
                  ),
                  child: const Text(
                    'BROADCAST',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: VroomColors.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Verification Badges
            VerificationBadge(
              nidStatus: groupReq.passenger.nidStatus,
              studentIdStatus: groupReq.passenger.studentIdStatus,
            ),
            const Divider(height: 20),

            // Pickup & Destination info
            Row(
              children: [
                const Icon(Icons.trip_origin, size: 16, color: VroomColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pickup Location', style: TextStyle(fontSize: 10, color: VroomColors.textMuted, fontWeight: FontWeight.w600)),
                      Text(
                        groupReq.pickup.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place, size: 16, color: VroomColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Destination', style: TextStyle(fontSize: 10, color: VroomColors.textMuted, fontWeight: FontWeight.w600)),
                      Text(
                        groupReq.dropoff.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Scheduled time & Seat/Fare details
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VroomColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trip: ${DateFormat('EEE, MMM d • hh:mm a').format(groupReq.scheduledDeparture)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Offer: ৳${(ridePost.farePerSeat * groupReq.requestedSeats).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: VroomColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                // Decline Button
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VroomColors.danger,
                      side: const BorderSide(color: VroomColors.border),
                    ),
                    onPressed: () {
                      provider.declineRideRequest(
                        groupRequestId: groupReq.id,
                        ridePostId: ridePost.id,
                      );
                    },
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),

                // Accept Button (Triggers atomic auto-cancellation of other requests!)
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VroomColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      provider.acceptRideRequest(
                        groupRequestId: groupReq.id,
                        ridePostId: ridePost.id,
                        acceptingRider: provider.currentUser,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Accepted! ${groupReq.passenger.name} has been confirmed. Sibling requests auto-cancelled.'),
                          backgroundColor: VroomColors.text,
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 18),
                        SizedBox(width: 6),
                        Text('Accept Request'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: VroomColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined, size: 40, color: VroomColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'No pending requests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'When passengers broadcast ride requests along your route, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: VroomColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
