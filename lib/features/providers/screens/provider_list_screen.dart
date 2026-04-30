import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/all_models.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/presence_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/login_required_dialog.dart';

class ProviderListScreen extends StatelessWidget {
  final String category;

  const ProviderListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<List<CategoryModel>>(
          stream: service.streamCategories(),
          builder: (context, snap) {
            final categories = snap.data ?? [];
            final cat = categories.firstWhere((c) => c.id == category, orElse: () => CategoryModel(id: category, label: category, labelUrdu: '', emoji: '📁'));
            return Text('${cat.emoji} ${cat.label}');
          },
        ),
      ),
      body: StreamBuilder<List<ProviderModel>>(
        stream: service.streamProvidersByCategory(category),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: ${snap.error}\n\nSearch index shayed pending ho.'),
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final providers = snap.data ?? [];

          if (providers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😔', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'Is ilaqe mein koi available nahi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _ProviderCard(provider: providers[i]),
          );
        },
      ),
    );
  }
}

class _ProviderCard extends StatefulWidget {
  final ProviderModel provider;

  const _ProviderCard({required this.provider});

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  bool _startingChat = false;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final presence = PresenceService();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar with type badge
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: provider.profilePic != null
                          ? NetworkImage(provider.profilePic!)
                          : null,
                      child: provider.profilePic == null
                          ? Text(
                              provider.type == ProviderType.shop ? '🏪' : '👤',
                              style: const TextStyle(fontSize: 22),
                            )
                          : null,
                    ),
                    // Online badge
                    StreamBuilder<Map<String, dynamic>?>(
                      stream: presence.streamPresence(provider.userId),
                      builder: (context, snap) {
                        final isOnline = snap.data?['online'] == true;
                        return Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isOnline ? AppColors.online : AppColors.offline,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              provider.type == ProviderType.shop
                                  ? provider.shop?.shopName ?? 'Shop'
                                  : 'Provider',
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: provider.type == ProviderType.shop
                                  ? AppColors.info.withValues(alpha: 0.1)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              provider.type == ProviderType.shop ? '🏪 Shop' : '👤 Individual',
                              style: TextStyle(
                                fontSize: 11,
                                color: provider.type == ProviderType.shop
                                    ? AppColors.info
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.textSecondary),
                          Text(
                            ' ${provider.area}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.accent, size: 18),
                    const SizedBox(width: 2),
                    Text(
                      provider.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      ' (${provider.jobsCompleted} jobs)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),

                const Spacer(),

                // Availability
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: provider.isAvailable
                        ? AppColors.online.withValues(alpha: 0.1)
                        : AppColors.offline.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: provider.isAvailable ? AppColors.online : AppColors.offline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        provider.isAvailable ? 'Available' : 'Busy',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: provider.isAvailable ? AppColors.online : AppColors.offline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Start Chat CTA
            ElevatedButton.icon(
              icon: _startingChat
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.chat_bubble_outline, size: 20),
              label: Text(_startingChat ? 'Ruko...' : 'Chat Shuru Karein'),
              onPressed: provider.isAvailable && !_startingChat
                  ? () => _startChat()
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startChat() async {
    final auth = context.read<AuthAppProvider>();
    final currentUserId = auth.uid;
    if (currentUserId == null) {
      LoginRequiredDialog.show(context);
      return;
    }

    setState(() => _startingChat = true);

    try {
      final chat = await FirestoreService().startChat(
        userId: currentUserId,
        providerId: widget.provider.userId,
      );
      if (mounted) {
        context.push('/chat/${chat.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat shuru nahi hui: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }
}
