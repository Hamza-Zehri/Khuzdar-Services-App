import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../shared/theme/app_theme.dart';

class PhoneEntryScreen extends StatefulWidget {
  final Map<String, String> registrationData;

  const PhoneEntryScreen({super.key, required this.registrationData});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('register'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('enter_phone'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('verify_identity_sms'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              // Phone input
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('+92', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: InputDecoration(
                        hintText: context.tr('phone_hint'),
                        counterText: '',
                      ),
                      style: const TextStyle(fontSize: 20, letterSpacing: 2),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loading ? null : _sendOTP,
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(context.tr('next')),
              ),

              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/'),
                  child: Text(context.tr('already_have_account')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOTP() async {
    final phone = _controller.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('invalid_phone'))),
      );
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthAppProvider>();
    await auth.sendOTP('+92$phone');
    setState(() => _loading = false);

    if (mounted) {
      final data = Map<String, String>.from(widget.registrationData);
      data['phone'] = '+92$phone';
      context.go('/auth/otp', extra: data);
    }
  }
}
