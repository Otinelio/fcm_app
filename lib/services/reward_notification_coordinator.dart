import 'package:flutter/foundation.dart';

class RewardNotificationCoordinator {
  // Singleton pattern
  RewardNotificationCoordinator._privateConstructor();
  static final RewardNotificationCoordinator instance = RewardNotificationCoordinator._privateConstructor();

  final Set<int> _displayedRewardIds = {};
  
  // ValueNotifier pour avertir le HomeScreen de recharger les points
  // lorsqu'un utilisateur tape sur une notification FCM en arrière-plan.
  final ValueNotifier<int> onPointsRefreshRequested = ValueNotifier<int>(0);

  /// Retourne true si ce reward peut être affiché (pas déjà vu),
  /// et le marque comme traité pour éviter un doublon ultérieur.
  bool shouldDisplay(int rewardId) {
    if (_displayedRewardIds.contains(rewardId)) {
      return false;
    }
    _displayedRewardIds.add(rewardId);
    return true;
  }
  
  void requestPointsRefresh() {
    onPointsRefreshRequested.value++;
  }
}
