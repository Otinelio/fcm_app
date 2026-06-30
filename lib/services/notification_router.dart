import 'package:flutter/material.dart';
import 'reward_notification_coordinator.dart';

void handleNotificationTap(
  GlobalKey<NavigatorState> navigatorKey,
  Map<String, dynamic> data,
) {
  final type = data['type'];
  switch (type) {
    case 'reward':
    case 'reward_unlocked':
      final String rawRewardId = data['reward_id']?.toString() ?? '0';
      final int rewardId = int.tryParse(rawRewardId) ?? 0;
      
      // On affiche l'écran de reward, mais on rafraîchit aussi les points sur HomeScreen
      if (rewardId > 0 && RewardNotificationCoordinator.instance.shouldDisplay(rewardId)) {
        RewardNotificationCoordinator.instance.requestPointsRefresh();
      }
      
      navigatorKey.currentState?.pushNamed(
        '/reward',
        arguments: rewardId,
      );
      break;
    case 'promo':
      navigatorKey.currentState?.pushNamed(
        '/promo',
        arguments: data['promo_id'],
      );
      break;
    default:
      navigatorKey.currentState?.pushNamed('/notifications');
  }
}
