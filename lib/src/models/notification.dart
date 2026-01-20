import 'package:flutter/material.dart';

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
