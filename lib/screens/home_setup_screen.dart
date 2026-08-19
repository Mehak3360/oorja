import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/home_setup_provider.dart';
import '../models/home_model.dart';
import '../theme/app_theme.dart';
import 'auth_gate.dart';
import '../utils/electricity_providers.dart';

class HomeSetupScreen extends StatefulWidget {
  const HomeSetupScreen({super.key});

  @override
  State<HomeSetupScreen> createState() => _HomeSetupScreenState();
}

class _HomeSetupScreenState extends State<HomeSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cityController = TextEditingController();
  final _budgetController = TextEditingController();
  final _tariffController = TextEditingController();
  final _familyMembersController = TextEditingController();

  String _selectedHouseType = '2BHK';
  final List<String> _houseTypes = ['1BHK', '2BHK', '3BHK', 'Villa', 'Independent House'];

  String _selectedProvider = ElectricityProviders.names.first;

  @override
  void dispose() {
    _cityController.dispose();
    _budgetController.dispose();
    _tariffController.dispose();
    _familyMembersController.dispose();
    super.dispose();
  }

  /// Providers in this app use slab (telescopic) billing, but the rest of the
  /// app (Dashboard, Rooms, Report) works off a single flat tariffPerUnit.
  /// To bridge the two without rewriting the calculation engine, we derive a
  /// representative flat rate from the provider's slabs at a typical monthly
  /// usage level (300 units/month is a common mid-size household benchmark).
  double _estimatedFlatTariff(String providerName) {
    final provider = ElectricityProviders.getByName(providerName);
    if (provider == null || provider.slabs.isEmpty) return 0;

    const typicalMonthlyUnits = 300.0;
    final cost = ElectricityProviders.calculateSlabCost(provider, typicalMonthlyUnits);
    return cost / typicalMonthlyUnits;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<app_auth.AuthProvider>();
    final homeSetupProvider = context.read<HomeSetupProvider>();
    final uid = authProvider.currentUser!.uid;

    final home = HomeModel(
      homeId: uid,
      houseType: _selectedHouseType,
      familyMembers: int.parse(_familyMembersController.text.trim()),
      city: _cityController.text.trim(),
      electricityProvider: _selectedProvider,
      monthlyBudget: double.parse(_budgetController.text.trim()),
      tariffPerUnit: _selectedProvider == 'Other / Custom'
          ? double.parse(_tariffController.text.trim())
          : _estimatedFlatTariff(_selectedProvider),
      setupComplete: true,
    );

    final success = await homeSetupProvider.submitHomeSetup(uid, home);

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(homeSetupProvider.errorMessage ?? 'Setup failed'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeSetupProvider = context.watch<HomeSetupProvider>();
    final estimatedTariff = _selectedProvider == 'Other / Custom'
        ? null
        : _estimatedFlatTariff(_selectedProvider);

    return Scaffold(
      backgroundColor: AppTheme.navyBackground,
      appBar: AppBar(
        title: const Text('Set Up Your Home'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tell us about your home',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This helps us estimate your energy usage accurately',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 28),

                // House Type dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedHouseType,
                  dropdownColor: AppTheme.cardBackground,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'House Type',
                    prefixIcon: Icon(Icons.home_outlined, color: AppTheme.textSecondary),
                  ),
                  items: _houseTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedHouseType = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Family Members
                TextFormField(
                  controller: _familyMembersController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Family Members',
                    prefixIcon: Icon(Icons.people_outline, color: AppTheme.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (int.tryParse(value) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // City
                TextFormField(
                  controller: _cityController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined, color: AppTheme.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Electricity Provider
                DropdownButtonFormField<String>(
                  initialValue: _selectedProvider,
                  dropdownColor: AppTheme.cardBackground,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Electricity Provider',
                    prefixIcon: Icon(Icons.bolt_outlined, color: AppTheme.textSecondary),
                  ),
                  items: ElectricityProviders.names.map((name) {
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedProvider = value!);
                  },
                ),

                // Auto-filled tariff preview — shown for all providers except Custom
                if (estimatedTariff != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppTheme.accentBlue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estimated tariff for $_selectedProvider: ₹${estimatedTariff.toStringAsFixed(2)}/unit '
                            '(based on typical usage — you can fine-tune this later in Profile).',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Monthly Budget
                TextFormField(
                  controller: _budgetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Budget (₹)',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: AppTheme.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tariff per unit — only shown for "Other / Custom" provider
                if (_selectedProvider == 'Other / Custom')
                  TextFormField(
                    controller: _tariffController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Electricity Tariff (₹ per unit)',
                      prefixIcon: Icon(Icons.receipt_long_outlined, color: AppTheme.textSecondary),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                if (_selectedProvider == 'Other / Custom') const SizedBox(height: 16),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: homeSetupProvider.isLoading ? null : _handleSubmit,
                  child: homeSetupProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Continue to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}