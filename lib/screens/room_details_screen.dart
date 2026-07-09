import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appliance_provider.dart';
import '../models/appliance_model.dart';
import '../models/room_model.dart';
import '../theme/app_theme.dart';

class RoomDetailsScreen extends StatefulWidget {
  final RoomModel room;

  const RoomDetailsScreen({super.key, required this.room});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  final List<String> _categories = [
    'Cooling', 'Lighting', 'Kitchen', 'Entertainment', 'Laundry', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplianceProvider>().listenToAppliances(widget.room.roomId);
    });
  }

  void _showAddApplianceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final wattageController = TextEditingController();
    final hoursController = TextEditingController();
    final daysController = TextEditingController(text: '7');
    String selectedCategory = 'Other';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              title: const Text('Add Appliance', style: TextStyle(color: AppTheme.textPrimary)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Appliance Name'),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        dropdownColor: AppTheme.cardBackground,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedCategory = value!);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (int.tryParse(value) == null) return 'Enter a whole number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: wattageController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Wattage (W)'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: hoursController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Hours Used Per Day'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Enter a valid number (e.g. 6 or 6.5)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: daysController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Days Used Per Week'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (int.tryParse(value) == null) return 'Enter a whole number';
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

                    final appliance = ApplianceModel(
                      applianceId: '',
                      roomId: widget.room.roomId,
                      name: nameController.text.trim(),
                      category: selectedCategory,
                      quantity: int.parse(quantityController.text.trim()),
                      wattage: double.parse(wattageController.text.trim()),
                      hoursPerDay: double.parse(hoursController.text.trim()),
                      daysPerWeek: int.parse(daysController.text.trim()),
                    );

                    await context.read<ApplianceProvider>().addAppliance(appliance);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text('Add', style: TextStyle(color: AppTheme.accentBlue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final applianceProvider = context.watch<ApplianceProvider>();

    return Scaffold(
      backgroundColor: AppTheme.navyBackground,
      appBar: AppBar(title: Text(widget.room.name)),
      body: applianceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : applianceProvider.appliances.isEmpty
              ? Center(
                  child: Text(
                    'No appliances yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: applianceProvider.appliances.length,
                  itemBuilder: (context, index) {
                    final appliance = applianceProvider.appliances[index];
                    return Card(
                      color: AppTheme.cardBackground,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.electrical_services, color: AppTheme.primaryBlue),
                        title: Text(
                          appliance.name,
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${appliance.category} • Qty: ${appliance.quantity} • '
                          '${appliance.monthlyUnits.toStringAsFixed(1)} units/month',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () async {
                            await context
                                .read<ApplianceProvider>()
                                .deleteAppliance(appliance.applianceId);
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddApplianceDialog(context),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }
}