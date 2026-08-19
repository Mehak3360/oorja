import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../repositories/user_repository.dart';
import '../repositories/home_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../models/user_model.dart';
import '../models/home_model.dart';
import '../utils/demo_data_generator.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<app_auth.AuthProvider>();
    final uid = authProvider.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.navyBackground,
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder(
        future: Future.wait([
          UserRepository().getUser(uid),
          HomeRepository().getHome(uid),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data![0] as UserModel?;
          final home = snapshot.data![1] as HomeModel?;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.accentTeal],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: AppTheme.navyBackground,
                        child: const Icon(Icons.person_rounded, size: 38, color: AppTheme.accentBlue),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            if (user != null) _showEditProfileDialog(context, uid, user);
                          },
                          child: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.accentBlue),
                        ),
                      ],
                    ),
                    Text(user?.email ?? '', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _sectionCard('Home Details', Icons.home_rounded, [
                _infoRow('House Type', home?.houseType ?? '-'),
                _infoRow('Family Members', '${home?.familyMembers ?? '-'}'),
                _infoRow('City', home?.city ?? '-'),
              ]),
              const SizedBox(height: 12),
              _sectionCard('Electricity', Icons.bolt_rounded, [
                _infoRow('Provider', home?.electricityProvider ?? '-'),
                _infoRow('Monthly Budget', '₹${home?.monthlyBudget.toStringAsFixed(0) ?? '-'}'),
                _infoRow('Tariff', '₹${home?.tariffPerUnit.toStringAsFixed(2) ?? '-'} / unit'),
              ]),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  if (home != null) _showEditHomeDialog(context, uid, home);
                },
                icon: const Icon(Icons.edit_outlined, color: AppTheme.accentBlue),
                label: const Text('Edit Home Details', style: TextStyle(color: AppTheme.accentBlue)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: AppTheme.cardBackground,
                      title: const Text('Generate Demo Data', style: TextStyle(color: AppTheme.textPrimary)),
                      content: Text(
                        'This will add 6 rooms and ~20 appliances with realistic usage data to your home. Continue?',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Generate', style: TextStyle(color: AppTheme.accentBlue)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Generating demo data...')));
                    await DemoDataGenerator.generate(uid);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Demo data generated successfully!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.auto_awesome_outlined, color: AppTheme.warning),
                label: const Text('Generate Demo Data', style: TextStyle(color: AppTheme.warning)),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: AppTheme.cardBackground,
                        title: const Text('Log out?', style: TextStyle(color: AppTheme.textPrimary)),
                        content: Text(
                          'You\'ll need to log in again to access your account.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Logout', style: TextStyle(color: AppTheme.danger)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await authProvider.logout();
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
                  label: const Text('Logout', style: TextStyle(color: AppTheme.danger)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.danger, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, List<Widget> rows) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentBlue, size: 16),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, String uid, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Edit Profile', style: TextStyle(color: AppTheme.textPrimary)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Note: Changing your email won\'t change your password. Use your new email with the same password next time you log in.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final newEmail = emailController.text.trim();
                final emailChanged = newEmail != user.email;
                try {
                  if (emailChanged) {
                    await AuthService().updateEmail(newEmail);
                  }
                  await UserRepository().updateUser(uid, {
                    'name': nameController.text.trim(),
                    'email': newEmail,
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppTheme.danger),
                    );
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: AppTheme.accentBlue)),
            ),
          ],
        );
      },
    );
  }

  void _showEditHomeDialog(BuildContext context, String uid, HomeModel home) {
    final houseTypeController = TextEditingController(text: home.houseType);
    final familyMembersController = TextEditingController(text: home.familyMembers.toString());
    final cityController = TextEditingController(text: home.city);
    final providerController = TextEditingController(text: home.electricityProvider);
    final budgetController = TextEditingController(text: home.monthlyBudget.toString());
    final tariffController = TextEditingController(text: home.tariffPerUnit.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Edit Home Details', style: TextStyle(color: AppTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: houseTypeController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'House Type'),
                    validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: familyMembersController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Family Members'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (int.tryParse(value) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cityController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: providerController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Electricity Provider'),
                    validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: budgetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Monthly Budget (₹)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tariffController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Tariff (₹ per unit)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await HomeRepository().updateHome(uid, {
                  'houseType': houseTypeController.text.trim(),
                  'familyMembers': int.parse(familyMembersController.text.trim()),
                  'city': cityController.text.trim(),
                  'electricityProvider': providerController.text.trim(),
                  'monthlyBudget': double.parse(budgetController.text.trim()),
                  'tariffPerUnit': double.parse(tariffController.text.trim()),
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save', style: TextStyle(color: AppTheme.accentBlue)),
            ),
          ],
        );
      },
    );
  }
}