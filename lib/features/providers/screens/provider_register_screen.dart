import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/all_models.dart';
import '../../../core/services/firestore_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class ProviderRegisterScreen extends StatefulWidget {
  const ProviderRegisterScreen({super.key});

  @override
  State<ProviderRegisterScreen> createState() => _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState extends State<ProviderRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  ProviderType _type = ProviderType.individual;
  ServiceCategory _category = ServiceCategory.electrician;
  String _area = 'Khuzdar City';
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register as Provider')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apni details bharein',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              // Type
              const Text('Aap kis tarah kaam karte hain?', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TypeChoice(
                      label: 'Individual',
                      icon: Icons.person_outline,
                      isSelected: _type == ProviderType.individual,
                      onTap: () => setState(() => _type = ProviderType.individual),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeChoice(
                      label: 'Shop',
                      icon: Icons.storefront_outlined,
                      isSelected: _type == ProviderType.shop,
                      onTap: () => setState(() => _type = ProviderType.shop),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Category
              const Text('Service Category', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<ServiceCategory>(
                value: _category,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                items: ServiceCategory.values.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text('${c.emoji} ${c.label}'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),

              const SizedBox(height: 24),

              // Shop specific fields
              if (_type == ProviderType.shop) ...[
                const Text('Shop Details', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(hintText: 'Shop ka naam'),
                  validator: (v) => v!.isEmpty ? 'Naam lazmi hai' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _shopAddressController,
                  decoration: const InputDecoration(hintText: 'Shop ka pata (Address)'),
                  validator: (v) => v!.isEmpty ? 'Pata lazmi hai' : null,
                ),
                const SizedBox(height: 24),
              ],

              // Area
              const Text('Ilaqa (Area)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _area,
                decoration: const InputDecoration(hintText: 'Example: Jinnah Road, Khuzdar'),
                onChanged: (v) => _area = v,
                validator: (v) => v!.isEmpty ? 'Area lazmi hai' : null,
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Application Submit Karein'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final auth = context.read<AuthAppProvider>();
    final firestore = FirestoreService();

    final provider = ProviderModel(
      id: const Uuid().v4(),
      userId: auth.uid!,
      type: _type,
      category: _category,
      area: _area,
      shop: _type == ProviderType.shop
          ? ShopInfo(
              shopName: _shopNameController.text.trim(),
              shopAddress: _shopAddressController.text.trim(),
            )
          : null,
      createdAt: DateTime.now(),
    );

    await firestore.createProvider(provider);
    // Also update user role to provider if it was customer
    await auth.signOut(); // Force re-login or refresh to see new role

    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submit ho gayi! Admin verify karega.')),
      );
      context.go('/auth/phone');
    }
  }
}

class _TypeChoice extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChoice({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
