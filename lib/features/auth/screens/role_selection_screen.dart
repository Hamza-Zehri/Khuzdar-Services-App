import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/all_models.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../shared/theme/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E7A5F), Color(0xFF0B5D47), Color(0xFF063D2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  context.isUrdu ? 'آپ کون ہیں؟' : 'Who are you?',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.isUrdu
                      ? 'اپنا کردار منتخب کریں'
                      : 'Choose how you want to use this app',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 40),

                // Customer Option
                _RoleCard(
                  title: 'Customer',
                  description: context.isUrdu
                      ? 'مجھے خدمت چاہیے (بجلی والا، پلمبر وغیرہ)'
                      : 'I need a service (electrician, plumber, etc.)',
                  icon: '🏠',
                  color: AppColors.info,
                  onTap: () => _selectRole(context, UserRole.customer),
                ),

                const SizedBox(height: 16),

                // Provider Option
                _RoleCard(
                  title: context.isUrdu ? 'سروس پرووائیڈر' : 'Service Provider',
                  description: context.isUrdu
                      ? 'میں ہنرمند ہوں اور کام کرنا چاہتا ہوں'
                      : 'I am skilled and want to offer my services',
                  icon: '🛠️',
                  color: AppColors.primary,
                  onTap: () => _selectRole(context, UserRole.provider),
                ),

                const Spacer(),

                Center(
                  child: TextButton.icon(
                    onPressed: () => context.read<AuthAppProvider>().signOut(),
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white70, size: 18),
                    label: Text(
                      context.isUrdu ? 'لاگ آؤٹ' : 'Logout',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
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
        SnackBar(
            content: Text('Error updating role: $e'),
            backgroundColor: AppColors.danger),
      );
    }
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
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
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 28)),
              ),
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
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
