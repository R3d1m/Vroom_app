import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/vroom_provider.dart';
import '../widgets/verification_badge.dart';
import 'ride_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();
    final user = provider.currentUser;
    final hasVehicle = user.vehicleModel != null && user.vehicleModel!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: VroomColors.background,
      appBar: AppBar(
        title: const Text('My Profile & Trust Verification'),
        backgroundColor: VroomColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: VroomColors.surface,
                borderRadius: BorderRadius.circular(20),
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
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: VroomColors.text,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0] : 'U',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: VroomColors.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.universityOrOrg,
                    style: const TextStyle(fontSize: 13, color: VroomColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.phone,
                    style: const TextStyle(fontSize: 12, color: VroomColors.textMuted),
                  ),
                  const SizedBox(height: 12),

                  // Fixed User Role Badge (Non-switchable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: user.activeMode == UserRoleMode.rider
                          ? VroomColors.text
                          : VroomColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VroomColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.activeMode == UserRoleMode.rider ? Icons.two_wheeler : Icons.person_pin_circle,
                          size: 15,
                          color: user.activeMode == UserRoleMode.rider ? VroomColors.primary : VroomColors.text,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.activeMode == UserRoleMode.rider
                              ? 'Verified Rider (Vehicle Owner)'
                              : 'Verified Passenger (Commuter)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: user.activeMode == UserRoleMode.rider ? Colors.white : VroomColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Verification Badges
                  VerificationBadge(
                    nidStatus: user.nidStatus,
                    studentIdStatus: user.studentIdStatus,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Vehicle Registration Information (Displayed ONLY if the user registered a vehicle)
            if (hasVehicle) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VroomColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VroomColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: VroomColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Vehicle & Trust Verification',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildProfileRow('Registered Vehicle', user.vehicleModel!),
                    if (user.vehiclePlate != null && user.vehiclePlate!.trim().isNotEmpty)
                      _buildProfileRow('License Plate', user.vehiclePlate!),
                    if (user.vehicleType != null && user.vehicleType!.trim().isNotEmpty)
                      _buildProfileRow('Vehicle Type', user.vehicleType!),
                    _buildProfileRow('Driving License', 'Verified (BRTA Linked)'),
                    _buildProfileRow('National ID (NID)', 'Verified (Govt DB)'),
                    _buildProfileRow('University ID Card', '${user.universityOrOrg} Verified'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Ride History Navigation Card
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RideHistoryScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: VroomColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VroomColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.history, color: VroomColors.primary, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ride History', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('View completed pooled trips & payment receipts', style: TextStyle(fontSize: 11, color: VroomColors.textMuted)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: VroomColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Safety Contacts
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VroomColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VroomColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.contact_phone_outlined, color: VroomColors.danger, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Emergency Contacts & SOS',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildProfileRow('Primary Guardian', '+880 1711-998877'),
                  _buildProfileRow('Campus Security (CUET)', '01713-246500'),
                  _buildProfileRow('National Helpline', '999 (Police / Medical)'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: VroomColors.danger,
                side: const BorderSide(color: VroomColors.danger, width: 1.5),
              ),
              onPressed: () {
                provider.logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out of VROOM', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: VroomColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: VroomColors.text)),
        ],
      ),
    );
  }
}
