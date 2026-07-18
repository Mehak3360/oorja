import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/insights_provider.dart';
import '../theme/app_theme.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<app_auth.AuthProvider>().currentUser!.uid;
      context.read<InsightsProvider>().fetchRecommendations(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final insightsProvider = context.watch<InsightsProvider>();
    final uid = context.read<app_auth.AuthProvider>().currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.navyBackground,
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: insightsProvider.isLoading
                ? null
                : () => insightsProvider.refresh(uid),
          ),
        ],
      ),
      body: insightsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : insightsProvider.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: ${insightsProvider.errorMessage}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                )
              : insightsProvider.recommendations.isEmpty
                  ? Center(
                      child: Text(
                        'No insights yet.\nAdd some appliances first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: insightsProvider.recommendations.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: AppTheme.cardBackground,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lightbulb_outline,
                                    color: AppTheme.primaryBlue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    insightsProvider.recommendations[index],
                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}