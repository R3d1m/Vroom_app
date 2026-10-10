import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/booking_model.dart';
import '../../core/providers/vroom_provider.dart';

class PaymentRatingSheet extends StatefulWidget {
  final String bookingId;

  const PaymentRatingSheet({super.key, required this.bookingId});

  @override
  State<PaymentRatingSheet> createState() => _PaymentRatingSheetState();
}

class _PaymentRatingSheetState extends State<PaymentRatingSheet> {
  PaymentMethod _selectedMethod = PaymentMethod.bKash;
  bool _isPaid = false;
  double _rating = 5.0;
  final Set<String> _selectedTags = {'Punctual', 'Safe Driving'};
  final TextEditingController _reviewController = TextEditingController();

  final List<String> _availableTags = [
    'Punctual',
    'Safe Driving',
    'Polite Rider',
    'Clean Helmet Provided',
    'Smooth Route',
    'Student Friendly',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();
    final booking = provider.bookings.firstWhere(
      (b) => b.id == widget.bookingId,
      orElse: () => provider.bookings.first,
    );

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: VroomColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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

            if (!_isPaid) ...[
              // Step 1: Payment Checkout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trip Completed! Pay Fare',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: VroomColors.text),
                  ),
                  Text(
                    '৳${booking.fare.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: VroomColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Ride with ${booking.rider.name} (${booking.pickup.name.split(" ")[0]} → ${booking.dropoff.name.split(" ")[0]})',
                style: const TextStyle(fontSize: 12, color: VroomColors.textMuted),
              ),
              const SizedBox(height: 20),

              const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 10),

              // bKash Option
              _buildPaymentOption(
                method: PaymentMethod.bKash,
                title: 'bKash MFS Direct',
                subtitle: 'Fast split checkout via bKash Wallet',
                icon: Icons.account_balance_wallet,
                color: VroomColors.bKash,
              ),
              const SizedBox(height: 8),

              // Nagad Option
              _buildPaymentOption(
                method: PaymentMethod.nagad,
                title: 'Nagad Digital Pay',
                subtitle: 'Pay instantly with Nagad Gateway',
                icon: Icons.payments,
                color: VroomColors.nagad,
              ),
              const SizedBox(height: 8),

              // Cash Option
              _buildPaymentOption(
                method: PaymentMethod.cash,
                title: 'Cash on Drop-off',
                subtitle: 'Hand over cash directly to the rider',
                icon: Icons.attach_money,
                color: VroomColors.text,
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: VroomColors.primary,
                ),
                onPressed: () {
                  provider.processPayment(widget.bookingId, _selectedMethod);
                  setState(() => _isPaid = true);
                },
                child: Text('Pay ৳${booking.fare.toStringAsFixed(0)} via ${_selectedMethod.name.toUpperCase()}'),
              ),
            ] else ...[
              // Step 2: Rating & Review
              Row(
                children: [
                  const Icon(Icons.check_circle, color: VroomColors.accent, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Payment Successful!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: VroomColors.text),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'How was your ride with ${booking.rider.name}?',
                style: const TextStyle(fontSize: 13, color: VroomColors.textMuted),
              ),
              const SizedBox(height: 16),

              // Star Rating Selector
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      onPressed: () => setState(() => _rating = starIndex.toDouble()),
                      icon: Icon(
                        starIndex <= _rating ? Icons.star : Icons.star_border,
                        color: VroomColors.warning,
                        size: 36,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),

              // Tag Chips
              const Text('What went well?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : VroomColors.text)),
                    selected: isSelected,
                    selectedColor: VroomColors.primary,
                    backgroundColor: VroomColors.surfaceMuted,
                    side: const BorderSide(color: VroomColors.border),
                    showCheckmark: false,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _reviewController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Add an optional note or review for the community...',
                ),
              ),
              const SizedBox(height: 18),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: VroomColors.text,
                ),
                onPressed: () {
                  provider.submitRating(
                    bookingId: widget.bookingId,
                    rating: _rating,
                    review: _reviewController.text.trim(),
                    tags: _selectedTags.toList(),
                  );
                  Navigator.pop(context); // Close bottom sheet
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Return from ongoing trip screen if pushed
                  }
                },
                child: const Text('Submit Review & Done'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? VroomColors.surfaceMuted : VroomColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? VroomColors.primary : VroomColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: VroomColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: VroomColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
