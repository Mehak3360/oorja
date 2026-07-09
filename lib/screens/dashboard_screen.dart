import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../repositories/home_repository.dart';
import '../repositories/room_repository.dart';
import '../repositories/appliance_repository.dart';
import '../models/home_model.dart';
import '../models/room_model.dart';
import '../models/appliance_model.dart';
import '../utils/calculation_engine.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<app_auth.AuthProvider>().currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.navyBackground,
      appBar: AppBar(title: const Text('Dashboard')),
      body: FutureBuilder<HomeModel?>(
        future: HomeRepository().getHome(uid),
        builder: (context, homeSnapshot) {
          if (!homeSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final home = homeSnapshot.data!;

          return StreamBuilder<List<RoomModel>>(
            stream: RoomRepository().watchRooms(uid),
            builder: (context, roomSnapshot) {
              final rooms = roomSnapshot.data ?? [];
              final roomIds = rooms.map((r) => r.roomId).toList();

              return StreamBuilder<List<ApplianceModel>>(
                stream: ApplianceRepository().watchAllAppliancesForHome(roomIds),
                builder: (context, applianceSnapshot) {
                  final appliances = applianceSnapshot.data ?? [];

                  final totalUnits = CalculationEngine.totalMonthlyUnits(appliances);
                  final totalCost = CalculationEngine.totalMonthlyCost(appliances, home.tariffPerUnit);
                  final budgetProgress = home.monthlyBudget > 0
                      ? (totalCost / home.monthlyBudget).clamp(0.0, 1.5)
                      : 0.0;
                  final healthScore = CalculationEngine.energyHealthScore(
                    applianceCount: appliances.length,
                    estimatedBill: totalCost,
                    budget: home.monthlyBudget,
                  );
                  final topAppliances = CalculationEngine.topConsumers(appliances, 5);
                  final roomWise = CalculationEngine.roomWiseConsumption(rooms, appliances);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting
                        Text(
                          'Hello 👋',
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                        const Text(
                          'Your Energy Overview',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Bill + Units cards
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                'Estimated Bill',
                                '₹${totalCost.toStringAsFixed(0)}',
                                Icons.account_balance_wallet_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                'Monthly Units',
                                '${totalUnits.toStringAsFixed(0)} kWh',
                                Icons.bolt_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Budget progress
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Budget Progress',
                                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                  Text(
                                    '₹${totalCost.toStringAsFixed(0)} / ₹${home.monthlyBudget.toStringAsFixed(0)}',
                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: budgetProgress > 1 ? 1 : budgetProgress,
                                  minHeight: 10,
                                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                                  color: budgetProgress > 1 ? Colors.redAccent : AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Energy Health Score
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircularProgressIndicator(
                                value: healthScore / 100,
                                strokeWidth: 6,
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                color: healthScore >= 60 ? Colors.greenAccent : Colors.orangeAccent,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Energy Health Score',
                                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                  Text(
                                    '${healthScore.toStringAsFixed(0)} / 100',
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Room-wise consumption
                        Text('Room-wise Consumption',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                        const SizedBox(height: 12),
                        if (roomWise.isEmpty)
                          Text('No rooms yet', style: TextStyle(color: AppTheme.textSecondary))
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: roomWise.entries.map((entry) {
                                final maxUnits = roomWise.values.isEmpty
                                    ? 1.0
                                    : roomWise.values.reduce((a, b) => a > b ? a : b);
                                final barWidth = maxUnits > 0 ? entry.value / maxUnits : 0.0;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(entry.key,
                                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                                          Text('${entry.value.toStringAsFixed(0)} units',
                                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: barWidth,
                                          minHeight: 8,
                                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                                          color: AppTheme.accentBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Top appliances
                        Text('Top Energy Consuming Appliances',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                        const SizedBox(height: 12),
                        if (topAppliances.isEmpty)
                          Text('No appliances yet', style: TextStyle(color: AppTheme.textSecondary))
                        else
                          ...topAppliances.map((appliance) {
                            return Card(
                              color: AppTheme.cardBackground,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.electrical_services, color: AppTheme.primaryBlue),
                                title: Text(appliance.name,
                                    style: const TextStyle(color: AppTheme.textPrimary)),
                                trailing: Text(
                                  '${appliance.monthlyUnits.toStringAsFixed(0)} units',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 22),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}