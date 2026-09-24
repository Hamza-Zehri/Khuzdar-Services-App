import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/auth_scaffold.dart';

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      header: AuthHeader(
        title: context.tr('otp_verify'),
        subtitle: context.tr('almost_done'),
        onBack: () => context.go('/auth/register'),
      ),
      card: Padding(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProgressSteps(active: 1),
            const SizedBox(height: 32),
            Text(
              context.tr('enter_phone'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('verify_identity_sms'),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            _buildLabel(context.tr('enter_phone')),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '+92',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: '3xx xxxxxxx',
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendOTP,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Send Code',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Already have an account? Sign In',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Future<void> _sendOTP() async {
    final phone = _controller.text.trim();
    if (phone.length != 10) {
      _showSnack('Please enter a valid 10-digit number.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = context.read<AuthAppProvider>();
      await auth.sendOTP('+92$phone');

      if (!mounted) return;
      final data = Map<String, String>.from(widget.registrationData);
      data['phone'] = '+92$phone';
      context.go('/auth/otp', extra: data);
    } catch (e) {
      _showSnack(
        e is String && e.isNotEmpty
            ? e
            : 'Failed to send code. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.primary,
    ));
  }
}
