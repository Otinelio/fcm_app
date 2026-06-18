import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rewardId = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Récompense'),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Color(0xFF10B981), size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Récompense débloquée !',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            const SizedBox(height: 12),
            Text(
              rewardId != null ? 'Récompense #$rewardId' : 'Détails de la récompense',
              style: const TextStyle(fontSize: 16, color: AppColors.lightText),
            ),
          ],
        ),
      ),
    );
  }
}
