import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthAppProvider>().user;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block_flipped,
                  color: AppColors.danger, size: 80),
              const SizedBox(height: 24),
              Text(
                user?.blockReason == 'auto_client_review'
                    ? 'Aapko unfair reviews ki wajah se block kiya gaya'
                    : (user?.blockReason == 'auto_provider_rating'
                        ? 'Aapko low rating ki wajah se block kiya gaya'
                        : 'Aapka account block ho gaya'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _reasonDetail(user),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Agar ye ghalati hai to support ko rabta karein.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.read<AuthAppProvider>().signOut(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _reasonDetail(UserModel? user) {
    switch (user?.blockReason) {
      case 'auto_provider_rating':
        return 'Apni services par aapki avg rating 2 star se kam aur 3+ '
            'kaam mukammal hain. Khuzdar Services aisi low-quality '
            'services ko list se hata deta hai.';
      case 'auto_client_review':
        return 'Aapne 3+ ghair-munafiq (1-2 star) reviews diye hain. '
            'Unfair reviews na de kar providers ke saath insaaf karein.';
      case 'admin':
      default:
        return 'Kisi behtreen service ko yakeeni banane ke liye admin ne '
            'aapka account block kiya hai.';
    }
  }
}