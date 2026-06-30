import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/mock_data.dart';
import '../widgets/loyalty_card.dart';
import '../widgets/simulate_action_button.dart';
import '../widgets/reward_item_card.dart';
import '../services/api_service.dart';
import '../services/reverb_service.dart';
import '../services/reward_notification_coordinator.dart';
import 'login_screen.dart';
import 'loyalty_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  StreamSubscription? _reverbSubscription;
  final ReverbService _reverb = ReverbService();

  StreamSubscription? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ApiService.fetchProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
      });

      if (_profile != null && _profile!['id'] != null) {
        _reverb.connect();
        final customerId = _profile!['id'];
        final channelName = 'private-loyalty.$customerId';
        
        void _handleAuth(String socketId) async {
          try {
            // Canal privé (existant)
            final authData = await ApiService.authorizeChannel(socketId, channelName);
            _reverb.subscribeToPrivateChannel(channelName, authData);

            // Canal de présence (nouveau)
            final presenceChannelName = 'presence-customer.$customerId';
            final presenceAuthData = await ApiService.authorizeChannel(socketId, presenceChannelName);
            _reverb.subscribeToPresenceChannel(presenceChannelName, presenceAuthData);
          } catch (e) {
            print("Erreur auth Reverb: $e");
          }
        }

        _connectionSubscription?.cancel();
        _connectionSubscription = _reverb.onConnected.listen(_handleAuth);

        if (_reverb.socketId != null) {
          _handleAuth(_reverb.socketId!);
        }

        _reverbSubscription?.cancel();
        _reverbSubscription = _reverb.events.listen((message) {
          final eventName = message['event'] as String?;
          final channel = message['channel'] as String?;
          final data = message['data'] as Map<String, dynamic>;

          if (channel == channelName) {
            // Points update via private channel
            if (mounted) {
              setState(() {
                _profile!['loyalty_points'] = data['loyalty_points'];
              });
            }
          } else if (channel == 'presence-customer.$customerId') {
            // Reward unlocked via presence channel
            if (eventName == 'reward.unlocked') {
              final rewardId = data['reward_id'];
              
              if (rewardId != null && 
                  RewardNotificationCoordinator.instance.shouldDisplay(rewardId)) {
                _showRewardBanner(data['title'], data['description']);
                _loadProfile(); // Actualise le solde après déblocage
              }
              
              // Confirmation au backend que l'event a été traité (Ack)
              // L'ack part toujours, qu'on ait affiché la bannière ou bloqué un doublon
              if (rewardId != null) {
                ApiService.ackReward(rewardId);
              }
            }
          }
        });
        
        // Écoute des requêtes de rafraîchissement depuis le tap FCM
        RewardNotificationCoordinator.instance.onPointsRefreshRequested.addListener(_loadProfile);
      }
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _reverbSubscription?.cancel();
    super.dispose();
  }

  void _showRewardBanner(String title, String description) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎉 $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(description),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSimulationDialog(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulé : $title'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userName = _profile?['name'] ?? 'Utilisateur';
    final int loyaltyPoints = _profile?['loyalty_points'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Bouton rafraîchissement
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
            tooltip: 'Actualiser',
            onPressed: () {
              setState(() => _loading = true);
              _loadProfile();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryBlue),
            onPressed: () async {
              await ApiService.clearToken();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Bonjour, ${_profile?['name']?.split(' ').first ?? '...'} 👋',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Votre tableau de fidélité',
                  style: TextStyle(fontSize: 16, color: AppColors.lightText),
                ),
                const SizedBox(height: 24),

                // Loyalty Card — données réelles depuis la BDD
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Column(
                    children: [
                      LoyaltyCard(
                        userName: userName,
                        loyaltyPoints: loyaltyPoints,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_profile?['id'] != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoyaltyScreen(
                                    customerId: _profile!['id'] as int,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.bolt),
                          label: const Text('Voir le solde en direct (WebSocket)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),

                // Simulate Actions
                const Text(
                  'Simuler des événements FCM',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 16),
                SimulateActionButton(
                  title: 'Simuler une notification Promo',
                  icon: Icons.campaign,
                  onPressed: () async {
                    _showSimulationDialog(context, 'Promo Notification');
                    await ApiService.simulateEvent('promo');
                  },
                ),
                SimulateActionButton(
                  title: 'Simuler une notification Récompense',
                  icon: Icons.star_purple500,
                  onPressed: () async {
                    _showSimulationDialog(context, 'Reward Notification');
                    await ApiService.simulateEvent('reward');
                    // Reload points after reward simulation
                    await _loadProfile();
                  },
                ),
                SimulateActionButton(
                  title: 'Simuler une notification Anniversaire',
                  icon: Icons.cake,
                  onPressed: () async {
                    _showSimulationDialog(context, 'Birthday Notification');
                    await ApiService.simulateEvent('birthday');
                  },
                ),
                SimulateActionButton(
                  title: 'Simuler: Confirmation de connexion',
                  icon: Icons.login,
                  onPressed: () async {
                    _showSimulationDialog(context, 'Confirmation Connexion');
                    await ApiService.simulateEvent('login_confirmation');
                  },
                ),
                SimulateActionButton(
                  title: 'Simuler: Notif en ligne (Data)',
                  icon: Icons.phone_android,
                  onPressed: () async {
                    _showSimulationDialog(context, 'Message Silencieux');
                    await ApiService.simulateEvent('online_only');
                  },
                ),
                SimulateActionButton(
                  title: 'Simuler: Tous les users (Topic)',
                  icon: Icons.public,
                  onPressed: () async {
                    _showSimulationDialog(context, 'Broadcast Global');
                    await ApiService.simulateEvent('all_users');
                  },
                ),
                SimulateActionButton(
                  title: 'Simuler: >10 points (DB Query)',
                  icon: Icons.stars,
                  onPressed: () async {
                    _showSimulationDialog(context, 'Requête Base de données');
                    await ApiService.simulateEvent('points_gt_10');
                  },
                ),
                const SizedBox(height: 32),

                // Recent Rewards
                const Text(
                  'Récompenses récentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: MockData.recentRewards.length,
                    itemBuilder: (context, index) {
                      return RewardItemCard(title: MockData.recentRewards[index]);
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
