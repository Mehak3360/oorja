import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/report_provider.dart';
import '../repositories/home_repository.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../services/pdf_service.dart';

class EnergyReportScreen extends StatefulWidget {
  const EnergyReportScreen({super.key});

  @override
  State<EnergyReportScreen> createState() => _EnergyReportScreenState();
}

class _EnergyReportScreenState extends State<EnergyReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<app_auth.AuthProvider>().currentUser!.uid;
      context.read<ReportProvider>().generateReport(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final uid = context.read<app_auth.AuthProvider>().currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.navyBackground,
      appBar: AppBar(
        title: const Text('Energy Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: reportProvider.currentReport == null
                ? null
                : () async {
                    final uid = context.read<app_auth.AuthProvider>().currentUser!.uid;
                    final home = await HomeRepository().getHome(uid);
                    await PdfService().generateAndShareReport(reportProvider.currentReport!, home);
                  },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                reportProvider.isGenerating ? null : () => reportProvider.generateReport(uid),
          ),
        ],
      ),
      body: reportProvider.isGenerating
          ? const Center(child: CircularProgressIndicator())
          : reportProvider.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: ${reportProvider.errorMessage}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                  ),
                )
              : reportProvider.currentReport == null
                  ? Center(
                      child: Text('No report generated yet',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    )
                  : _buildReportContent(reportProvider),
    );
  }

  Widget _buildReportContent(ReportProvider reportProvider) {
    final report = reportProvider.currentReport!;

    return FutureBuilder(
      future: HomeRepository().getHome(report.homeId),
      builder: (context, homeSnapshot) {
        final home = homeSnapshot.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Energy Report',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Generated on ${report.generatedAt.day}/${report.generatedAt.month}/${report.generatedAt.year}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),

              if (home != null)
                _sectionCard('Home Summary', Icons.home_rounded, [
                  _infoRow('House Type', home.houseType),
                  _infoRow('City', home.city),
                  _infoRow('Family Members', '${home.familyMembers}'),
                  _infoRow('Provider', home.electricityProvider),
                ]),
              const SizedBox(height: 14),

              _sectionCard('Budget Summary', Icons.account_balance_wallet_rounded, [
                _infoRow('Estimated Bill', '₹${report.totalCost.toStringAsFixed(0)}'),
                _infoRow('Monthly Budget',
                    home != null ? '₹${home.monthlyBudget.toStringAsFixed(0)}' : '-'),
                _infoRow('Total Units', '${report.totalUnits.toStringAsFixed(1)} kWh'),
              ]),
              const SizedBox(height: 14),

              GlassCard(
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: report.energyHealthScore / 100,
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            color: report.energyHealthScore >= 60
                                ? AppTheme.success
                                : AppTheme.warning,
                          ),
                          Text(report.energyHealthScore.toStringAsFixed(0),
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Energy Health Score',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        Text(
                          '${report.energyHealthScore.toStringAsFixed(0)} / 100',
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              GlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.eco_rounded, color: AppTheme.success, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Carbon Footprint',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        Text(
                          '${report.carbonFootprintKg.toStringAsFixed(1)} kg CO₂/month',
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _sectionTitle('Room-wise Breakdown'),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: report.roomWiseBreakdown.entries.toList().asMap().entries.map((e) {
                    final color = AppTheme.chartPalette[e.key % AppTheme.chartPalette.length];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(e.value.key,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                          ),
                          Text('${e.value.value.toStringAsFixed(1)} units',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              _sectionTitle('Top 5 Energy Consuming Appliances'),
              const SizedBox(height: 12),
              ...report.top5Appliances.asMap().entries.map((entry) {
                final color = AppTheme.chartPalette[entry.key % AppTheme.chartPalette.length];
                final a = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.electrical_services_rounded, color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(a['name'] ?? '',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        ),
                        Text(
                          '${(a['monthlyUnits'] as num).toStringAsFixed(0)} units',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              _sectionTitle('AI Recommendations'),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: report.recommendations.map((r) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: AppTheme.warning, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(r,
                                style:
                                    const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style:
            const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700));
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
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}