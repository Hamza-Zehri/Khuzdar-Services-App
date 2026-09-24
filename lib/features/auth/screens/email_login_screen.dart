import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_logo.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0E7A5F), Color(0xFF0B5D47), Color(0xFF063D2E)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top branding
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                        child: Column(
                          children: [
                            const AppLogo(size: 84),
                            const SizedBox(height: 20),
                            const Text(
                              'Khuzdar Services',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your Local Marketplace',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // White card
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('official_login'),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                context.tr('google_login_desc'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Google button
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: OutlinedButton(
                                  onPressed: _loading ? null : _loginWithGoogle,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.textPrimary,
                                    side: const BorderSide(
                                      color: AppColors.border,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              color: AppColors.primary,
                                              strokeWidth: 2.5),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const _GoogleG(),
                                            const SizedBox(width: 12),
                                            Text(
                                              context.tr('continue_google'),
                                              style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              const Center(
                                child: Text(
                                  'By continuing, you agree to our Terms & Privacy Policy.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Language switcher
                              Center(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.language,
                                      size: 18, color: AppColors.textMuted),
                                  label: Text(
                                    context.isUrdu
                                        ? 'Switch to English'
                                        : 'اردو میں تبدیل کریں',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13),
                                  ),
                                  onPressed: () {
                                    context.read<LanguageProvider>().setLocale(
                                        context.isUrdu ? 'en' : 'ur');
                                  },
                                ),
                              ),

                              const SizedBox(height: 16),
                              const Center(
                                child: Text(
                                  '© Developed by Engr. Hamza Asad',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFBBBBBB),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    final auth = context.read<AuthAppProvider>();
    final success = await auth.loginWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      if (auth.hasProfile) {
        context.go('/home');
      } else {
        // New user - need to complete profile (phone/address)
        context.go('/auth/register');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Sign in failed. Please try again with an official Gmail.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF0F9D58)],
        ).createShader(bounds),
        child: const Icon(Icons.g_mobiledata, size: 28),
      ),
    );
  }
}
