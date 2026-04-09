import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthAppProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
                const SizedBox(height: 32),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  trailing: Text(user.language.toUpperCase()),
                ),
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('My Rating'),
                  trailing: Text(user.rating.toStringAsFixed(1)),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: OutlinedButton(
                    onPressed: () => auth.signOut(),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
    );
  }
}
