import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../repositories/home_repository.dart';
import '../repositories/room_repository.dart';
import '../repositories/appliance_repository.dart';
import '../utils/calculation_engine.dart';

class InsightsProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();

  List<String> recommendations = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchRecommendations(String uid) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final home = await HomeRepository().getHome(uid);
      if (home == null) {
        errorMessage = 'Home data not found';
        isLoading = false;
        notifyListeners();
        return;
      }

      // Get rooms (one-time fetch using first value from stream)
     final rooms = await RoomRepository().watchRooms(uid).first;
      print('DEBUG: Rooms found = ${rooms.length}, uid = $uid');
      final roomIds = rooms.map((r) => r.roomId).toList();
      print('DEBUG: Room IDs = $roomIds');
      final appliances =
          await ApplianceRepository().watchAllAppliancesForHome(roomIds).first;
      print('DEBUG: Appliances found = ${appliances.length}');

      final totalUnits = CalculationEngine.totalMonthlyUnits(appliances);
      final totalCost = CalculationEngine.totalMonthlyCost(appliances, home.tariffPerUnit);

      final result = await _geminiService.generateRecommendations(
        home: home,
        rooms: rooms,
        appliances: appliances,
        estimatedMonthlyBill: totalCost,
        estimatedMonthlyUnits: totalUnits,
      );

      recommendations = result;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(String uid) async {
    await fetchRecommendations(uid);
  }
}