import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../shared/theme/app_theme.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D6B52),
              Color(0xFF09503C),
              Color(0xFF063D2E),
            ],
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
                      padding: const EdgeInsets.fromLTRB(24, 64, 24, 48),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text('🏪', style: TextStyle(fontSize: 40)),
                            ),
                          ),
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
                              color: Colors.white.withOpacity(0.7),
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
                        padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('official_login'),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.tr('google_login_desc'),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 48),

                            // Google button
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: OutlinedButton(
                                onPressed: _loading ? null : _loginWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1A1A1A),
                                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
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
                                            color: AppColors.primary, strokeWidth: 2.5),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.network(
                                            'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                            height: 24,
                                            errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata, size: 28),
                                          ),
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
                                  color: Color(0xFF999999),
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            const Spacer(),

                            // Language switcher
                            Center(
                              child: TextButton.icon(
                                icon: const Icon(Icons.language,
                                    size: 18, color: Color(0xFF999999)),
                                label: Text(
                                  context.isUrdu
                                      ? 'Switch to English'
                                      : 'اردو میں تبدیل کریں',
                                  style: const TextStyle(
                                      color: Color(0xFF999999), fontSize: 13),
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
    );
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    final auth = context.read<AuthAppProvider>();
    final success = await auth.loginWithGoogle();
    setState(() => _loading = false);

    if (success && mounted) {
      if (auth.hasProfile) {
        context.go('/home');
      } else {
        // New user - need to complete profile (phone/address)
        context.go('/auth/register');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sign in failed. Please try again with an official Gmail.'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
