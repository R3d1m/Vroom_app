import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/booking_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/vroom_provider.dart';
import '../widgets/vroom_map_widget.dart';
import '../widgets/verification_badge.dart';
import '../passenger/payment_sheet.dart';

class OngoingTripScreen extends StatefulWidget {
  final String bookingId;

  const OngoingTripScreen({super.key, required this.bookingId});

  @override
  State<OngoingTripScreen> createState() => _OngoingTripScreenState();
}

class _OngoingTripScreenState extends State<OngoingTripScreen> {
  bool _hasPromptedPayment = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();
    final isRider = provider.activeMode == UserRoleMode.rider;

    final booking = provider.bookings.firstWhere(
      (b) => b.id == widget.bookingId,
      orElse: () => provider.bookings.isNotEmpty
          ? provider.bookings.first
          : throw Exception('No booking found'),
    );

    final isTripCompleted = booking.tripStatus == TripLifecycleStatus.completed;
    final isUnpaid = booking.paymentStatus != PaymentStatus.paid;

    // Auto-prompt payment sheet for passenger when ride is completed
    if (!isRider && isTripCompleted && isUnpaid && !_hasPromptedPayment) {
      _hasPromptedPayment = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => PaymentRatingSheet(bookingId: booking.id),
          ).then((_) {
            if (mounted) {
              setState(() => _hasPromptedPayment = false);
            }
          });
        }
      });
    }

    final ridePost = provider.ridePosts.firstWhere(
      (r) => r.id == booking.ridePostId,
      orElse: () => provider.ridePosts.first,
    );

    final List<LatLng> poly = ridePost.primaryRoute.polyline;
    final LatLng currentRiderPos = poly.isNotEmpty
        ? poly[0]
        : booking.pickup.coordinates;

    final otherUser = isRider ? booking.passenger : booking.rider;
    final isTripInProgress = booking.tripStatus == TripLifecycleStatus.inProgress;

    return Scaffold(
      backgroundColor: VroomColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTripCompleted ? 'Trip Completed' : 'Trip in Progress',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            Text(
              '${booking.pickup.name.split(" ")[0]} → ${booking.dropoff.name.split(" ")[0]}',
              style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
            ),
          ],
        ),
        backgroundColor: VroomColors.surface,
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
          // Live Map Display
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

          // User Header Card (Passenger sees Rider info; Rider sees Passenger info)
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
                          otherUser.name.isNotEmpty ? otherUser.name[0] : 'U',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: VroomColors.text),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRider ? 'Passenger: ${otherUser.name}' : 'Rider: ${otherUser.name}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            Text(
                              isRider
                                  ? otherUser.universityOrOrg
                                  : (booking.rider.vehicleModel != null && booking.rider.vehicleModel!.isNotEmpty
                                      ? '${booking.rider.vehicleModel}${booking.rider.vehiclePlate != null ? " • ${booking.rider.vehiclePlate}" : ""}'
                                      : 'Verified Rider • ${otherUser.universityOrOrg}'),
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
                            Text(
                              isRider ? 'VERIFY PIN' : 'OTP PIN',
                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: VroomColors.textMuted),
                            ),
                            Text(
                              booking.pinCode,
                              style: const TextStyle(
                                fontSize: 15,
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
                        nidStatus: otherUser.nidStatus,
                        studentIdStatus: otherUser.studentIdStatus,
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _openChatDialog(context, otherUser.name),
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
                  const SizedBox(height: 10),
                  // Contact Details Shared Between Rider & Passenger
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: VroomColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: VroomColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: VroomColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRider ? 'Passenger Contact' : 'Rider Contact',
                                style: const TextStyle(fontSize: 10, color: VroomColors.textMuted, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                otherUser.phone.isNotEmpty ? otherUser.phone : '+880 1812-345678',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VroomColors.text),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VroomColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _showCallDialog(context, otherUser.name, otherUser.phone),
                          icon: const Icon(Icons.phone_in_talk, size: 14),
                          label: const Text('Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet: Status & Role-based Controls
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
                    // Status & Fare
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live Trip Status',
                              style: TextStyle(color: VroomColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              booking.tripStatus == TripLifecycleStatus.confirmed
                                  ? 'Heading to Pickup'
                                  : (booking.tripStatus == TripLifecycleStatus.inProgress
                                      ? 'On Route to Destination'
                                      : 'Arrived at Destination'),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: VroomColors.text),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '৳${booking.fare.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: VroomColors.text),
                            ),
                            Text(
                              booking.paymentStatus == PaymentStatus.paid ? 'PAID' : 'UNPAID',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: booking.paymentStatus == PaymentStatus.paid ? VroomColors.primary : VroomColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Controls Section
                    if (isRider) ...[
                      // RIDER CONTROLS
                      if (booking.tripStatus == TripLifecycleStatus.confirmed)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VroomColors.text,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () {
                            provider.updateTripStatus(booking.id, TripLifecycleStatus.inProgress);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Trip marked as In Progress! Safe travels.'),
                                backgroundColor: VroomColors.text,
                              ),
                            );
                          },
                          child: const Text('Start Trip (Picked Up Passenger)'),
                        )
                      else if (isTripInProgress)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VroomColors.primary,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () {
                            // Only Rider can mark trip completed
                            provider.updateTripStatus(booking.id, TripLifecycleStatus.completed);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ride marked as completed! Passenger will be prompted for payment.'),
                                backgroundColor: VroomColors.primary,
                              ),
                            );
                          },
                          child: const Text('Complete Ride'),
                        )
                      else if (isTripCompleted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: VroomColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: VroomColors.primary),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: VroomColors.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  booking.paymentStatus == PaymentStatus.paid
                                      ? 'Ride Completed & Payment of ৳${booking.fare.toStringAsFixed(0)} Received!'
                                      : 'Ride Completed! Waiting for passenger fuel payment (৳${booking.fare.toStringAsFixed(0)}).',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: VroomColors.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (booking.paymentStatus == PaymentStatus.paid) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              side: const BorderSide(color: VroomColors.border),
                            ),
                            icon: const Icon(Icons.check, size: 18, color: VroomColors.primary),
                            label: const Text('Ride Completed — Back to Home', style: TextStyle(fontWeight: FontWeight.w700, color: VroomColors.text)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ],
                    ] else ...[
                      // PASSENGER CONTROLS & STATUS
                      if (!isTripCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: VroomColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: VroomColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: VroomColors.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  booking.tripStatus == TripLifecycleStatus.confirmed
                                      ? 'Rider is on the way to pick you up. Please verify the 4-digit PIN upon boarding.'
                                      : 'Ride is currently ongoing. Your rider will complete the trip upon reaching your drop-off.',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VroomColors.text),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Trip is completed: Show Payment & Rating Button to passenger!
                        if (booking.paymentStatus != PaymentStatus.paid)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VroomColors.primary,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => PaymentRatingSheet(bookingId: booking.id),
                              );
                            },
                            icon: const Icon(Icons.payment, size: 18),
                            label: Text('Pay ৳${booking.fare.toStringAsFixed(0)} & Rate Rider'),
                          )
                        else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: VroomColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: VroomColors.primary),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: VroomColors.primary, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Payment completed! Thank you for sharing the ride and splitting fuel costs.',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: VroomColors.text),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              side: const BorderSide(color: VroomColors.border),
                            ),
                            icon: const Icon(Icons.history, size: 18, color: VroomColors.primary),
                            label: const Text('Ride Completed — View History', style: TextStyle(fontWeight: FontWeight.w700, color: VroomColors.text)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ],
                    ],
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
          'Your live GPS coordinates and trip details will be transmitted to Campus Security & 999 Helpline.',
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
                  content: Text('🚨 Emergency alert transmitted to security dispatch.'),
                  backgroundColor: VroomColors.danger,
                ),
              );
            },
            child: const Text('Transmit SOS'),
          ),
        ],
      ),
    );
  }

  void _showCallDialog(BuildContext context, String userName, String phone) {
    final phoneNumber = phone.isNotEmpty ? phone : '+880 1812-345678';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.phone_forwarded, color: VroomColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('Call $userName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Verified Contact Number:', style: TextStyle(fontSize: 12, color: VroomColors.textMuted)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: VroomColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: VroomColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    phoneNumber,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: VroomColors.text),
                  ),
                  const Icon(Icons.verified, color: VroomColors.primary, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Coordinate your exact pickup landmark or arrival time safely.',
              style: TextStyle(fontSize: 11, color: VroomColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: VroomColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📞 Connecting call to $userName ($phoneNumber)...'),
                  backgroundColor: VroomColors.text,
                ),
              );
            },
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Call Now'),
          ),
        ],
      ),
    );
  }

  void _openChatDialog(BuildContext context, String userName) {
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
              Text('In-App Chat with $userName', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    _buildChatBubble('Hello! I am standing near the gate.', isMe: true),
                    _buildChatBubble('Got it! On the way, wearing helmet and jacket.', isMe: false),
                  ],
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type message...',
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
