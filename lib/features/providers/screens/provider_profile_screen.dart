import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/all_models.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/presence_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/status_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/login_required_dialog.dart';

class ProviderProfileScreen extends StatelessWidget {
  final String category;
  final String providerId;

  const ProviderProfileScreen({
    super.key,
    required this.category,
    required this.providerId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProviderModel?>(
      stream: FirestoreService().streamProvider(providerId),
      builder: (context, snap) {
        final provider = snap.data;

        if (snap.connectionState == ConnectionState.waiting && provider == null) {
          return const Scaffold(body: LoadingView(message: 'Loading...'));
        }

        if (provider == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyView(
              icon: Icons.person_off_outlined,
              message: 'Provider not found',
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileHeader(provider: provider),
              const SizedBox(height: 20),

              // Stats
              Row(
                children: [
                  _StatBox(
                    icon: Icons.star_rounded,
                    value: provider.rating.toStringAsFixed(1),
                    label: 'Rating',
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  _StatBox(
                    icon: Icons.work_history_rounded,
                    value: provider.jobsCompleted.toString(),
                    label: 'Jobs Done',
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // About card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('About',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: provider.area.isEmpty
                            ? 'Khuzdar'
                            : provider.area,
                      ),
                      if (provider.type == ProviderType.shop &&
                          provider.shop != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.storefront_outlined,
                          text: provider.shop!.shopName,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.map_outlined,
                          text: provider.shop!.shopAddress,
                        ),
                      ],
                      if (provider.profilePic == null) ...[
                        const SizedBox(height: 8),
                        const _InfoRow(
                          icon: Icons.verified_outlined,
                          text: 'Verified by Khuzdar Services',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Message CTA
              ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: const Text('Message'),
                onPressed: () => _startChat(context, provider),
              ),

              const SizedBox(height: 28),

              // Reviews
              SectionHeader(title: 'Reviews (${provider.jobsCompleted})'),
              const SizedBox(height: 12),
              StreamBuilder<List<RatingModel>>(
                stream: FirestoreService().streamRatingsFor(providerId),
                builder: (context, snap) {
                  final ratings = snap.data ?? [];
                  if (ratings.isEmpty) {
                    return const EmptyView(
                      icon: Icons.rate_review_outlined,
                      message: 'No reviews yet',
                      detail: 'Be the first to rate this provider.',
                    );
                  }
                  return Column(
                    children: [
                      for (final r in ratings) _ReviewTile(rating: r),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startChat(BuildContext context, ProviderModel provider) {
    final auth = context.read<AuthAppProvider>();
    if (auth.uid == null) {
      LoginRequiredDialog.show(context);
      return;
    }
    if (auth.uid == provider.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself.')),
      );
      return;
    }
    if (!provider.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This provider is currently busy.')),
      );
      return;
    }

    context
        .read<AuthAppProvider>()
        .startChatWith(provider.userId)
        .then((chatId) {
      if (chatId != null && context.mounted) {
        context.push('/chat/$chatId');
      }
    });
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProviderModel provider;

  const _ProfileHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: FirestoreService().getUser(provider.userId),
      builder: (context, snap) {
        final user = snap.data;
        return Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: provider.profilePic != null
                      ? NetworkImage(provider.profilePic!)
                      : null,
                  child: provider.profilePic == null
                      ? Text(
                          provider.type == ProviderType.shop ? '🏪' : '👤',
                          style: const TextStyle(fontSize: 40),
                        )
                      : null,
                ),
                StreamBuilder<Map<String, dynamic>?>(
                  stream: PresenceService().streamPresence(provider.userId),
                  builder: (context, pSnap) {
                    final online = pSnap.data?['online'] == true;
                    return Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: online ? AppColors.online : AppColors.offline,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              provider.type == ProviderType.shop
                  ? (provider.shop?.shopName ?? 'Shop')
                  : (user?.name ?? 'Provider'),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            PillBadge(
              text: provider.isAvailable ? 'Available' : 'Busy',
              icon: Icons.circle,
              color: provider.isAvailable ? AppColors.online : AppColors.offline,
            ),
          ],
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final RatingModel rating;

  const _ReviewTile({required this.rating});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: FirestoreService().getUser(rating.fromUserId),
      builder: (context, snap) {
        final name = snap.data?.name ?? 'Customer';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < rating.rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: AppColors.accent,
                              );
                            }),
                          ),
                        ],
                      ),
                      if (rating.comment != null &&
                          rating.comment!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(rating.comment!,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}