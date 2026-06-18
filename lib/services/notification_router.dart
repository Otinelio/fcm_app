import 'package:flutter/material.dart';

void handleNotificationTap(
  GlobalKey<NavigatorState> navigatorKey,
  Map<String, dynamic> data,
) {
  final type = data['type'];
  switch (type) {
    case 'reward':
      navigatorKey.currentState?.pushNamed(
        '/reward',
        arguments: data['reward_id'],
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
