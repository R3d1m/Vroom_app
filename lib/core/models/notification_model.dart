enum NotificationCategory {
  ride,
  payment,
  security,
  system,
}

class VroomNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationCategory category;
  bool isRead;

  VroomNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.category = NotificationCategory.system,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'category': category.name,
    'isRead': isRead,
  };

  factory VroomNotification.fromJson(Map<String, dynamic> json) {
    NotificationCategory cat = NotificationCategory.system;
    final c = json['category']?.toString();
    if (c == 'ride') cat = NotificationCategory.ride;
    if (c == 'payment') cat = NotificationCategory.payment;
    if (c == 'security') cat = NotificationCategory.security;

    return VroomNotification(
      id: json['id']?.toString() ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      category: cat,
      isRead: json['isRead'] == true,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
