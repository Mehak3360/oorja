import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/report_provider.dart';
import '../repositories/home_repository.dart';
import '../theme/app_theme.dart';
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
            onPressed: reportProvider.isGenerating
                ? null
                : () => reportProvider.generateReport(uid),
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
                      style: const TextStyle(color: Colors.redAccent),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Monthly Energy Report',
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'Generated on ${report.generatedAt.day}/${report.generatedAt.month}/${report.generatedAt.year}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Home Summary
              if (home != null)
                _sectionCard('Home Summary', [
                  _infoRow('House Type', home.houseType),
                  _infoRow('City', home.city),
                  _infoRow('Family Members', '${home.familyMembers}'),
                  _infoRow('Provider', home.electricityProvider),
                ]),
              const SizedBox(height: 16),

              // Budget Summary
              _sectionCard('Budget Summary', [
                _infoRow('Estimated Bill', '₹${report.totalCost.toStringAsFixed(0)}'),
                _infoRow('Monthly Budget', home != null ? '₹${home.monthlyBudget.toStringAsFixed(0)}' : '-'),
                _infoRow('Total Units', '${report.totalUnits.toStringAsFixed(1)} kWh'),
              ]),
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
                      value: report.energyHealthScore / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      color: report.energyHealthScore >= 60
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
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
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Carbon Footprint
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco_outlined, color: Colors.greenAccent, size: 32),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Carbon Footprint',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        Text(
                          '${report.carbonFootprintKg.toStringAsFixed(1)} kg CO₂/month',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Room-wise breakdown
              Text('Room-wise Breakdown',
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: report.roomWiseBreakdown.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                          Text('${entry.value.toStringAsFixed(1)} units',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Top 5 appliances
              Text('Top 5 Energy Consuming Appliances',
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...report.top5Appliances.map((a) {
                return Card(
                  color: AppTheme.cardBackground,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.electrical_services, color: AppTheme.primaryBlue),
                    title: Text(a['name'] ?? '', style: const TextStyle(color: AppTheme.textPrimary)),
                    trailing: Text(
                      '${(a['monthlyUnits'] as num).toStringAsFixed(0)} units',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // AI Recommendations summary
              Text('AI Recommendations',
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: report.recommendations.map((r) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              color: AppTheme.primaryBlue, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(r,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionCard(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
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
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}