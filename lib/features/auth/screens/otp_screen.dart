import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/auth_scaffold.dart';

class OtpScreen extends StatefulWidget {
  final Map<String, String> registrationData;

  const OtpScreen({super.key, required this.registrationData});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;

  String get _otp => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      header: AuthHeader(
        title: context.tr('verification_code'),
        subtitle: context.tr('almost_done'),
        onBack: () => context.go('/auth/phone', extra: widget.registrationData),
      ),
      card: Padding(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProgressSteps(active: 2),
            const SizedBox(height: 32),

            Text(
              context.tr('enter_6_digit'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('sent_to',
                  args: [widget.registrationData['phone'] ?? '']),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),

            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 56 - 40) / 6,
                  height: 62,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 5) {
                        _focusNodes[i + 1].requestFocus();
                      } else if (v.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                      if (_otp.length == 6) {
                        _verify();
                      }
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        context.tr('verify_complete'),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr('didnt_receive'),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _resendOTP,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.tr('resend_code'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resendOTP() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthAppProvider>();
      await auth.sendOTP(widget.registrationData['phone'] ?? '');
      if (mounted) _showSnack('Verification code resent.');
    } catch (e) {
      if (mounted) _showSnack('Failed to resend code.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    if (_otp.length != 6 || _loading) return;
    setState(() => _loading = true);

    try {
      final auth = context.read<AuthAppProvider>();
      final success = await auth.verifyOTP(_otp);

      if (!mounted) return;

      if (success) {
        final regData = widget.registrationData;
        final complete = await auth.completeRegistration(
          email: regData['email'] ?? '',
          password: regData['password'] ?? '',
          name: regData['name'] ?? '',
          phone: regData['phone'] ?? '',
          address: regData['address'] ?? '',
        );

        if (complete && mounted) {
          context.go('/auth/role');
        } else if (mounted) {
          _showSnack('Registration failed. Please try again.', isError: true);
        }
      } else {
        _showSnack('Invalid verification code. Please try again.',
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('An error occurred. Please try again.', isError: true);
      }
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
