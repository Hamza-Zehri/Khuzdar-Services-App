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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Text(
                  context.tr('app_name'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                context.tr('login'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: context.tr('enter_email'),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(context.tr('login')),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Account nahi hai?'),
                  TextButton(
                    onPressed: () => context.go('/auth/register'),
                    child: Text(context.tr('register')),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Language Switcher
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.language),
                  label: Text(context.isUrdu ? 'Switch to English' : 'اردو میں تبدیل کریں'),
                  onPressed: () {
                    context.read<LanguageProvider>().setLocale(context.isUrdu ? 'en' : 'ur');
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Developer Credits
              const Center(
                child: Text(
                  '© Developed by Engr. Hamza Asad',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email aur password daalein')),
      );
      return;
    }

    setState(() => _loading = true);
    final success = await context.read<AuthAppProvider>().loginWithEmail(email, password);
    setState(() => _loading = false);

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login fail hua. Credentials check karein.')),
      );
    }
  }
}
