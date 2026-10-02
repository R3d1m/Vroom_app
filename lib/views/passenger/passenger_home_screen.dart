import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/route_model.dart';
import '../../core/models/booking_model.dart';
import '../../core/data/mock_data.dart';
import '../../core/providers/vroom_provider.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/vroom_map_widget.dart';
import '../shared/ongoing_trip_screen.dart';
import 'search_results_screen.dart';
import 'broadcast_status_hud.dart';
import 'payment_sheet.dart';
import '../shared/ride_history_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  LocationPoint _pickup = VroomMockData.cuetCampus;
  LocationPoint _dropoff = VroomMockData.gecCircle;
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  bool _hasAutoPromptedPayment = false;

  // Read-only reference fare estimation state (no input needed from passenger)
  double _estimatedFare = 245.0;
  double _distanceKm = 24.5;
  String _weather = 'clear';
  bool _isLoadingFare = false;

  @override
  void initState() {
    super.initState();
    _calculateFareEstimate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VroomProvider>().loadRidesFromBackend();
        context.read<VroomProvider>().loadBookingsFromBackend();
      }
    });
  }

  void _calculateFareEstimate() async {
    const distCalc = Distance();
    final straight = distCalc.as(LengthUnit.Kilometer, _pickup.coordinates, _dropoff.coordinates);
    _distanceKm = straight > 0 ? double.parse((straight * 1.35).toStringAsFixed(1)) : 24.5;
    
    // Immediate formula base: 50tk for 0-5km, +10tk for each additional km
    final base = _distanceKm <= 5.0 ? 50.0 : 50.0 + (_distanceKm - 5.0) * 10.0;
    if (mounted) {
      setState(() {
        _estimatedFare = base;
        _isLoadingFare = true;
      });
    }

    try {
      final res = await context.read<VroomProvider>().estimateFare(
        distanceKm: _distanceKm,
        origin: _pickup.name,
        destination: _dropoff.name,
        originLat: _pickup.coordinates.latitude,
        originLng: _pickup.coordinates.longitude,
      );
      if (mounted) {
        setState(() {
          _isLoadingFare = false;
          _estimatedFare = (res['estimated_fare'] as num?)?.toDouble() ?? base;
          _weather = res['weather']?.toString().toLowerCase() ?? 'clear';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingFare = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();
    final pendingReq = provider.pendingPassengerRequest;
    final activeBookings = provider.passengerActiveBookings;
    final activeBooking = provider.activeBooking;
    final pendingPayment = provider.pendingPaymentBooking;

    // Automatically prompt payment bottom sheet when trip completes
    if (pendingPayment != null && !_hasAutoPromptedPayment) {
      _hasAutoPromptedPayment = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => PaymentRatingSheet(bookingId: pendingPayment.id),
          ).then((_) {
            if (mounted) {
              setState(() => _hasAutoPromptedPayment = false);
            }
          });
        }
      });
    }

    return Scaffold(
      appBar: const VroomTopBar(),
      body: Stack(
        children: [
          // Background Interactive Map
          VroomMapWidget(
            initialCenter: const LatLng(22.3950, 91.8600),
            initialZoom: 11.2,
            pickupPoint: _pickup.coordinates,
            dropoffPoint: _dropoff.coordinates,
          ),

          // 1. Pending Payment Due Banner (Prompted when rider completes trip)
          if (pendingPayment != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => PaymentRatingSheet(bookingId: pendingPayment.id),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: VroomColors.text,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: VroomColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: VroomColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.payment, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trip Completed with ${pendingPayment.rider.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Tap to pay ৳${pendingPayment.fare.toStringAsFixed(0)} & rate your rider',
                              style: const TextStyle(
                                color: VroomColors.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VroomColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => PaymentRatingSheet(bookingId: pendingPayment.id),
                          );
                        },
                        child: const Text('Pay Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 2. Active Trip Banner (if ongoing)
          if (activeBooking != null && pendingPayment == null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OngoingTripScreen(bookingId: activeBooking.id),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: VroomColors.text,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: VroomColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.navigation, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Ongoing Ride with ${activeBooking.rider.name}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${activeBooking.tripStatus == TripLifecycleStatus.inProgress ? "In Progress" : "Confirmed"} • PIN: ${activeBooking.pinCode} • Tap for details',
                              style: const TextStyle(
                                color: VroomColors.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
            ),

          // Pending Booking / Broadcast Status Bar (if request active and no ongoing trip)
          if (pendingReq != null && activeBooking == null && pendingPayment == null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BroadcastStatusHud(requestId: pendingReq.id),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: VroomColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: VroomColors.warning, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: VroomColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ride Booking Pending',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            Text(
                              'Awaiting rider approval for ${pendingReq.pickup.name.split(" ")[0]} → ${pendingReq.dropoff.name.split(" ")[0]}',
                              style: const TextStyle(color: VroomColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'View HUD',
                        style: TextStyle(
                          color: VroomColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Search & Corridor Selector Card
          DraggableScrollableSheet(
            initialChildSize: 0.46,
            minChildSize: 0.32,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: VroomColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: VroomColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 1. Pending Passenger Booking / Request (only when no active/ongoing booking)
                    if (pendingReq != null && activeBookings.isEmpty && pendingPayment == null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: VroomColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: VroomColors.warning, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: VroomColors.warning,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'AWAITING DRIVER APPROVAL',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: VroomColors.warning),
                                    ),
                                  ],
                                ),
                                Text(
                                  DateFormat('EEE, MMM d • hh:mm a').format(pendingReq.scheduledDeparture.toLocal()),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VroomColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${pendingReq.pickup.name} → ${pendingReq.dropoff.name}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: VroomColors.text),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Requested ${pendingReq.requestedSeats} seat(s) • Sent to ${pendingReq.totalRidersTargeted} matching rider(s)',
                              style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: VroomColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => BroadcastStatusHud(requestId: pendingReq.id)),
                                      );
                                    },
                                    icon: const Icon(Icons.bolt, size: 14),
                                    label: const Text('View Status HUD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    side: const BorderSide(color: VroomColors.danger),
                                  ),
                                  onPressed: () => provider.cancelGroupRequest(pendingReq.id),
                                  child: const Text('Cancel', style: TextStyle(color: VroomColors.danger, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 2. Confirmed Passenger Bookings
                    if (activeBookings.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Confirmed Bookings',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: VroomColors.text),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: VroomColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${activeBookings.length} Active',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: VroomColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...activeBookings.map((b) => Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: VroomColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: VroomColors.primary, width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: VroomColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    b.tripStatus == TripLifecycleStatus.inProgress ? 'RIDE IN PROGRESS' : 'BOOKING CONFIRMED',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: VroomColors.primary),
                                  ),
                                ),
                                Text(
                                  '৳${b.fare.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: VroomColors.text),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: VroomColors.surfaceMuted,
                                  child: Text(b.rider.name.isNotEmpty ? b.rider.name[0] : 'R', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(b.rider.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                      Text('${b.rider.phone} • ★ ${b.rider.rating}', style: const TextStyle(fontSize: 11, color: VroomColors.textMuted)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: VroomColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: VroomColors.primary, width: 1),
                                  ),
                                  child: Text(
                                    'PIN: ${b.pinCode}',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: VroomColors.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${b.pickup.name} → ${b.dropoff.name}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              DateFormat('EEE, MMM d • hh:mm a').format(b.scheduledTime.toLocal()),
                              style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: VroomColors.text,
                                minimumSize: const Size.fromHeight(38),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => OngoingTripScreen(bookingId: b.id)),
                                );
                              },
                              icon: const Icon(Icons.navigation, size: 14, color: Colors.white),
                              label: const Text('View Ride Details & Track', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ],
                        ),
                      )),
                      const Divider(height: 24),
                    ],

                    const Text(
                      'Find a Shared Ride',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: VroomColors.text,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'Join daily riders traveling your route & split costs',
                      style: TextStyle(color: VroomColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Pickup Location Dropdown/Field
                    _buildLocationPicker(
                      label: 'Pickup Point',
                      icon: Icons.trip_origin,
                      iconColor: VroomColors.primary,
                      currentValue: _pickup,
                      onChanged: (loc) {
                        setState(() => _pickup = loc);
                        _calculateFareEstimate();
                      },
                    ),
                    const SizedBox(height: 10),

                    // Dropoff Location Dropdown/Field
                    _buildLocationPicker(
                      label: 'Destination',
                      icon: Icons.place,
                      iconColor: VroomColors.text,
                      currentValue: _dropoff,
                      onChanged: (loc) {
                        setState(() => _dropoff = loc);
                        _calculateFareEstimate();
                      },
                    ),
                    const SizedBox(height: 12),

                    // Passenger Reference Estimated Fare (Read-only, no input)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: VroomColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: VroomColors.primary.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: VroomColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_awesome, color: VroomColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'AI Estimated Fair Fare',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VroomColors.textMuted),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: VroomColors.surfaceMuted,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Idea / Reference',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: VroomColors.textMuted),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '৳${_estimatedFare.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: VroomColors.text),
                                    ),
                                    const Text(
                                      ' / seat',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VroomColors.textMuted),
                                    ),
                                    if (_isLoadingFare) ...[
                                      const SizedBox(width: 8),
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: VroomColors.primary),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  '${_distanceKm.toStringAsFixed(1)} km • Base ৳50 + ৳10/km • Open-Meteo: ${_weather == "rain" ? "🌧️ Rain (×1.25)" : "☀️ Clear"}',
                                  style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Travel Date Picker (No time needed!)
                    InkWell(
                      onTap: _pickDepartureDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: VroomColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: VroomColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 20, color: VroomColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date of Travel',
                                    style: TextStyle(
                                      color: VroomColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDateLabel(_selectedDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: VroomColors.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: VroomColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Select Date',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: VroomColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Button: Search Rides along Route
                    ElevatedButton(
                      onPressed: () {
                        context.read<VroomProvider>().loadRidesFromBackend();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchResultsScreen(
                              pickup: _pickup,
                              dropoff: _dropoff,
                              travelDate: _selectedDate,
                            ),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 20),
                          SizedBox(width: 8),
                          Text('Search Route Matches'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Popular Campus & Commuter Corridors Chips
                    const Text(
                      'Popular Corridor Shortcuts',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: VroomColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCorridorChip(
                          'CUET ⇄ GEC Circle',
                          VroomMockData.cuetCampus,
                          VroomMockData.gecCircle,
                        ),
                        _buildCorridorChip(
                          'Oxygen ⇄ Agrabad',
                          VroomMockData.oxygen,
                          VroomMockData.agrabad,
                        ),
                        _buildCorridorChip(
                          'CU ⇄ New Market',
                          VroomMockData.cuCampus,
                          VroomMockData.newMarket,
                        ),
                        _buildCorridorChip(
                          'Muradpur ⇄ 2 No Gate',
                          VroomMockData.muradpur,
                          VroomMockData.no2Gate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RideHistoryScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: VroomColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: VroomColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.history, size: 20, color: VroomColors.primary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Ride History & Past Receipts',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VroomColors.text),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 14, color: VroomColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPicker({
    required String label,
    required IconData icon,
    required Color iconColor,
    required LocationPoint currentValue,
    required ValueChanged<LocationPoint> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: VroomColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VroomColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<LocationPoint>(
                value: currentValue,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: VroomColors.textMuted),
                items: VroomMockData.allLocations.map((loc) {
                  return DropdownMenuItem<LocationPoint>(
                    value: loc,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          loc.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: VroomColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          loc.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: VroomColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onChanged(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorridorChip(String label, LocationPoint p, LocationPoint d) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: VroomColors.surfaceMuted,
      side: const BorderSide(color: VroomColors.border),
      avatar: const Icon(Icons.directions_bike, size: 14, color: VroomColors.primary),
      onPressed: () {
        setState(() {
          _pickup = p;
          _dropoff = d;
        });
      },
    );
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Today • ${DateFormat('MMM d, yyyy').format(date)}';
    } else if (target == tomorrow) {
      return 'Tomorrow • ${DateFormat('MMM d, yyyy').format(date)}';
    }
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  Future<void> _pickDepartureDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: VroomColors.primary,
              onPrimary: Colors.white,
              onSurface: VroomColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
        );
      });
    }
  }
}
