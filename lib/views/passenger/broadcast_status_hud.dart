import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/trip_request.dart';
import '../../core/data/mock_data.dart';
import '../../core/providers/vroom_provider.dart';
import '../shared/ongoing_trip_screen.dart';

class BroadcastStatusHud extends StatelessWidget {
  final String requestId;

  const BroadcastStatusHud({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();
    final groupReq = provider.allGroupRequests.firstWhere(
      (g) => g.id == requestId,
      orElse: () => GroupTripRequest(
        id: 'none',
        passenger: provider.currentUser,
        pickup: VroomMockData.cuetCampus,
        dropoff: VroomMockData.gecCircle,
        scheduledDeparture: DateTime.now(),
        subRequests: [],
      ),
    );

    final isConfirmed = groupReq.status == GroupRequestStatus.accepted;
    final isCancelled = groupReq.status == GroupRequestStatus.cancelled;
    final isPending = groupReq.status == GroupRequestStatus.pending;

    // Find confirmed booking if accepted
    final activeBooking = provider.activeBooking;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Request Status'),
        actions: [
          if (isPending)
            TextButton(
              onPressed: () {
                provider.cancelGroupRequest(requestId);
                Navigator.pop(context);
              },
              child: const Text('Cancel Broadcast', style: TextStyle(color: VroomColors.danger, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isConfirmed ? VroomColors.text : VroomColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isConfirmed ? VroomColors.primary : VroomColors.border,
                  width: isConfirmed ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isConfirmed
                              ? VroomColors.primary
                              : (isCancelled ? VroomColors.danger : VroomColors.surfaceMuted),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isConfirmed
                              ? Icons.check_circle
                              : (isCancelled ? Icons.cancel : Icons.radar),
                          color: isConfirmed ? Colors.white : (isCancelled ? Colors.white : VroomColors.primary),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isConfirmed
                                  ? 'RIDE CONFIRMED!'
                                  : (isCancelled ? 'Broadcast Cancelled' : 'Awaiting Rider Response'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isConfirmed ? Colors.white : VroomColors.text,
                              ),
                            ),
                            Text(
                              isConfirmed
                                  ? 'Seat locked. Sibling requests automatically cancelled.'
                                  : 'Broadcasting to ${groupReq.totalRidersTargeted} matching riders along your route.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isConfirmed ? Colors.white70 : VroomColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Route & Time info
                  Row(
                    children: [
                      const Icon(Icons.trip_origin, size: 16, color: VroomColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          groupReq.pickup.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isConfirmed ? Colors.white : VroomColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16, color: VroomColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          groupReq.dropoff.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isConfirmed ? Colors.white : VroomColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scheduled: ${DateFormat('EEE, MMM d • hh:mm a').format(groupReq.scheduledDeparture)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isConfirmed ? VroomColors.secondary : VroomColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live Riders Status List
            const Text(
              'Targeted Riders in Corridor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: VroomColors.text),
            ),
            const SizedBox(height: 4),
            const Text(
              'When any rider accepts, all other requests instantly auto-cancel.',
              style: TextStyle(fontSize: 12, color: VroomColors.textMuted),
            ),
            const SizedBox(height: 12),

            ...groupReq.subRequests.map((sub) {
              return _buildSubRequestTile(sub);
            }),

            const SizedBox(height: 24),

            // Action CTA & Contact Card when confirmed
            if (isConfirmed && activeBooking != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: VroomColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VroomColors.primary, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.contact_phone, size: 16, color: VroomColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Rider Contact Details Shared',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: VroomColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: VroomColors.surfaceMuted,
                          child: Text(
                            activeBooking.rider.name.isNotEmpty ? activeBooking.rider.name[0] : 'R',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: VroomColors.text),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeBooking.rider.name,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              Text(
                                activeBooking.rider.phone.isNotEmpty ? activeBooking.rider.phone : '+880 1812-345678',
                                style: const TextStyle(fontSize: 12, color: VroomColors.textMuted, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VroomColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            final phone = activeBooking.rider.phone.isNotEmpty ? activeBooking.rider.phone : '+880 1812-345678';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📞 Calling rider ${activeBooking.rider.name} ($phone)...'),
                                backgroundColor: VroomColors.text,
                              ),
                            );
                          },
                          icon: const Icon(Icons.call, size: 14),
                          label: const Text('Call Rider', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: VroomColors.primary,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OngoingTripScreen(bookingId: activeBooking.id),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_bike),
                    SizedBox(width: 8),
                    Text('View Active Trip & Live Tracking'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubRequestTile(SubRequestItem sub) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (sub.status) {
      case SubRequestStatus.pending:
        statusColor = VroomColors.warning;
        statusLabel = 'Pending Review';
        statusIcon = Icons.hourglass_empty;
        break;
      case SubRequestStatus.accepted:
        statusColor = VroomColors.primary;
        statusLabel = 'ACCEPTED & CONFIRMED';
        statusIcon = Icons.check_circle;
        break;
      case SubRequestStatus.autoCancelled:
        statusColor = VroomColors.textMuted;
        statusLabel = 'Auto-Cancelled';
        statusIcon = Icons.remove_circle_outline;
        break;
      case SubRequestStatus.declined:
        statusColor = VroomColors.danger;
        statusLabel = 'Declined';
        statusIcon = Icons.cancel;
        break;
    }

    final isWinner = sub.status == SubRequestStatus.accepted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWinner ? VroomColors.primary.withValues(alpha: 0.1) : VroomColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWinner ? VroomColors.primary : VroomColors.border,
          width: isWinner ? 1.8 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: VroomColors.surfaceMuted,
            child: Icon(
              sub.vehicleType == 'Car' ? Icons.directions_car : Icons.two_wheeler,
              size: 18,
              color: VroomColors.text,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.riderName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  '${sub.vehicleModel} • ৳${sub.fare.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                ),
                if (sub.cancellationReason != null)
                  Text(
                    sub.cancellationReason!,
                    style: const TextStyle(fontSize: 10, color: VroomColors.textMuted, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
