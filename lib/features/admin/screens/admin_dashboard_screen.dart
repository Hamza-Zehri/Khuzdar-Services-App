import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/all_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../providers/language_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.isUrdu ? 'ایڈمن ڈیش بورڈ' : 'Admin Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.isUrdu ? 'زیر التوا درخواستیں' : 'Pending Provider Requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ProviderModel>>(
              stream: firestore.streamPendingProviders(),
              builder: (context, snapshot) {
                final pending = snapshot.data ?? [];
                if (pending.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        context.isUrdu ? 'کوئی نئی درخواست نہیں' : 'No pending requests',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final p = pending[i];
                    return _PendingProviderCard(provider: p);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingProviderCard extends StatelessWidget {
  final ProviderModel provider;
  const _PendingProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(provider.shop?.shopName ?? 'Individual Provider'),
              subtitle: StreamBuilder<List<CategoryModel>>(
                stream: firestore.streamCategories(),
                builder: (context, snap) {
                  final cat = (snap.data ?? []).firstWhere((c) => c.id == provider.categoryId, orElse: () => CategoryModel(id: provider.categoryId, label: provider.categoryId, labelUrdu: '', emoji: ''));
                  return Text('${cat.label} • ${provider.area}');
                },
              ),
              trailing: const Icon(Icons.info_outline),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => firestore.updateProviderVerification(provider.userId, VerificationStatus.rejected),
                  child: const Text('Reject', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => firestore.updateProviderVerification(provider.userId, VerificationStatus.approved),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.online),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
