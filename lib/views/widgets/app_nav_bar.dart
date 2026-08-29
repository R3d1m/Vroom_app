import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/vroom_provider.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_screen.dart';
import '../shared/ride_history_screen.dart';

class VroomTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showModeSwitcher;

  const VroomTopBar({
    super.key,
    this.title,
    this.showModeSwitcher = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();
    final isRider = provider.activeMode == UserRoleMode.rider;
    final unreadNotifs = provider.unreadNotificationsCount;

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          // VROOM Logo Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: VroomColors.text,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRider ? Icons.two_wheeler : Icons.directions_car,
                  color: VroomColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                const Text(
                  'VROOM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          if (title != null) ...[
            const SizedBox(width: 12),
            Text(
              title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
      actions: [
        // Ride History Shortcut
        IconButton(
          tooltip: 'Ride History',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RideHistoryScreen()),
            );
          },
          icon: const Icon(Icons.history, size: 22),
        ),

        // Notification Bell with Badge
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, size: 22),
              if (unreadNotifs > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: VroomColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadNotifs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // User Avatar Button
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: VroomColors.border,
              child: Text(
                provider.currentUser.name.isNotEmpty ? provider.currentUser.name[0] : 'U',
                style: const TextStyle(
                  color: VroomColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
