import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PromoScreen extends StatelessWidget {
  const PromoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final promoId = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Promotion'),
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
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_offer, color: Color(0xFFF59E0B), size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Promotion spéciale !',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            const SizedBox(height: 12),
            Text(
              promoId != null ? 'Promo #$promoId' : 'Détails de la promotion',
              style: const TextStyle(fontSize: 16, color: AppColors.lightText),
            ),
          ],
        ),
      ),
    );
  }
}
