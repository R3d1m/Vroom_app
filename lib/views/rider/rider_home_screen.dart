import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/ride_post.dart';
import '../../core/models/trip_request.dart';
import '../../core/models/booking_model.dart';
import '../../core/providers/vroom_provider.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/vroom_map_widget.dart';
import '../shared/ongoing_trip_screen.dart';
import '../shared/ride_detail_screen.dart';
import 'create_ride_screen.dart';
import 'rider_requests_screen.dart';
import '../shared/ride_history_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  int _selectedTab = 0; // 0: My Posted Rides, 1: Request a Ride (Browse others)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VroomProvider>().loadRidesFromBackend();
        context.read<VroomProvider>().loadBookingsFromBackend();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();
    final pendingRequests = provider.getPendingRequestsForRider(provider.currentUser.id);
    final riderBookings = provider.riderConfirmedBookings;

    // 1. My Posted Rides: only rides posted by THIS rider, active and not completed
    final myRides = provider.ridePosts
        .where((r) => provider.isRiderOf(r) && r.status != RideStatus.completed)
        .toList();

    // 2. Rides posted by others: browse and book seats
    final ridesByOthers = provider.ridePosts
        .where((r) => !provider.isRiderOf(r) && r.status != RideStatus.completed)
        .toList();

    return Scaffold(
      backgroundColor: VroomColors.background,
      appBar: const VroomTopBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadRidesFromBackend();
          await provider.loadBookingsFromBackend();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rider Earnings & Trust Summary Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: VroomColors.text,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Fuel Savings',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '৳ 4,850',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RideHistoryScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.history, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text('History', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                            if (provider.currentUser.vehicleModel != null && provider.currentUser.vehicleModel!.trim().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: VroomColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: VroomColors.primary),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.two_wheeler, color: VroomColors.primary, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      provider.currentUser.vehicleModel!,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('Rating', '★ ${provider.currentUser.rating}'),
                      _buildMiniStat('Trips Shared', '${provider.currentUser.totalTrips}'),
                      _buildMiniStat(
                        'Vehicle',
                        provider.currentUser.vehiclePlate != null && provider.currentUser.vehiclePlate!.trim().isNotEmpty
                            ? provider.currentUser.vehiclePlate!.split(" ").last
                            : 'N/A',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Ongoing Active Trip Banner (if any)
            if (provider.activeBooking != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OngoingTripScreen(bookingId: provider.activeBooking!.id),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: VroomColors.text,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
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
                            Text(
                              'Ongoing Ride with ${provider.activeBooking!.passenger.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Status: ${provider.activeBooking!.tripStatus.name.toUpperCase()} • Fare: ৳${provider.activeBooking!.fare.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: VroomColors.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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

            // Real-time Inbound Booking Alert Banner
            if (provider.latestBookingAlert != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.15),
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
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NEW BOOKING REQUEST!',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            provider.latestBookingAlert!,
                            style: const TextStyle(
                              color: Color(0xFF78350F),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Color(0xFF92400E)),
                      onPressed: () => provider.clearLatestBookingAlert(),
                    ),
                  ],
                ),
              ),

            // Pending Booking Requests Section
            if (pendingRequests.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: VroomColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VroomColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                      child: Text(
                        '${pendingRequests.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Incoming Booking Requests',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          Text(
                            '${pendingRequests.length} passenger(s) requested a seat on your route',
                            style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        backgroundColor: VroomColors.text,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RiderRequestsScreen()),
                        );
                      },
                      child: const Text('Review All', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              ...pendingRequests.map(
                (req) => _buildHomepageRequestCard(
                  context,
                  provider,
                  req['groupRequest'],
                  req['subRequest'],
                  req['ridePost'],
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Confirmed Passenger Bookings for this Rider
            if (riderBookings.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_alt, color: VroomColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Passenger Bookings (${riderBookings.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: VroomColors.text),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: VroomColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${riderBookings.length} Active',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VroomColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...riderBookings.map((b) => _buildRiderBookingCard(context, b, provider)),
              const SizedBox(height: 14),
            ],

            // Segmented Tab Selector (My Posted Rides vs Request a Ride)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: VroomColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: VroomColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? VroomColors.text : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.two_wheeler,
                              size: 16,
                              color: _selectedTab == 0 ? VroomColors.primary : VroomColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'My Posted Rides (${myRides.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _selectedTab == 0 ? Colors.white : VroomColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? VroomColors.text : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 16,
                              color: _selectedTab == 1 ? VroomColors.primary : VroomColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Request a Ride (${ridesByOthers.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _selectedTab == 1 ? Colors.white : VroomColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab 0: My Posted Rides
            if (_selectedTab == 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Active Ride Posts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: VroomColors.text),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateRideScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_circle, size: 16, color: VroomColors.primary),
                    label: const Text('Post Ride', style: TextStyle(fontWeight: FontWeight.w800, color: VroomColors.primary, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (myRides.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: VroomColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: VroomColors.border),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.two_wheeler, size: 40, color: VroomColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No Rides Posted by You',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Post your regular commute to offer empty seats and split fuel costs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: VroomColors.textMuted),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: VroomColors.primary),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateRideScreen()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Post Your First Ride'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...myRides.map((ride) => _buildMyRideItem(context, ride, provider)),
            ],

            // Tab 1: Request a Ride (Rides posted by others)
            if (_selectedTab == 1) ...[
              const Text(
                'Available Rides Posted by Others',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: VroomColors.text),
              ),
              const SizedBox(height: 4),
              const Text(
                'Browse rides scheduled by other commuters and request a seat along their corridor.',
                style: TextStyle(fontSize: 12, color: VroomColors.textMuted),
              ),
              const SizedBox(height: 12),

              if (ridesByOthers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: VroomColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: VroomColors.border),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.route, size: 40, color: VroomColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'No Other Rides Available',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'There are currently no active rides posted by other commuters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: VroomColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...ridesByOthers.map((ride) => _buildOtherRideItem(context, ride)),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
        backgroundColor: VroomColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateRideScreen()),
          );
        },
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Post New Ride', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
      ],
    );
  }

  // Card for rides posted by THIS rider (With Edit & Delete options)
  Widget _buildMyRideItem(BuildContext context, RidePost ride, VroomProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: VroomColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VroomColors.border),
      ),
      child: Column(
        children: [
          // Map preview snippet
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 120,
              child: VroomMapWidget(
                initialCenter: ride.origin.coordinates,
                initialZoom: 11.5,
                primaryRoute: ride.primaryRoute,
                alternateRoutes: ride.alternateRoutes,
                showControls: false,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEE, MMM d • hh:mm a').format(ride.departureTime),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: VroomColors.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: VroomColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${ride.availableSeats} / ${ride.totalSeats} seats left',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VroomColors.text),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.trip_origin, size: 14, color: VroomColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ride.origin.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place, size: 14, color: VroomColors.danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ride.destination.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Booked Passengers on this specific ride
                Builder(
                  builder: (_) {
                    final thisRideBookings = provider.bookings
                        .where((b) => b.ridePostId == ride.id && b.tripStatus != TripLifecycleStatus.cancelled)
                        .toList();
                    if (thisRideBookings.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VroomColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: VroomColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, size: 12, color: VroomColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Booked (${thisRideBookings.length} passenger):',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: VroomColors.text),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          ...thisRideBookings.map((b) => Text(
                                '• ${b.passenger.name} (${b.passenger.phone}) • PIN: ${b.pinCode}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: VroomColors.text),
                              )),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fare: ৳${ride.farePerSeat.toStringAsFixed(0)} / seat',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    Row(
                      children: [
                        // Edit Button
                        IconButton(
                          tooltip: 'Edit Ride',
                          icon: const Icon(Icons.edit_outlined, size: 18, color: VroomColors.text),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateRideScreen(rideToEdit: ride),
                              ),
                            );
                          },
                        ),
                        // Delete Button
                        IconButton(
                          tooltip: 'Delete Ride',
                          icon: const Icon(Icons.delete_outline, size: 18, color: VroomColors.danger),
                          onPressed: () => _confirmDeleteRide(context, ride, provider),
                        ),
                        // View Details Button
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RideDetailScreen(ridePostId: ride.id),
                              ),
                            );
                          },
                          child: const Text(
                            'Details →',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: VroomColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card for rides posted by OTHERS (with Book/Request option)
  Widget _buildOtherRideItem(BuildContext context, RidePost ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: VroomColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VroomColors.border),
      ),
      child: Column(
        children: [
          // Rider Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: VroomColors.surfaceMuted,
                  child: Text(
                    ride.rider.name.isNotEmpty ? ride.rider.name[0] : 'R',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: VroomColors.text, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.rider.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      Text(
                        '${ride.vehicleModel} • ${ride.rider.universityOrOrg}',
                        style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '৳${ride.farePerSeat.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: VroomColors.primary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEE, MMM d • hh:mm a').format(ride.departureTime),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: VroomColors.textMuted),
                    ),
                    Text(
                      '${ride.availableSeats} seat(s) available',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VroomColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.trip_origin, size: 14, color: VroomColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ride.origin.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place, size: 14, color: VroomColors.danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ride.destination.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VroomColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RideDetailScreen(ridePostId: ride.id),
                        ),
                      );
                    },
                    child: const Text('View & Book Ride', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomepageRequestCard(
    BuildContext context,
    VroomProvider provider,
    GroupTripRequest groupReq,
    SubRequestItem sub,
    RidePost ridePost,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VroomColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VroomColors.primary.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: VroomColors.surfaceMuted,
                child: Text(
                  groupReq.passenger.name.isNotEmpty ? groupReq.passenger.name[0] : 'P',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: VroomColors.text, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          groupReq.passenger.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: VroomColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 11, color: VroomColors.warning),
                              const SizedBox(width: 2),
                              Text(
                                '${groupReq.passenger.rating}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${groupReq.passenger.universityOrOrg} • ${groupReq.requestedSeats} Seat(s)',
                      style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: VroomColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '৳${sub.fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: VroomColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.trip_origin, size: 14, color: VroomColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${groupReq.pickup.name} → ${groupReq.dropoff.name}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VroomColors.text),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    foregroundColor: VroomColors.danger,
                    side: const BorderSide(color: VroomColors.border),
                  ),
                  onPressed: () {
                    provider.declineRideRequest(
                      groupRequestId: groupReq.id,
                      ridePostId: ridePost.id,
                    );
                  },
                  child: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                        content: Text('Accepted! Ride confirmed with ${groupReq.passenger.name}. Sibling requests auto-cancelled.'),
                        backgroundColor: VroomColors.text,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Accept Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiderBookingCard(BuildContext context, ConfirmedBooking booking, VroomProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VroomColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VroomColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: VroomColors.surfaceMuted,
                child: Text(
                  booking.passenger.name.isNotEmpty ? booking.passenger.name[0] : 'P',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: VroomColors.text, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.passenger.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    Text(
                      '${booking.passenger.universityOrOrg} • ★ ${booking.passenger.rating}',
                      style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: booking.tripStatus == TripLifecycleStatus.inProgress
                      ? VroomColors.primary
                      : VroomColors.text,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.tripStatus == TripLifecycleStatus.inProgress ? 'IN PROGRESS' : 'CONFIRMED',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.phone, size: 14, color: VroomColors.primary),
              const SizedBox(width: 6),
              Text(
                booking.passenger.phone,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: VroomColors.text),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.access_time, size: 14, color: VroomColors.textMuted),
              const SizedBox(width: 4),
              Text(
                DateFormat('EEE, MMM d • hh:mm a').format(booking.scheduledTime.toLocal()),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VroomColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trip_origin, size: 13, color: VroomColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${booking.pickup.name} → ${booking.dropoff.name}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Fare: ', style: TextStyle(fontSize: 11, color: VroomColors.textMuted)),
                  Text('৳${booking.fare.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: VroomColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PIN: ${booking.pinCode}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: VroomColors.primary),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VroomColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OngoingTripScreen(bookingId: booking.id),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation, size: 14),
                label: const Text('Start / View Trip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRide(BuildContext context, RidePost ride, VroomProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Scheduled Ride?'),
        content: Text(
          'Are you sure you want to cancel and remove your ride from ${ride.origin.name} to ${ride.destination.name}? Any pending passenger requests for this ride will be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Ride'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: VroomColors.danger),
            onPressed: () {
              provider.deleteRidePost(ride.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scheduled ride deleted.'),
                  backgroundColor: VroomColors.danger,
                ),
              );
            },
            child: const Text('Delete Ride'),
          ),
        ],
      ),
    );
  }
}
