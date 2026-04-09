import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rating Dein')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('😊', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Kaam kaisa raha?',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Rating Submit Karein'),
            ),

            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Skip'),
            ),
          ],
        ),
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
    setState(() => _loading = true);
    // Submit logic
    setState(() => _loading = false);
    if (mounted) context.pop();
  }
}
