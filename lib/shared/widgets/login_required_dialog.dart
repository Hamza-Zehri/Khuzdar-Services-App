import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../providers/language_provider.dart';

class LoginRequiredDialog extends StatelessWidget {
  const LoginRequiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        context.isUrdu ? 'لاگ ان درکار ہے' : 'Login Required',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Text(
        context.isUrdu
            ? 'سروس فراہم کنندگان سے بات کرنے کے لیے براہ کرم لاگ ان کریں۔'
            : 'Please login to interact with service providers and start chatting.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.isUrdu ? 'بعد میں' : 'Later',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.push('/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(context.isUrdu ? 'لاگ ان کریں' : 'Login'),
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LoginRequiredDialog(),
    );
  }
}
