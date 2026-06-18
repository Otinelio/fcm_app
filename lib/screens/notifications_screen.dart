import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/mock_data.dart';
import '../widgets/notification_item_card.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final apiNotifications = await ApiService.fetchNotifications();

    if (apiNotifications.isNotEmpty) {
      _notifications = apiNotifications.map((item) {
        final type = item['type'] ?? 'promo';
        return NotificationModel(
          title: item['title'] ?? '',
          message: item['body'] ?? '',
          timestamp: _formatDate(item['sent_at']),
          icon: _iconForType(type),
          iconColor: _colorForType(type),
        );
      }).toList();
    } else {
      // Fallback sur les données mock si aucune notification
      _notifications = MockData.notifications;
    }

    setState(() => _isLoading = false);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}j';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'reward': return Icons.star;
      case 'birthday': return Icons.cake;
      case 'reminder': return Icons.alarm;
      default: return Icons.local_offer;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'reward': return const Color(0xFF10B981);
      case 'birthday': return const Color(0xFF2563EB);
      case 'reminder': return const Color(0xFF8B5CF6);
      default: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune notification',
                        style: TextStyle(color: AppColors.lightText, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return NotificationItemCard(notification: notification);
                      },
                    ),
            ),
    );
  }
}
