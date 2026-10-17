import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/booking_model.dart';
import '../../core/providers/vroom_provider.dart';
import '../widgets/vroom_map_widget.dart';
import '../widgets/verification_badge.dart';
import 'payment_sheet.dart';

class ActiveTripScreen extends StatefulWidget {
  final String bookingId;

  const ActiveTripScreen({super.key, required this.bookingId});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  // Simulated rider moving position
  final int _simulationStep = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();
    final booking = provider.bookings.firstWhere(
      (b) => b.id == widget.bookingId,
      orElse: () => provider.bookings.isNotEmpty ? provider.bookings.first : throw Exception('No booking'),
    );

    // Ride post details if available
    final ridePost = provider.ridePosts.firstWhere(
      (r) => r.id == booking.ridePostId,
      orElse: () => provider.ridePosts.first,
    );

    // Simulated moving coordinates for rider
    final List<LatLng> poly = ridePost.primaryRoute.polyline;
    final LatLng currentRiderPos = poly.isNotEmpty
        ? poly[(_simulationStep).clamp(0, poly.length - 1)]
        : booking.pickup.coordinates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Ride Tracking'),
        actions: [
          // Emergency SOS Button
          IconButton(
            onPressed: () => _showSosDialog(context),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: VroomColors.danger,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Live Map
          VroomMapWidget(
            initialCenter: booking.pickup.coordinates,
            initialZoom: 13.0,
            primaryRoute: ridePost.primaryRoute,
            alternateRoutes: ridePost.alternateRoutes,
            pickupPoint: booking.pickup.coordinates,
            dropoffPoint: booking.dropoff.coordinates,
            riderLocation: currentRiderPos,
            vehicleType: booking.rider.vehicleType ?? 'Motorcycle',
          ),

          // Top Rider Profile Card
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: VroomColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VroomColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: VroomColors.surfaceMuted,
                        child: Text(
                          booking.rider.name[0],
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: VroomColors.text),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.rider.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            Text(
                              '${booking.rider.vehicleModel ?? "Bike"} • ${booking.rider.vehiclePlate ?? "Chatto Metro-Ha"}',
                              style: const TextStyle(color: VroomColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // 4-Digit Security PIN Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: VroomColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: VroomColors.primary, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Text('OTP PIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: VroomColors.textMuted)),
                            Text(
                              booking.pinCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: VroomColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      VerificationBadge(
                        nidStatus: booking.rider.nidStatus,
                        studentIdStatus: booking.rider.studentIdStatus,
                      ),
                      const Spacer(),
                      // In-app chat button
                      InkWell(
                        onTap: () => _openChatDialog(context, booking.rider.name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: VroomColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: VroomColors.border),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 14, color: VroomColors.text),
                              SizedBox(width: 4),
                              Text('In-App Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Trip Status & Completion Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: VroomColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Trip Status', style: TextStyle(color: VroomColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                            Text(
                              booking.tripStatus == TripLifecycleStatus.confirmed
                                  ? 'Rider is on the way'
                                  : (booking.tripStatus == TripLifecycleStatus.inProgress
                                      ? 'On Route to Destination'
                                      : 'Arrived at Destination'),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: VroomColors.text),
                            ),
                          ],
                        ),
                        Text(
                          '৳${booking.fare.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: VroomColors.text),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          provider.updateTripStatus(booking.id, TripLifecycleStatus.completed);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => PaymentRatingSheet(bookingId: booking.id),
                          );
                        },
                        child: const Text('Complete & Pay'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield, color: VroomColors.danger),
            SizedBox(width: 8),
            Text('Emergency SOS'),
          ],
        ),
        content: const Text(
          'Your live GPS coordinates and rider details will be instantly shared with CUET Campus Security and National Emergency Helpline (999).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: VroomColors.danger),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚨 Emergency alert transmitted to emergency contacts.'),
                  backgroundColor: VroomColors.danger,
                ),
              );
            },
            child: const Text('Send Alert Now'),
          ),
        ],
      ),
    );
  }

  void _openChatDialog(BuildContext context, String riderName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: 380,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chat with $riderName', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    _buildChatBubble('Hello! I am waiting near the CUET Main Gate.', isMe: true),
                    _buildChatBubble('Great, I am wearing a black helmet and Yamaha FZ. Arriving in 3 mins.', isMe: false),
                  ],
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.send, color: VroomColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, {required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? VroomColors.primary.withValues(alpha: 0.15) : VroomColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isMe ? VroomColors.primary : VroomColors.border),
        ),
        child: Text(text, style: const TextStyle(fontSize: 13, color: VroomColors.text)),
      ),
    );
  }
}
