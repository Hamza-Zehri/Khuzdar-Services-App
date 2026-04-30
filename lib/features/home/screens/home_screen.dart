import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/all_models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthAppProvider>();
    final notifications = context.watch<NotificationAppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(context.tr('app_name')),
            Text(
              context.isUrdu ? 'خضدار، بلوچستان' : 'Khuzdar, Balochistan',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
              if (notifications.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        notifications.unreadCount > 9
                            ? '9+'
                            : '${notifications.unreadCount}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                auth.user != null
                    ? context.tr('welcome_greeting', args: [auth.user!.name])
                    : (context.isUrdu ? 'خوش آمدید، مہمان' : 'Welcome, Guest'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('home_prompt'),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 24),

              // Category grid — dynamically loaded from Firestore
              Expanded(
                child: StreamBuilder<List<CategoryModel>>(
                  stream: FirestoreService().streamCategories(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final categories = snapshot.data ?? [];
                    
                    if (categories.isEmpty) {
                      return Center(
                        child: Text(
                          context.isUrdu ? 'کوئی کیٹیگری دستیاب نہیں' : 'No categories available',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, i) {
                        final cat = categories[i];
                        return _CategoryButton(
                          category: cat,
                          onTap: () => context.push('/providers/${cat.id}'),
                        );
                      },
                    );
                  },
                ),
              ),

              // Provider register CTA (if user has no provider profile)
              if (auth.user?.role == UserRole.customer)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    icon: const Icon(Icons.work_outline),
                    label: const Text('Khud ko service provider register karein'),
                    onPressed: () => context.push('/provider/register'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryButton({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                context.isUrdu ? category.labelUrdu : category.label,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
