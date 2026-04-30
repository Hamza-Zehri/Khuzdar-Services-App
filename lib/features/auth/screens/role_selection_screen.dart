import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/all_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'Aap kaun hain?',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Apna role select karein',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),

              // Customer Option
              _RoleCard(
                title: 'Customer',
                description: 'Mujhe service chahiye (Bijli wala, Plumber, etc.)',
                icon: '🏠',
                onTap: () => _selectRole(context, UserRole.customer),
              ),

              const SizedBox(height: 16),

              // Provider Option
              _RoleCard(
                title: 'Service Provider',
                description: 'Main hunar mand hun aur kaam karna chahta hun',
                icon: '🛠️',
                onTap: () => _selectRole(context, UserRole.provider),
              ),

              const Spacer(),

              Center(
                child: TextButton(
                  onPressed: () => context.read<AuthAppProvider>().signOut(),
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectRole(BuildContext context, UserRole role) async {
    try {
      final authApp = context.read<AuthAppProvider>();
      final uid = authApp.uid;
      
      if (uid != null) {
        final authService = AuthService();
        await authService.updateUserRole(uid, role);
        await authApp.refreshUser(); // Sync the local profile
      }

      if (!context.mounted) return;

      if (role == UserRole.provider) {
        // Check if provider profile already exists
        final firestoreService = FirestoreService();
        final provider = await firestoreService.streamProvider(uid!).first;

        if (!context.mounted) return;
        if (provider != null) {
          // Already registered — enable provider mode then go to dashboard
          await authApp.enableProviderMode();
          if (context.mounted) context.go('/home');
        } else {
          context.push('/provider/register');
        }
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating role: $e'), backgroundColor: AppColors.danger),
      );
    }
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                       description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
