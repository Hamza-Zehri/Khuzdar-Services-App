import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/all_models.dart';
import '../../../shared/theme/app_theme.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthAppProvider>();
    final firestoreService = FirestoreService();

    return StreamBuilder<ProviderModel?>(
      stream: firestoreService.streamProvider(auth.uid ?? ''),
      builder: (context, snapshot) {
        final provider = snapshot.data;
        if (provider == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
                context.isUrdu ? 'پرووائیڈر ڈیش بورڈ' : 'Provider Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () =>
                    context.read<AuthAppProvider>().toggleProviderMode(),
                tooltip: context.tr('switch_to_customer'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row
                Row(
                  children: [
                    _StatCard(
                      label: context.isUrdu ? 'ریٹنگ' : 'Rating',
                      value: provider.rating.toStringAsFixed(1),
                      icon: Icons.star,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      label: context.isUrdu ? 'کل کام' : 'Total Jobs',
                      value: provider.jobsCompleted.toString(),
                      icon: Icons.work_history,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Availability Toggle
                Card(
                  child: SwitchListTile(
                    title: Text(context.isUrdu
                        ? 'دستیابی (Availability)'
                        : 'Available for Work'),
                    subtitle: Text(context.isUrdu
                        ? 'اگر آپ مصروف ہیں تو اسے بند کر دیں'
                        : 'Turn off if you are busy'),
                    value: provider.isAvailable,
                    onChanged: (v) => auth.toggleAvailability(v),
                    activeThumbColor: AppColors.online,
                  ),
                ),
                const SizedBox(height: 32),

                // Broadcasts Section
                Text(
                  context.isUrdu
                      ? 'ایڈمن کے اعلانات (Admin Broadcasts)'
                      : 'Admin Broadcasts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: firestoreService.streamBroadcastJobs(),
                  builder: (context, snapshot) {
                    final broadcasts = snapshot.data ?? [];
                    if (broadcasts.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      height: 130,
                      margin: const EdgeInsets.only(bottom: 24),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: broadcasts.length,
                        itemBuilder: (context, index) {
                          final b = broadcasts[index];
                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.campaign,
                                        color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        b['title'] ?? 'Update',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  b['body'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.4),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                Text(
                  context.isUrdu ? 'فعال بات چیت' : 'Active Chats',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // List of active client chats
                StreamBuilder<List<ChatModel>>(
                  stream: firestoreService.streamProviderChats(auth.uid ?? ''),
                  builder: (context, chatSnapshot) {
                    if (chatSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chats = chatSnapshot.data ?? [];
                    if (chats.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Text(
                            context.isUrdu
                                ? 'ابھی کوئی نیا کام نہیں ہے۔'
                                : 'No active requests yet.',
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: chats.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return _ChatTile(chat: chat);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                context.read<AuthAppProvider>().toggleProviderMode(),
            label: Text(context.tr('switch_to_customer')),
            icon: const Icon(Icons.swap_horiz),
          ),
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: FirestoreService().getUser(chat.userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user?.profilePic != null
                ? NetworkImage(user!.profilePic!)
                : null,
            child: user?.profilePic == null
                ? Text(user?.name.characters.firstOrNull?.toUpperCase() ?? '?')
                : null,
          ),
          title: Text(user?.name ?? 'Customer'),
          subtitle: Text(
            chat.lastMessage ??
                (context.read<LanguageProvider>().isUrdu
                    ? 'نئی درخواست'
                    : 'New Request'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => GoRouter.of(context).push('/chat/${chat.id}'),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
