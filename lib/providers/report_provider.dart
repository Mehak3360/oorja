import 'package:flutter/material.dart';
import '../repositories/report_repository.dart';
import '../repositories/home_repository.dart';
import '../repositories/room_repository.dart';
import '../repositories/appliance_repository.dart';
import '../utils/calculation_engine.dart';
import '../models/report_model.dart';
import '../services/gemini_service.dart';

class ReportProvider extends ChangeNotifier {
  ReportModel? currentReport;
  bool isGenerating = false;
  String? errorMessage;

  Future<void> generateReport(String uid) async {
    isGenerating = true;
    errorMessage = null;
    notifyListeners();

    try {
      final home = await HomeRepository().getHome(uid);
      if (home == null) throw Exception('Home data not found');

      final rooms = await RoomRepository().watchRooms(uid).first;
      final roomIds = rooms.map((r) => r.roomId).toList();
      final appliances =
          await ApplianceRepository().watchAllAppliancesForHome(roomIds).first;

      final totalUnits = CalculationEngine.totalMonthlyUnits(appliances);
      final totalCost = CalculationEngine.totalMonthlyCost(appliances, home.tariffPerUnit);
      final healthScore = CalculationEngine.energyHealthScore(
        applianceCount: appliances.length,
        estimatedBill: totalCost,
        budget: home.monthlyBudget,
      );
      final carbonFootprint = CalculationEngine.carbonFootprintKg(totalUnits);
      final roomWise = CalculationEngine.roomWiseConsumption(rooms, appliances);
      final top5 = CalculationEngine.topConsumers(appliances, 5);

      final recommendations = await GeminiService().generateRecommendations(
        home: home,
        rooms: rooms,
        appliances: appliances,
        estimatedMonthlyBill: totalCost,
        estimatedMonthlyUnits: totalUnits,
      );

      final report = ReportModel(
        reportId: '',
        homeId: uid,
        generatedAt: DateTime.now(),
        totalUnits: totalUnits,
        totalCost: totalCost,
        energyHealthScore: healthScore,
        carbonFootprintKg: carbonFootprint,
        roomWiseBreakdown: roomWise,
        top5Appliances: top5
            .map((a) => {
                  'name': a.name,
                  'monthlyUnits': a.monthlyUnits,
                  'monthlyCost': a.monthlyCost(home.tariffPerUnit),
                })
            .toList(),
        recommendations: recommendations,
      );

      await ReportRepository().saveReport(report);
      currentReport = report;
      isGenerating = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isGenerating = false;
      notifyListeners();
    }
  }
}