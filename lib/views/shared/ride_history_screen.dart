import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/booking_model.dart';
import '../../core/providers/vroom_provider.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: As Rider, 2: As Passenger

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();
    final allHistory = provider.rideHistory;
    final asRiderHistory = allHistory.where((b) => provider.isRiderOfBooking(b)).toList();
    final asPassengerHistory = allHistory.where((b) => provider.isPassengerOfBooking(b)).toList();

    final displayedHistory = _selectedFilterIndex == 1
        ? asRiderHistory
        : _selectedFilterIndex == 2
            ? asPassengerHistory
            : allHistory;

    return Scaffold(
      backgroundColor: VroomColors.background,
      appBar: AppBar(
        title: const Text('Ride History & Receipts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        backgroundColor: VroomColors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadBookingsFromBackend();
        },
        child: Column(
          children: [
            // Filter Tabs (All / As Rider / As Passenger)
            Container(
              color: VroomColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: VroomColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildFilterTab(0, 'All (${allHistory.length})'),
                    _buildFilterTab(1, 'As Rider (${asRiderHistory.length})'),
                    _buildFilterTab(2, 'As Passenger (${asPassengerHistory.length})'),
                  ],
                ),
              ),
            ),

            // Content List
            Expanded(
              child: displayedHistory.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: const BoxDecoration(
                                color: VroomColors.surfaceMuted,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.history_toggle_off, size: 48, color: VroomColors.textMuted),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilterIndex == 1
                                  ? 'No Rides Offered Yet'
                                  : _selectedFilterIndex == 2
                                      ? 'No Booked Trips Yet'
                                      : 'No Completed Rides Yet',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: VroomColors.text),
                            ),
                            const SizedBox(height: 6),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'When your shared campus commutes finish, their trip logs, receipts, and mutual ratings will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: VroomColors.textMuted, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: displayedHistory.length,
                      itemBuilder: (context, index) {
                        final booking = displayedHistory[index];
                        final isMeRider = provider.isRiderOfBooking(booking);
                        final counterparty = isMeRider ? booking.passenger : booking.rider;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: VroomColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: VroomColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Bar: Role badge, date, fare
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: isMeRider
                                                ? VroomColors.primary.withValues(alpha: 0.14)
                                                : Colors.blue.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isMeRider ? Icons.two_wheeler : Icons.person_pin,
                                                size: 14,
                                                color: isMeRider ? VroomColors.primary : Colors.blue.shade700,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                isMeRider ? 'Offered as Rider' : 'Traveled as Passenger',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: isMeRider ? VroomColors.primary : Colors.blue.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('MMM d, yyyy • hh:mm a').format(booking.scheduledTime),
                                          style: const TextStyle(fontSize: 11, color: VroomColors.textMuted, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '৳${booking.fare.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: VroomColors.text,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Divider(height: 1),

                              // Route points (Pickup -> Dropoff)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                                child: Row(
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: VroomColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Container(
                                          width: 2,
                                          height: 24,
                                          color: VroomColors.border,
                                        ),
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: VroomColors.danger,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            booking.pickup.name,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            booking.dropoff.name,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Counterparty & Payment summary
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                color: VroomColors.surfaceMuted.withValues(alpha: 0.5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: VroomColors.primary.withValues(alpha: 0.15),
                                            child: Text(
                                              counterparty.name.isNotEmpty ? counterparty.name[0] : 'U',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: VroomColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${isMeRider ? "Passenger" : "Rider"}: ${counterparty.name}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: VroomColors.text,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${counterparty.universityOrOrg}${counterparty.phone.isNotEmpty ? " • ${counterparty.phone}" : ""}',
                                                  style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle, size: 14, color: VroomColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'PAID (${booking.paymentMethod.name.toUpperCase()})',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: VroomColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Ratings & Review Section
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                                child: booking.passengerGivenRating != null
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Row(
                                                children: List.generate(5, (starIdx) {
                                                  final score = booking.passengerGivenRating!;
                                                  return Icon(
                                                    starIdx < score.floor()
                                                        ? Icons.star
                                                        : (starIdx < score ? Icons.star_half : Icons.star_border),
                                                    size: 15,
                                                    color: Colors.amber,
                                                  );
                                                }),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '★ ${booking.passengerGivenRating!.toStringAsFixed(1)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w900,
                                                  color: VroomColors.text,
                                                ),
                                              ),
                                              const Spacer(),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: const Size(50, 24),
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                onPressed: () => _showTripReceiptModal(context, booking, isMeRider),
                                                child: const Text(
                                                  'Receipt →',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: VroomColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (booking.passengerGivenReview != null &&
                                              booking.passengerGivenReview!.trim().isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '"${booking.passengerGivenReview!.trim()}"',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: VroomColors.textMuted,
                                              ),
                                            ),
                                          ],
                                          if (booking.passengerGivenTags.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: booking.passengerGivenTags.map((tag) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: VroomColors.surfaceMuted,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: VroomColors.border),
                                                  ),
                                                  child: Text(
                                                    '#$tag',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: VroomColors.textMuted,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Trip Completed',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12,
                                                    color: VroomColors.text,
                                                  ),
                                                ),
                                                Text(
                                                  'Share feedback & rate your commute with ${counterparty.name}',
                                                  style: const TextStyle(fontSize: 11, color: VroomColors.textMuted),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: VroomColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              elevation: 0,
                                            ),
                                            onPressed: () => _showRatingDialog(context, booking, provider),
                                            icon: const Icon(Icons.star_rate, size: 14),
                                            label: const Text(
                                              'Rate Trip',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'View Receipt',
                                            icon: const Icon(Icons.receipt_long, size: 18, color: VroomColors.textMuted),
                                            onPressed: () => _showTripReceiptModal(context, booking, isMeRider),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? VroomColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? VroomColors.text : VroomColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // Interactive Rating Dialog
  void _showRatingDialog(BuildContext context, ConfirmedBooking booking, VroomProvider provider) {
    double rating = 5.0;
    final commentController = TextEditingController();
    final selectedTags = <String>{'On Time', 'Safe Driving'};

    final availableTags = [
      'On Time',
      'Safe Driving',
      'Smooth Route',
      'Clean Helmet',
      'Clean Vehicle',
      'Polite & Friendly',
      'Fair Fare',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: VroomColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
                const Text(
                  'Rate Your Commute',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: VroomColors.text),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your honest rating builds university trust for ${booking.rider.name}',
                  style: const TextStyle(fontSize: 12, color: VroomColors.textMuted),
                ),
                const SizedBox(height: 20),

                // Star Picker
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        iconSize: 36,
                        icon: Icon(
                          starValue <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setModalState(() => rating = starValue.toDouble());
                        },
                      );
                    }),
                  ),
                ),
                Center(
                  child: Text(
                    rating == 5
                        ? 'Excellent Experience (★ 5.0)'
                        : rating >= 4
                            ? 'Good Commute (★ ${rating.toStringAsFixed(1)})'
                            : 'Average Trip (★ ${rating.toStringAsFixed(1)})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VroomColors.primary),
                  ),
                ),
                const SizedBox(height: 16),

                // Praise Tags
                const Text('What went well?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: availableTags.map((tag) {
                    final isChecked = selectedTags.contains(tag);
                    return ChoiceChip(
                      label: Text(tag),
                      selected: isChecked,
                      selectedColor: VroomColors.primary.withValues(alpha: 0.15),
                      backgroundColor: VroomColors.surfaceMuted,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isChecked ? VroomColors.primary : VroomColors.textMuted,
                      ),
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) {
                            selectedTags.add(tag);
                          } else {
                            selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Comment
                TextField(
                  controller: commentController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Share a quick note about your ride...',
                    hintStyle: const TextStyle(fontSize: 12, color: VroomColors.textMuted),
                    filled: true,
                    fillColor: VroomColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: VroomColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: VroomColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VroomColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      provider.submitRating(
                        bookingId: booking.id,
                        rating: rating,
                        review: commentController.text.trim(),
                        tags: selectedTags.toList(),
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Feedback and rating submitted! Thank you.'),
                          backgroundColor: VroomColors.primary,
                        ),
                      );
                    },
                    child: const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Full Trip Receipt Modal
  void _showTripReceiptModal(BuildContext context, ConfirmedBooking booking, bool isMeRider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: VroomColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, color: VroomColors.primary, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Trip Receipt',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: VroomColors.text),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: VroomColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PAID • ${booking.paymentMethod.name.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: VroomColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Booking Ref: ${booking.id}',
              style: const TextStyle(fontSize: 11, color: VroomColors.textMuted, fontFamily: 'monospace'),
            ),
            const Divider(height: 24),

            _buildReceiptRow('Date & Departure', DateFormat('EEE, MMM d, yyyy • hh:mm a').format(booking.scheduledTime)),
            _buildReceiptRow('Pickup Location', booking.pickup.name),
            _buildReceiptRow('Dropoff Location', booking.dropoff.name),
            _buildReceiptRow('Rider', '${booking.rider.name} (${booking.rider.universityOrOrg})'),
            _buildReceiptRow('Passenger', '${booking.passenger.name} (${booking.passenger.universityOrOrg})'),
            _buildReceiptRow('Trip Security PIN', booking.pinCode),
            const Divider(height: 20),
            _buildReceiptRow('Base Seat Share', '৳${booking.fare.toStringAsFixed(0)}'),
            _buildReceiptRow('Platform Service Fee', '৳0 (Campus Free)'),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Fare',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: VroomColors.text),
                ),
                Text(
                  '৳${booking.fare.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: VroomColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VroomColors.text,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close Receipt', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: VroomColors.textMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: VroomColors.text),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
