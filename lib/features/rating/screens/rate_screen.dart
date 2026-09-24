import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/all_models.dart';
import '../../../core/services/firestore_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/status_view.dart';

class RateScreen extends StatefulWidget {
  final String jobId;

  const RateScreen({super.key, required this.jobId});

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  double _rating = 4.0;
  final _commentController = TextEditingController();
  bool _loading = false;

  Future<(JobModel?, UserModel?, bool)> _load() async {
    final auth = context.read<AuthAppProvider>();
    final currentUid = auth.uid ?? '';
    final firestore = FirestoreService();

    final job = await firestore.getJob(widget.jobId);
    if (job == null) return (null, null, false);

    final targetId =
        (currentUid == job.userId) ? job.providerId : job.userId;
    final target = await firestore.getUser(targetId);
    final rated = await firestore.hasUserRated(widget.jobId, currentUid);
    return (job, target, rated);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rating Dein')),
      body: FutureBuilder<(JobModel?, UserModel?, bool)>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading...');
          }
          if (snap.hasError || snap.data?.$1 == null) {
            return const EmptyView(
              icon: Icons.error_outline,
              message: 'Job not found',
              detail: 'This job may have been removed.',
            );
          }

          final (_, target, rated) = snap.data!;
          if (rated) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: AppColors.online, size: 72),
                    const SizedBox(height: 16),
                    Text('Aap pehle hi rating de chuke hain!',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Shukriya, aapki raay kaam aayegi.',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: target?.profilePic != null
                      ? NetworkImage(target!.profilePic!)
                      : null,
                  child: target?.profilePic == null
                      ? Text(
                          (target?.name ?? '?').isEmpty
                              ? '?'
                              : target!.name[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 24, color: AppColors.textPrimary))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  '${target?.name ?? 'Partner'} ko rate karein',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text('Kaam kaisa raha?',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),

                // Star rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => _rating = i + 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          i < _rating ? Icons.star : Icons.star_border,
                          color: AppColors.accent,
                          size: 48,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 8),
                Text(
                  _ratingLabel(_rating),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),

                const SizedBox(height: 24),

                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Koi baat kehni hai? (Optional)',
                  ),
                ),

                const Spacer(),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Rating Submit Karein'),
                ),

                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Skip'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _ratingLabel(double r) {
    if (r >= 5) return 'Zabardast! ⭐⭐⭐⭐⭐';
    if (r >= 4) return 'Bahut Acha ⭐⭐⭐⭐';
    if (r >= 3) return 'Theek Tha ⭐⭐⭐';
    if (r >= 2) return 'Thoda Theek ⭐⭐';
    return 'Bura Tha ⭐';
  }

  Future<void> _submit() async {
    final auth = context.read<AuthAppProvider>();
    final currentUid = auth.uid;
    if (currentUid == null) return;

    setState(() => _loading = true);

    try {
      final firestore = FirestoreService();
      final job = await firestore.getJob(widget.jobId);
      if (job != null) {
        final toUserId =
            (currentUid == job.userId) ? job.providerId : job.userId;
        await firestore.submitRating(
          fromUserId: currentUid,
          toUserId: toUserId,
          jobId: widget.jobId,
          rating: _rating,
          comment: _commentController.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shukriya! Aapki rating submit ho gayi.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rating submit nahi hui: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}