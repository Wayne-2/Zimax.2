import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsPage extends StatelessWidget {
  NotificationsPage({super.key});

  final List<AppNotification> notifications = [
    AppNotification(
      avatar: "https://i.pravatar.cc/150?img=3",
      title: "John Doe",
      body: "liked your post: “Flutter UI is getting insanely good 🚀”",
      time: "2m",
      icon: Icons.favorite,
      iconColor: Colors.pinkAccent,
      isRead: false,
    ),
    AppNotification(
      avatar: "https://i.pravatar.cc/150?img=5",
      title: "Mary",
      body: "started following you",
      time: "10m",
      icon: Icons.person_add_alt_1,
      iconColor: Colors.blue,
      isRead: false,
    ),
    AppNotification(
      avatar: "https://i.pravatar.cc/150?img=8",
      title: "Alex",
      body: "replied: “This is exactly how Twitter UI should look.”",
      time: "1h",
      icon: Icons.chat_bubble,
      iconColor: Colors.green,
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Flat design
        centerTitle: false, // Instagram style is left-aligned
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(
            fontSize: 18, // Slightly larger
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _NotificationTile(notification: notifications[index]);
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {}, // Adds modern ripple effect
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with Badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: NetworkImage(notification.avatar),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      notification.icon,
                      size: 14,
                      color: notification.iconColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: "${notification.title} ",
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: notification.body,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: notification.isRead 
                                ? FontWeight.w400 
                                : FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: "  ${notification.time}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Unread Indicator
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue, // Instagram/Twitter Blue
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Minimal model structure for reference
class AppNotification {
  final String avatar;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isRead;

  AppNotification({
    required this.avatar,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
  });
}