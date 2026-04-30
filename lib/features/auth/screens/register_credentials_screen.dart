import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/language_provider.dart';

class RegisterCredentialsScreen extends StatefulWidget {
  const RegisterCredentialsScreen({super.key});

  @override
  State<RegisterCredentialsScreen> createState() =>
      _RegisterCredentialsScreenState();
}

class _RegisterCredentialsScreenState extends State<RegisterCredentialsScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('register'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Aakhri qadam! Apni details bharein',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naam (Name)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: context.tr('address'),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
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
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.tr('password'),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 8),
            _buildPasswordValidationRow(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Complete Registration'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordValidationRow() {
    final password = _passwordController.text;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final hasMinLength = password.length >= 8;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _validationItem('8+ Chars', hasMinLength),
        _validationItem('Capital (A)', hasUppercase),
        _validationItem('Number (1)', hasDigits),
        _validationItem('Special (!)', hasSpecial),
      ],
    );
  }

  Widget _validationItem(String text, bool isValid) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.circle_outlined,
          size: 14,
          color: isValid ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isValid ? Colors.green : Colors.grey,
            fontWeight: isValid ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || address.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saray fields bharna zaroori hain')),
      );
      return;
    }

    // Strong Password Validation
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final hasMinLength = password.length >= 8;

    if (!hasUppercase || !hasDigits || !hasLowercase || !hasSpecialCharacters || !hasMinLength) {
      String message = 'Password mazboot hona zaroori hai:\n';
      if (!hasMinLength) message += '• Kam az kam 8 haroof\n';
      if (!hasUppercase) message += '• Aik bara harf (A-Z)\n';
      if (!hasDigits) message += '• Aik adad (0-9)\n';
      if (!hasSpecialCharacters) message += '• Aik special character (!@#...)\n';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Instead of signing up here, we go to phone verification first
    context.go('/auth/phone', extra: {
      'name': name,
      'email': email,
      'password': password,
      'address': address,
    });
  }
}
