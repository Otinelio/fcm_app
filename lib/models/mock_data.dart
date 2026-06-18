import 'package:flutter/material.dart';

class NotificationModel {
  final String title;
  final String message;
  final String timestamp;
  final IconData icon;
  final Color iconColor;

  NotificationModel({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
  });
}

class MockData {
  static final List<String> recentRewards = [
    'Free Dessert',
    '20% Discount',
    'Free Cocktail',
  ];

  static final List<NotificationModel> notifications = [
    NotificationModel(
      title: 'Promo Notification',
      message: 'Happy Hour Tonight 🍹',
      timestamp: '2 min ago',
      icon: Icons.local_offer,
      iconColor: const Color(0xFFF59E0B), // Orange
    ),
    NotificationModel(
      title: 'Reward Notification',
      message: 'Reward Unlocked ⭐',
      timestamp: '10 min ago',
      icon: Icons.star,
      iconColor: const Color(0xFF10B981), // Green
    ),
    NotificationModel(
      title: 'Birthday Notification',
      message: 'Happy Birthday 🎂',
      timestamp: '1 day ago',
      icon: Icons.cake,
      iconColor: const Color(0xFF2563EB), // Blue
    ),
  ];
}
