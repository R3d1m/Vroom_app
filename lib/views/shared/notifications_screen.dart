import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/notification_model.dart';
import '../../core/providers/vroom_provider.dart';
import '../rider/rider_requests_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VroomProvider>().markAllNotificationsAsRead();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: VroomColors.background,
      appBar: AppBar(
        title: const Text('Activity & Notifications'),
        backgroundColor: VroomColors.surface,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                provider.clearAllNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications cleared'),
                    backgroundColor: VroomColors.text,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: VroomColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: VroomColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none, size: 44, color: VroomColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Notifications Yet',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: VroomColors.text),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ride requests, confirmations, and security alerts\nwill appear here in real-time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: VroomColors.textMuted),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _buildNotificationCard(context, notif);
              },
            ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, VroomNotification notif) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (notif.category) {
      case NotificationCategory.ride:
        icon = Icons.directions_bike;
        iconColor = VroomColors.primary;
        bgColor = VroomColors.primary.withValues(alpha: 0.12);
        break;
      case NotificationCategory.payment:
        icon = Icons.account_balance_wallet;
        iconColor = const Color(0xFF10B981);
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
        break;
      case NotificationCategory.security:
        icon = Icons.shield_outlined;
        iconColor = const Color(0xFF0284C7);
        bgColor = const Color(0xFF0284C7).withValues(alpha: 0.12);
        break;
      case NotificationCategory.system:
        icon = Icons.info_outline;
        iconColor = VroomColors.text;
        bgColor = VroomColors.surfaceMuted;
        break;
    }

    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VroomColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notif.isRead ? VroomColors.border : VroomColors.primary.withValues(alpha: 0.4),
          width: notif.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: VroomColors.text,
                        ),
                      ),
                    ),
                    Text(
                      notif.timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: VroomColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: VroomColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (notif.title.toLowerCase().contains('booking') ||
            notif.title.toLowerCase().contains('request')) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RiderRequestsScreen()),
          );
        }
      },
      child: card,
    );
  }
}
