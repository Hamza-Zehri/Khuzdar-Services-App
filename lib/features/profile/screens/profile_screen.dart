import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthAppProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile'))),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 32),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: user.profilePic != null ? NetworkImage(user.profilePic!) : null,
                  child: user.profilePic == null
                      ? Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32, color: Colors.white))
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  user.phone,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
                if (user.address != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      user.address!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 32),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(context.isUrdu ? 'اردو (Urdu)' : 'English'),
                  subtitle: Text(context.isUrdu ? 'English میں تبدیل کریں' : 'اردو میں تبدیل کریں'),
                  onTap: () async {
                    final newLocale = context.isUrdu ? 'en' : 'ur';
                    await context.read<LanguageProvider>().setLocale(newLocale);
                    // SYNC TO CORE
                    await auth.updateProfile(language: newLocale);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(context.isUrdu ? 'پروفائل تبدیل کریں' : 'Edit Profile'),
                  onTap: () => _showEditDialog(context, auth),
                ),
                if (user.role == UserRole.admin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.orange),
                    title: Text(
                      context.isUrdu ? 'ایڈمن پینل' : 'Admin Panel',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                    onTap: () => context.push('/admin'),
                  ),
                if (user.role == UserRole.provider)
                  ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: Text(context.tr(auth.isProviderMode ? 'switch_to_customer' : 'switch_to_provider')),
                    onTap: () {
                      auth.toggleProviderMode();
                      Navigator.pop(context); // Go back home
                    },
                  )
                else if (user.role == UserRole.customer)
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                    title: Text(
                      context.isUrdu ? 'سروس پرووائیڈر بنیں' : 'Become a Service Provider',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(context.isUrdu ? 'رجسٹریشن کے لیے یہاں کلک کریں' : 'Click to submit registration'),
                    onTap: () => context.push('/provider/register'),
                  ),
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: Text(context.isUrdu ? 'میری ریٹنگ' : 'My Rating'),
                  trailing: Text(user.rating.toStringAsFixed(1)),
                ),
                const Spacer(),
                // Developer Credits
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Center(
                    child: Text(
                      '© Developed by Engr. Hamza Asad',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: OutlinedButton(
                    onPressed: () => auth.signOut(),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: Text(context.isUrdu ? 'لاگ آؤٹ' : 'Logout'),
                  ),
                ),
              ],
            ),
    );
  }

  void _showEditDialog(BuildContext context, AuthAppProvider auth) {
    final nameController = TextEditingController(text: auth.user?.name);
    final addressController = TextEditingController(text: auth.user?.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.isUrdu ? 'پروفائل ایڈٹ کریں' : 'Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: context.isUrdu ? 'نام' : 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: context.isUrdu ? 'پتہ (Address)' : 'Address'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.isUrdu ? 'کینسل' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await auth.updateProfile(
                name: nameController.text.trim(),
                address: addressController.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(context.isUrdu ? 'سیو کریں' : 'Save'),
          ),
        ],
      ),
    );
  }
}
