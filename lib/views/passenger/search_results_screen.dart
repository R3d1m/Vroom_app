import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/route_model.dart';
import '../../core/models/ride_post.dart';
import '../../core/providers/vroom_provider.dart';
import '../widgets/vroom_map_widget.dart';
import '../shared/ride_detail_screen.dart';
import 'broadcast_status_hud.dart';

class SearchResultsScreen extends StatefulWidget {
  final LocationPoint pickup;
  final LocationPoint dropoff;
  final DateTime travelDate;

  SearchResultsScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    DateTime? travelDate,
    DateTime? departureTime,
  }) : travelDate = travelDate ?? departureTime ?? DateTime.now();

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  RidePost? _selectedPreviewRide;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime(widget.travelDate.year, widget.travelDate.month, widget.travelDate.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VroomProvider>().loadRidesFromBackend();
      }
    });
  }

  Future<void> _pickDifferentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null && mounted) {
      setState(() {
        _currentDate = DateTime(picked.year, picked.month, picked.day);
        _selectedPreviewRide = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();
    final matchingRides = provider.searchMatchingRides(
      widget.pickup.coordinates,
      widget.dropoff.coordinates,
      travelDate: _currentDate,
    );

    final otherDateMatches = matchingRides.isEmpty
        ? provider.searchMatchingRidesOtherDates(
            widget.pickup.coordinates,
            widget.dropoff.coordinates,
            travelDate: _currentDate,
          )
        : <RidePost>[];

    // If no ride selected for preview, default to first matching or first other-date match
    final activePreview = _selectedPreviewRide ??
        (matchingRides.isNotEmpty
            ? matchingRides.first
            : (otherDateMatches.isNotEmpty ? otherDateMatches.first : null));

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _pickDifferentDate,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.pickup.name.split(" ")[0]} → ${widget.dropoff.name.split(" ")[0]}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(_currentDate),
                      style: const TextStyle(fontSize: 11, color: VroomColors.primary, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_calendar, size: 12, color: VroomColors.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Rides',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await provider.loadRidesFromBackend();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Rides updated from live server'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Route Corridor Preview Map (Top 35%)
          SizedBox(
            height: 220,
            child: activePreview != null
                ? VroomMapWidget(
                    initialCenter: widget.pickup.coordinates,
                    initialZoom: 12.0,
                    primaryRoute: activePreview.primaryRoute,
                    alternateRoutes: activePreview.alternateRoutes,
                    pickupPoint: widget.pickup.coordinates,
                    dropoffPoint: widget.dropoff.coordinates,
                  )
                : VroomMapWidget(
                    pickupPoint: widget.pickup.coordinates,
                    dropoffPoint: widget.dropoff.coordinates,
                  ),
          ),

          // Informational AI Estimated Fare for this Corridor (No user input needed)
          Builder(builder: (context) {
            const distCalc = Distance();
            final straight = distCalc.as(LengthUnit.Kilometer, widget.pickup.coordinates, widget.dropoff.coordinates);
            final distKm = straight > 0 ? (straight * 1.35) : 24.5;
            final baseFare = distKm <= 5.0 ? 50.0 : 50.0 + (distKm - 5.0) * 10.0;
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: VroomColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VroomColors.primary.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: VroomColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'AI Fair Fare Idea: ~৳${baseFare.toStringAsFixed(0)} / seat',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: VroomColors.text),
                  ),
                  const Spacer(),
                  Text(
                    '${distKm.toStringAsFixed(1)} km route',
                    style: const TextStyle(fontSize: 11, color: VroomColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),

          // Matching Rides Feed with Pull-To-Refresh
          Expanded(
            child: Container(
              color: VroomColors.background,
              child: RefreshIndicator(
                onRefresh: () => provider.loadRidesFromBackend(),
                child: matchingRides.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        itemCount: matchingRides.length,
                        itemBuilder: (context, index) {
                          final ride = matchingRides[index];
                          final isSelected = ride.id == activePreview?.id;
                          return _buildRideCard(ride, isSelected);
                        },
                      )
                    : (otherDateMatches.isNotEmpty
                        ? ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                            itemCount: otherDateMatches.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildOtherDatesBanner(otherDateMatches.length);
                              }
                              final ride = otherDateMatches[index - 1];
                              final isSelected = ride.id == activePreview?.id;
                              return _buildRideCard(ride, isSelected, isOtherDate: true);
                            },
                          )
                        : _buildEmptyState()),
              ),
            ),
          ),
        ],
      ),

      // Bottom Floating Broadcast Bar (1-to-Many Group Request)
      bottomSheet: (matchingRides.isEmpty && otherDateMatches.isEmpty)
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: VroomColors.surface,
                border: Border(top: BorderSide(color: VroomColors.border)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt, color: VroomColors.primary, size: 18),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Group Request: Auto-cancels sibling requests upon first acceptance',
                            style: TextStyle(fontSize: 11, color: VroomColors.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VroomColors.text,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () => _handleBroadcastGroupRequest(
                        matchingRides.isNotEmpty ? matchingRides : otherDateMatches,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.dynamic_feed, size: 18, color: VroomColors.accent),
                          const SizedBox(width: 8),
                          Text(
                            matchingRides.isNotEmpty
                                ? 'Broadcast Request to All (${matchingRides.length}) Riders'
                                : 'Broadcast to (${otherDateMatches.length}) Upcoming Riders',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOtherDatesBanner(int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VroomColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VroomColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available, color: VroomColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No direct rides on ${DateFormat("MMM d").format(_currentDate)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: VroomColors.text),
                ),
                Text(
                  '$count upcoming ride(s) found along your corridor on other dates:',
                  style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _pickDifferentDate,
            child: const Text('Change Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(RidePost ride, bool isSelected, {bool isOtherDate = false}) {
    final detour = ride.calculateDetourForPassenger(widget.pickup.coordinates, widget.dropoff.coordinates);
    final rideDateLocal = ride.departureTime.toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: VroomColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? VroomColors.primary : VroomColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => _selectedPreviewRide = ride);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rider Info Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: VroomColors.surfaceMuted,
                    child: Text(
                      ride.rider.name[0],
                      style: const TextStyle(fontWeight: FontWeight.w800, color: VroomColors.text),
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
                              ride.rider.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
                                    '${ride.rider.rating}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ride.rider.universityOrOrg,
                          style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  // Fare Pill
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '৳${ride.farePerSeat.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: VroomColors.text,
                        ),
                      ),
                      const Text(
                        'per seat',
                        style: TextStyle(fontSize: 10, color: VroomColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Badges & Vehicle Specs
              Row(
                children: [
                  Icon(
                    ride.vehicleType == 'Car' ? Icons.directions_car : Icons.two_wheeler,
                    size: 14,
                    color: VroomColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.vehicleModel} • ${ride.availableSeats} seat left',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VroomColors.textMuted),
                  ),
                ],
              ),
              const Divider(height: 18),

              // Route & Schedule Info
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: VroomColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    DateFormat('hh:mm a').format(rideDateLocal),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isOtherDate ? VroomColors.primary.withValues(alpha: 0.15) : VroomColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                      border: isOtherDate ? Border.all(color: VroomColors.primary, width: 0.5) : null,
                    ),
                    child: Text(
                      DateFormat('MMM d').format(rideDateLocal),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isOtherDate ? VroomColors.primary : VroomColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.alt_route, size: 14, color: VroomColors.secondary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      ride.primaryRoute.viaRoadName,
                      style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: VroomColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Detour: ~${(detour).toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: VroomColors.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Action Buttons Row (Direct Request & View Details)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: VroomColors.border),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RideDetailScreen(ridePostId: ride.id),
                          ),
                        );
                      },
                      child: const Text(
                        'View Route Details',
                        style: TextStyle(color: VroomColors.text, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: VroomColors.primary,
                      ),
                      onPressed: () => _handleSingleRequest(ride),
                      child: const Text(
                        'Request Seat',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final provider = context.read<VroomProvider>();
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              child: const Icon(Icons.route_outlined, size: 40, color: VroomColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'No direct matches found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'No riders have scheduled trips passing your corridor on ${DateFormat("EEEE, MMM d").format(_currentDate)} yet. Try picking another date or refresh to sync live trips.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: VroomColors.textMuted),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDifferentDate,
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('Change Date'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    await provider.loadRidesFromBackend();
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSingleRequest(RidePost ride) {
    final provider = context.read<VroomProvider>();
    provider.sendGroupRequest(
      pickup: widget.pickup,
      dropoff: widget.dropoff,
      scheduledDeparture: ride.departureTime.toLocal(),
      targetRides: [ride],
    );

    final activeReq = provider.activeGroupRequest;
    if (activeReq != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BroadcastStatusHud(requestId: activeReq.id),
        ),
      );
    }
  }

  void _handleBroadcastGroupRequest(List<RidePost> rides) {
    final provider = context.read<VroomProvider>();
    provider.sendGroupRequest(
      pickup: widget.pickup,
      dropoff: widget.dropoff,
      scheduledDeparture: _currentDate,
      targetRides: rides,
    );

    final activeReq = provider.activeGroupRequest;
    if (activeReq != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BroadcastStatusHud(requestId: activeReq.id),
        ),
      );
    }
  }
}
