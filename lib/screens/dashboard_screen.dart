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
import 'package:fl_chart/fl_chart.dart';
import '../repositories/daily_usage_repository.dart';
import '../models/daily_usage_model.dart';

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

                  // Log today's usage snapshot (fire and forget)
                  DailyUsageRepository().logTodayUsage(uid, totalUnits, totalCost);

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
                        if (roomWise.isEmpty || roomWise.values.every((v) => v == 0))
                          Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('No consumption data yet',
                                style: TextStyle(color: AppTheme.textSecondary)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                      sections: _buildPieSections(roomWise),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: roomWise.entries.toList().asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final roomName = entry.value.key;
                                    final colors = [
                                      AppTheme.primaryBlue,
                                      AppTheme.accentBlue,
                                      Colors.tealAccent,
                                      Colors.orangeAccent,
                                      Colors.purpleAccent,
                                      Colors.pinkAccent,
                                    ];
                                    final color = colors[index % colors.length];

                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(roomName,
                                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Weekly usage trend
                        Text('This Week\'s Usage',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                        const SizedBox(height: 12),
                        FutureBuilder<List<DailyUsageModel>>(
                          future: DailyUsageRepository().getLastNDays(uid, 7),
                          builder: (context, weekSnapshot) {
                            if (!weekSnapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final weekData = weekSnapshot.data!;
                            final weekTotal = weekData.fold<double>(0, (sum, d) => sum + d.units);
                            final maxUnits = weekData.isEmpty
                                ? 1.0
                                : weekData.map((d) => d.units).reduce((a, b) => a > b ? a : b);

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${weekTotal.toStringAsFixed(1)} units this week',
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 150,
                                    child: BarChart(
                                      BarChartData(
                                        maxY: maxUnits <= 0 ? 10 : maxUnits * 1.2,
                                        barTouchData: BarTouchData(enabled: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                final index = value.toInt();
                                                if (index < 0 || index >= weekData.length) {
                                                  return const SizedBox();
                                                }
                                                final dateParts = weekData[index].date.split('-');
                                                if (dateParts.length != 3) return const SizedBox();

                                                final date = DateTime(
                                                  int.parse(dateParts[0]),
                                                  int.parse(dateParts[1]),
                                                  int.parse(dateParts[2]),
                                                );
                                                const dayNames = [
                                                  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                                                ];
                                                final dayLabel = dayNames[date.weekday - 1];

                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 6),
                                                  child: Text(
                                                    dayLabel,
                                                    style: TextStyle(
                                                        color: AppTheme.textSecondary, fontSize: 10),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        gridData: const FlGridData(show: false),
                                        barGroups: List.generate(weekData.length, (index) {
                                          return BarChartGroupData(
                                            x: index,
                                            barRods: [
                                              BarChartRodData(
                                                toY: weekData[index].units,
                                                color: AppTheme.primaryBlue,
                                                width: 18,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ],
                                          );
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

  List<PieChartSectionData> _buildPieSections(Map<String, double> roomWise) {
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.accentBlue,
      Colors.tealAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
    ];
    final total = roomWise.values.fold<double>(0, (sum, v) => sum + v);
    final entries = roomWise.entries.toList();

    return List.generate(entries.length, (index) {
      final value = entries[index].value;
      final percentage = total > 0 ? (value / total * 100) : 0;
      return PieChartSectionData(
        value: value,
        color: colors[index % colors.length],
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
}