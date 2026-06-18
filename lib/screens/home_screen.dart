import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/mock_data.dart';
import '../widgets/loyalty_card.dart';
import '../widgets/simulate_action_button.dart';
import '../widgets/reward_item_card.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showSimulationDialog(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulated: $title'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Hello, John 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your Loyalty Dashboard',
                style: TextStyle(fontSize: 16, color: AppColors.lightText),
              ),
              const SizedBox(height: 24),

              // Loyalty Card
              const LoyaltyCard(),
              const SizedBox(height: 32),

              // Simulate Actions
              const Text(
                'Simulate FCM Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 16),
              SimulateActionButton(
                title: 'Simulate Promo Notification',
                icon: Icons.campaign,
                onPressed: () async {
                  _showSimulationDialog(context, 'Promo Notification');
                  await ApiService.simulateEvent('promo');
                },
              ),
              SimulateActionButton(
                title: 'Simulate Reward Notification',
                icon: Icons.star_purple500,
                onPressed: () async {
                  _showSimulationDialog(context, 'Reward Notification');
                  await ApiService.simulateEvent('reward');
                },
              ),
              SimulateActionButton(
                title: 'Simulate Birthday Notification',
                icon: Icons.cake,
                onPressed: () async {
                  _showSimulationDialog(context, 'Birthday Notification');
                  await ApiService.simulateEvent('birthday');
                },
              ),
              SimulateActionButton(
                title: 'Simulate VIP Broadcast (Topic)',
                icon: Icons.diamond,
                onPressed: () async {
                  _showSimulationDialog(context, 'VIP Broadcast');
                  await ApiService.simulateEvent('vip');
                },
              ),
              const SizedBox(height: 32),

              // Recent Rewards
              const Text(
                'Recent Rewards',
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
    );
  }
}
