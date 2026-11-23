import 'dart:async';
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
import '../services/live_reading_service.dart';
import 'energy_report_screen.dart';

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
                  final budgetRatio =
                      home.monthlyBudget > 0 ? (totalCost / home.monthlyBudget) : 0.0;
                  final budgetProgress = budgetRatio.clamp(0.0, 1.0);
                  final budgetColor = AppTheme.statusColorForRatio(budgetRatio);
                  final healthScore = CalculationEngine.energyHealthScore(
                    applianceCount: appliances.length,
                    estimatedBill: totalCost,
                    budget: home.monthlyBudget,
                  );
                  final healthColor = healthScore >= 80
                      ? AppTheme.success
                      : healthScore >= 50
                          ? AppTheme.warning
                          : AppTheme.danger;
                  final topAppliances = CalculationEngine.topConsumers(appliances, 5);
                  final roomWise = CalculationEngine.roomWiseConsumption(rooms, appliances);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello 👋',
                            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                        const SizedBox(height: 2),
                        Text('Your Energy Overview', style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 20),

                        _heroBillCard(totalCost, totalUnits),
                        const SizedBox(height: 14),

                        _budgetCard(totalCost, home.monthlyBudget, budgetProgress, budgetColor),
                        const SizedBox(height: 14),

                        _healthScoreCard(healthScore, healthColor),
                        const SizedBox(height: 24),

                        _sectionTitle('Live Power'),
                        const SizedBox(height: 12),
                        _LiveReadingsCard(appliances: appliances),
                        const SizedBox(height: 24),

                        _sectionTitle('Room-wise Consumption'),
                        const SizedBox(height: 12),
                        (roomWise.isEmpty || roomWise.values.every((v) => v == 0))
                            ? _emptyState(Icons.donut_large_outlined, 'No consumption data yet',
                                'Add appliances to your rooms to see a breakdown here.')
                            : _roomWiseCard(roomWise),
                        const SizedBox(height: 24),

                        _sectionTitle("This Week's Usage"),
                        const SizedBox(height: 12),
                        FutureBuilder<List<DailyUsageModel>>(
                          // Log today first, THEN read the week, so the chart
                          // never shows a stale value for today.
                          // totalUnits / totalCost are MONTHLY figures; the daily
                          // log stores one day, so divide by 30.
                          future: DailyUsageRepository()
                              .logTodayUsage(uid, totalUnits / 30, totalCost / 30)
                              .then((_) => DailyUsageRepository().getLastNDays(uid, 7)),
                          builder: (context, weekSnapshot) {
                            if (!weekSnapshot.hasData) {
                              return const SizedBox(
                                height: 150,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return _weeklyUsageCard(weekSnapshot.data!);
                          },
                        ),
                        const SizedBox(height: 24),

                        _sectionTitle('Top Energy Consuming Appliances'),
                        const SizedBox(height: 12),
                        if (topAppliances.isEmpty)
                          _emptyState(Icons.electrical_services_outlined, 'No appliances yet',
                              'Add appliances to a room to start tracking usage.')
                        else
                          ...topAppliances.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _applianceRow(entry.value, entry.key),
                            );
                          }),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EnergyReportScreen()),
                              );
                            },
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('Generate Energy Report'),
                          ),
                        ),
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

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
    );
  }

  Widget _heroBillCard(double totalCost, double totalUnits) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: AppTheme.accentBlue, size: 20),
              ),
              const Spacer(),
              Icon(Icons.bolt_rounded, color: AppTheme.textSecondary.withValues(alpha: 0.6), size: 18),
              const SizedBox(width: 4),
              Text('${totalUnits.toStringAsFixed(0)} kWh',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Estimated Bill', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            '₹${totalCost.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetCard(double totalCost, double budget, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget Progress', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Text(
                '₹${totalCost.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthScoreCard(double healthScore, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: healthScore / 100,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: color,
                ),
                Text(healthScore.toStringAsFixed(0),
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Energy Health Score',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                '${healthScore.toStringAsFixed(0)} / 100',
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roomWiseCard(Map<String, double> roomWise) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 44,
                sections: _buildPieSections(roomWise),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: roomWise.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final roomName = entry.value.key;
              final color = AppTheme.chartPalette[index % AppTheme.chartPalette.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(roomName, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _weeklyUsageCard(List<DailyUsageModel> weekData) {
    final weekTotal = weekData.fold<double>(0, (sum, d) => sum + d.units);
    final maxUnits =
        weekData.isEmpty ? 1.0 : weekData.map((d) => d.units).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${weekTotal.toStringAsFixed(1)} units this week',
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxUnits <= 0 ? 10 : maxUnits * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= weekData.length) return const SizedBox();
                        final dateParts = weekData[index].date.split('-');
                        if (dateParts.length != 3) return const SizedBox();
                        final date = DateTime(
                          int.parse(dateParts[0]),
                          int.parse(dateParts[1]),
                          int.parse(dateParts[2]),
                        );
                        const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final dayLabel = dayNames[date.weekday - 1];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(dayLabel,
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
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
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [AppTheme.primaryBlue, AppTheme.accentTeal],
                        ),
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
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
  }

  Widget _applianceRow(ApplianceModel appliance, int index) {
    final color = AppTheme.chartPalette[index % AppTheme.chartPalette.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.electrical_services_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(appliance.name,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          ),
          Text(
            '${appliance.monthlyUnits.toStringAsFixed(0)} units',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 32),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> roomWise) {
    final total = roomWise.values.fold<double>(0, (sum, v) => sum + v);
    final entries = roomWise.entries.toList();

    return List.generate(entries.length, (index) {
      final value = entries[index].value;
      final percentage = total > 0 ? (value / total * 100) : 0;
      return PieChartSectionData(
        value: value,
        color: AppTheme.chartPalette[index % AppTheme.chartPalette.length],
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 56,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }
}

/// Live readings from the ESP32 (Realtime Database `/current`).
/// StatefulWidget so the stream is created once and a timer can
/// re-check "offline" status even when no new data arrives.
class _LiveReadingsCard extends StatefulWidget {
  final List<ApplianceModel> appliances;
  const _LiveReadingsCard({required this.appliances});

  @override
  State<_LiveReadingsCard> createState() => _LiveReadingsCardState();
}

class _LiveReadingsCardState extends State<_LiveReadingsCard> {
  late final Stream<Map<String, LiveReading>> _stream;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _stream = LiveReadingService.instance.watch();
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String? _linkedApplianceName(String channel) {
    for (final a in widget.appliances) {
      if (a.isMetered && a.deviceId == channel) return a.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, LiveReading>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _message(
            Icons.sensors_off_rounded,
            'Could not connect to live sensor',
            'Check internet and Realtime Database rules.',
          );
        }
        final readings = snapshot.data;
        if (readings == null) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (readings.isEmpty) {
          return _message(
            Icons.sensors_off_rounded,
            'No sensor data yet',
            'Waiting for the ESP32 to send readings.',
          );
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: AppTheme.cardDecoration(),
          child: Column(
            children: [
              for (int i = 0; i < LiveReadingService.channels.length; i++) ...[
                if (i > 0)
                  Divider(height: 22, color: Colors.white.withValues(alpha: 0.06)),
                _channelRow(LiveReadingService.channels[i], readings[LiveReadingService.channels[i]]),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Power estimated at 230 V (current-only sensor)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _channelRow(String channel, LiveReading? reading) {
    final linkedName = _linkedApplianceName(channel);
    final title = linkedName ?? '$channel (not linked)';

    String status;
    Color statusColor;
    if (reading == null) {
      status = 'No data';
      statusColor = AppTheme.textMuted;
    } else if (reading.isStale) {
      status = 'Offline';
      statusColor = AppTheme.danger;
    } else if (reading.amps > 0) {
      status = 'Live';
      statusColor = AppTheme.success;
    } else {
      status = 'Idle';
      statusColor = AppTheme.textMuted;
    }

    final showValues = reading != null && !reading.isStale;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.bolt_rounded, color: statusColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(status, style: TextStyle(color: statusColor, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              showValues ? '${reading.watts.toStringAsFixed(0)} W' : '--',
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              showValues ? '${reading.amps.toStringAsFixed(2)} A' : '--',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _message(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 30),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}