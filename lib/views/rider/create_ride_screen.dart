import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/route_model.dart';
import '../../core/models/ride_post.dart';
import '../../core/data/mock_data.dart';
import '../../core/providers/vroom_provider.dart';
import '../widgets/vroom_map_widget.dart';

class CreateRideScreen extends StatefulWidget {
  final RidePost? rideToEdit;

  const CreateRideScreen({super.key, this.rideToEdit});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  LocationPoint _origin = VroomMockData.cuetCampus;
  LocationPoint _destination = VroomMockData.gecCircle;
  DateTime _departureTime = DateTime.now().add(const Duration(days: 1, hours: -2));
  int _seats = 1;
  double _fare = 120.0;
  double _detourToleranceKm = 2.0;

  // Route & Via Roads text controller
  final TextEditingController _viaRoadController =
      TextEditingController(text: 'Via Kaptai Highway & Bayezid Bypass');

  // Fare controller for two-way sync with AI estimate
  late TextEditingController _fareController;

  // AI Fare Estimation State
  bool _isRaining = false;
  double _aiEstimatedFare = 245.0;
  String _aiFareReason = '';
  bool _isLoadingAi = false;

  // Selected Route Options
  late RouteOption _primaryRoute;
  late List<RouteOption> _alternateRoutes;

  @override
  void initState() {
    super.initState();
    _fareController = TextEditingController(text: _fare.toStringAsFixed(0));
    if (widget.rideToEdit != null) {
      final r = widget.rideToEdit!;
      _origin = r.origin;
      _destination = r.destination;
      _departureTime = r.departureTime;
      _seats = r.totalSeats;
      _fare = r.farePerSeat;
      _fareController.text = _fare.toStringAsFixed(0);
      _detourToleranceKm = r.detourToleranceKm;
      _primaryRoute = r.primaryRoute;
      _alternateRoutes = r.alternateRoutes;
      _viaRoadController.text = r.primaryRoute.viaRoadName.isNotEmpty
          ? r.primaryRoute.viaRoadName
          : 'Via Kaptai Highway & Bayezid Bypass';
    } else {
      _recalculateRoutes();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestFareEstimate();
    });
  }

  @override
  void dispose() {
    _viaRoadController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  void _recalculateRoutes() {
    // Generate realistic primary polyline between chosen points
    final p1 = _origin.coordinates;
    final p2 = _destination.coordinates;
    final midLat = (p1.latitude + p2.latitude) / 2;
    final midLng = (p1.longitude + p2.longitude) / 2;

    const Distance distCalc = Distance();
    final straightKm = distCalc.as(LengthUnit.Kilometer, p1, p2);
    final calculatedDistance = straightKm > 0 ? double.parse((straightKm * 1.35).toStringAsFixed(1)) : 24.5;
    final durationMinutes = (calculatedDistance * 1.8).round();

    _primaryRoute = RouteOption(
      id: 'prim_${_origin.id}_${_destination.id}',
      name: 'Main Direct Highway',
      viaRoadName: 'Via Primary Corridor',
      polyline: [
        p1,
        LatLng(midLat + 0.01, midLng + 0.01),
        LatLng(midLat - 0.005, midLng - 0.01),
        p2,
      ],
      isPrimary: true,
      isSelected: true,
      distanceKm: calculatedDistance,
      durationMinutes: durationMinutes,
    );

    _alternateRoutes = [
      RouteOption(
        id: 'alt1_${_origin.id}_${_destination.id}',
        name: 'Via Bayezid Link / Bypass Road',
        viaRoadName: 'Via Outer Ring / Bypass',
        polyline: [
          p1,
          LatLng(midLat + 0.03, midLng - 0.02),
          LatLng(midLat + 0.01, midLng - 0.03),
          p2,
        ],
        isPrimary: false,
        isSelected: true, // Enabled by default
        distanceKm: double.parse((calculatedDistance * 1.09).toStringAsFixed(1)),
        durationMinutes: durationMinutes + 3,
      ),
      RouteOption(
        id: 'alt2_${_origin.id}_${_destination.id}',
        name: 'Via Chawkbazar Commercial Road',
        viaRoadName: 'Via Inner City Commercial Corridor',
        polyline: [
          p1,
          LatLng(midLat - 0.02, midLng + 0.02),
          LatLng(midLat - 0.01, midLng + 0.01),
          p2,
        ],
        isPrimary: false,
        isSelected: false, // Optional
        distanceKm: double.parse((calculatedDistance * 1.03).toStringAsFixed(1)),
        durationMinutes: durationMinutes + 7,
      ),
    ];

    _requestFareEstimate();
  }

  Future<void> _requestFareEstimate() async {
    if (!mounted) return;
    setState(() => _isLoadingAi = true);
    try {
      final provider = context.read<VroomProvider>();
      final res = await provider.estimateFare(
        distanceKm: _primaryRoute.distanceKm,
        origin: _origin.name,
        destination: _destination.name,
        originLat: _origin.coordinates.latitude,
        originLng: _origin.coordinates.longitude,
      );
      if (mounted) {
        setState(() {
          _isLoadingAi = false;
          _aiEstimatedFare = (res['estimated_fare'] as num).toDouble();
          _aiFareReason = res['reasoning'] as String? ?? '';
          _isRaining = (res['weather']?.toString().toLowerCase().contains('rain') ?? false);
          // Auto-set the fare in the input field!
          _fare = _aiEstimatedFare;
          _fareController.text = _aiEstimatedFare.toStringAsFixed(0);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<VroomProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rideToEdit != null ? 'Edit Scheduled Ride' : 'Schedule & Post a Ride'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Interactive Route Visualizer on Map (Top)
            SizedBox(
              height: 240,
              child: VroomMapWidget(
                initialCenter: _origin.coordinates,
                initialZoom: 11.5,
                primaryRoute: _primaryRoute,
                alternateRoutes: _alternateRoutes,
                pickupPoint: _origin.coordinates,
                dropoffPoint: _destination.coordinates,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Origin & Destination',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: VroomColors.text),
                  ),
                  const SizedBox(height: 12),

                  // Origin Dropdown
                  _buildLocationDropdown(
                    label: 'Starting Location',
                    icon: Icons.trip_origin,
                    iconColor: VroomColors.primary,
                    current: _origin,
                    onChanged: (loc) {
                      setState(() {
                        _origin = loc;
                        _recalculateRoutes();
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // Destination Dropdown
                  _buildLocationDropdown(
                    label: 'Final Destination',
                    icon: Icons.place,
                    iconColor: VroomColors.danger,
                    current: _destination,
                    onChanged: (loc) {
                      setState(() {
                        _destination = loc;
                        _recalculateRoutes();
                      });
                    },
                  ),
                  const Divider(height: 32),

                  // 2. Route Details / Via Roads (Single clean text box)
                  const Text(
                    '2. Route Details / Via Roads',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: VroomColors.text),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Specify the main roads, intersections, or corridors you plan to travel along:',
                    style: TextStyle(fontSize: 12, color: VroomColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _viaRoadController,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: VroomColors.text),
                    decoration: InputDecoration(
                      hintText: 'e.g. Via Kaptai Road, Oxygen Mor, Bayezid Bypass',
                      hintStyle: const TextStyle(fontSize: 13, color: VroomColors.textMuted),
                      prefixIcon: const Icon(Icons.alt_route, color: VroomColors.primary, size: 20),
                      filled: true,
                      fillColor: VroomColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: VroomColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: VroomColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: VroomColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detour Radius Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pickup Detour Tolerance',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${_detourToleranceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VroomColors.primary),
                      ),
                    ],
                  ),
                  Slider(
                    value: _detourToleranceKm,
                    min: 0.5,
                    max: 4.0,
                    divisions: 7,
                    activeColor: VroomColors.primary,
                    inactiveColor: VroomColors.border,
                    label: '${_detourToleranceKm.toStringAsFixed(1)} km',
                    onChanged: (val) => setState(() => _detourToleranceKm = val),
                  ),
                  const Divider(height: 32),

                  // Schedule Date & Time
                  const Text(
                    '3. Departure Schedule & Pricing',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: VroomColors.text),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: _pickDepartureDateTime,
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
                          const Icon(Icons.calendar_today, size: 18, color: VroomColors.textMuted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Departure Time', style: TextStyle(fontSize: 11, color: VroomColors.textMuted, fontWeight: FontWeight.w600)),
                                Text(
                                  DateFormat('EEEE, MMM d, yyyy • hh:mm a').format(_departureTime),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: VroomColors.text),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_calendar, size: 18, color: VroomColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Seats and Fare Row
                  Row(
                    children: [
                      // Available Seats
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: VroomColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: VroomColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Seats Offered', style: TextStyle(fontSize: 11, color: VroomColors.textMuted, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                                    onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                                  ),
                                  Text('$_seats', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    onPressed: _seats < 4 ? () => setState(() => _seats++) : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Fare per seat
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: VroomColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: VroomColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fare per Seat (৳)', style: TextStyle(fontSize: 11, color: VroomColors.textMuted, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text('৳', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: VroomColors.primary)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _fareController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      ),
                                      onChanged: (val) {
                                        final parsed = double.tryParse(val);
                                        if (parsed != null) _fare = parsed;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Single Box for AI-Powered Fare Estimation with Weather Multiplier
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VroomColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isRaining
                            ? Colors.blue.withValues(alpha: 0.5)
                            : VroomColors.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRaining ? Colors.blue : VroomColors.primary).withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: AI Badge + Weather Condition Selector Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: VroomColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.auto_awesome, size: 14, color: VroomColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'AI FARE ESTIMATE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: VroomColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Open-Meteo auto-detected weather chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _isRaining
                                    ? Colors.blue.withValues(alpha: 0.15)
                                    : VroomColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isRaining ? Colors.blue : VroomColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isRaining ? Icons.water_drop : Icons.wb_sunny,
                                    size: 13,
                                    color: _isRaining ? Colors.blue : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isRaining ? '🌧️ Rain (Open-Meteo ×1.25)' : '☀️ Clear (Open-Meteo)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _isRaining ? Colors.blue.shade800 : VroomColors.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Center: Fare amount + Auto-applied status & refresh
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '৳${_aiEstimatedFare.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: VroomColors.text,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '/ seat',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: VroomColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_isLoadingAi) ...[
                                      const SizedBox(width: 8),
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: VroomColors.primary),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  'Base 50৳ (0-5km) + 10৳/km • ${_primaryRoute.distanceKm.toStringAsFixed(1)} km • ${_isRaining ? 'Rain (+25%)' : 'Standard'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: VroomColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: VroomColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: VroomColors.primary),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 14, color: VroomColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Auto-Applied',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: VroomColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: _requestFareEstimate,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: VroomColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: VroomColors.border),
                                    ),
                                    child: const Icon(Icons.refresh, size: 16, color: VroomColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        if (_aiFareReason.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: VroomColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, size: 13, color: VroomColors.textMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _aiFareReason,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: VroomColors.textMuted,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: VroomColors.primary,
                    ),
                    onPressed: () {
                      final viaRoadText = _viaRoadController.text.trim().isNotEmpty
                          ? _viaRoadController.text.trim()
                          : 'Kaptai Highway & Main Road';

                      final updatedRoute = RouteOption(
                        id: 'prim_${_origin.id}_${_destination.id}',
                        name: 'Via $viaRoadText',
                        viaRoadName: viaRoadText,
                        polyline: _primaryRoute.polyline,
                        isPrimary: true,
                        isSelected: true,
                        distanceKm: _primaryRoute.distanceKm,
                        durationMinutes: _primaryRoute.durationMinutes,
                      );

                      if (widget.rideToEdit != null) {
                        final updated = RidePost(
                          id: widget.rideToEdit!.id,
                          rider: widget.rideToEdit!.rider,
                          origin: _origin,
                          destination: _destination,
                          primaryRoute: updatedRoute,
                          alternateRoutes: const [],
                          detourToleranceKm: _detourToleranceKm,
                          departureTime: _departureTime,
                          totalSeats: _seats,
                          availableSeats: _seats,
                          farePerSeat: _fare,
                          vehicleType: widget.rideToEdit!.vehicleType,
                          vehiclePlate: widget.rideToEdit!.vehiclePlate,
                          vehicleModel: widget.rideToEdit!.vehicleModel,
                          status: widget.rideToEdit!.status,
                        );
                        provider.updateRidePost(updated);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Scheduled ride updated successfully!'),
                            backgroundColor: VroomColors.text,
                          ),
                        );
                      } else {
                        provider.createRidePost(
                          origin: _origin,
                          destination: _destination,
                          primaryRoute: updatedRoute,
                          alternateRoutes: const [],
                          detourToleranceKm: _detourToleranceKm,
                          departureTime: _departureTime,
                          seats: _seats,
                          farePerSeat: _fare,
                          vehicleType: provider.currentUser.vehicleType ?? 'Motorcycle',
                          vehiclePlate: provider.currentUser.vehiclePlate ?? 'Plate Verified',
                          vehicleModel: provider.currentUser.vehicleModel ?? 'Registered Vehicle',
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Scheduled ride successfully posted on VROOM!'),
                            backgroundColor: VroomColors.text,
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.rideToEdit != null ? Icons.save : Icons.publish),
                        const SizedBox(width: 8),
                        Text(widget.rideToEdit != null ? 'Save Changes' : 'Publish Scheduled Ride'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDropdown({
    required String label,
    required IconData icon,
    required Color iconColor,
    required LocationPoint current,
    required ValueChanged<LocationPoint> onChanged,
  }) {
    final all = VroomMockData.allLocations;
    // Find matching item by ID
    final selectedValue = all.firstWhere(
      (loc) => loc.id == current.id,
      orElse: () => current,
    );
    final itemsList = all.any((loc) => loc.id == selectedValue.id)
        ? all
        : [...all, selectedValue];

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
                value: selectedValue,
                isExpanded: true,
                items: itemsList.map((loc) {
                  return DropdownMenuItem<LocationPoint>(
                    value: loc,
                    child: Text(
                      loc.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VroomColors.text),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    onChanged(val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDepartureDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _departureTime,
      firstDate: now,
      lastDate: now.add(const Duration(days: 14)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_departureTime),
      );

      if (pickedTime != null) {
        setState(() {
          _departureTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
}
