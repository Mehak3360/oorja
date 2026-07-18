import '../models/appliance_model.dart';
import '../models/room_model.dart';

class CalculationEngine {
  static double totalMonthlyUnits(List<ApplianceModel> appliances) {
    return appliances.fold(0, (sum, a) => sum + a.monthlyUnits);
  }

  static double totalMonthlyCost(List<ApplianceModel> appliances, double tariff) {
    return totalMonthlyUnits(appliances) * tariff;
  }

  static List<ApplianceModel> topConsumers(List<ApplianceModel> appliances, int n) {
    final sorted = List<ApplianceModel>.from(appliances)
      ..sort((a, b) => b.monthlyUnits.compareTo(a.monthlyUnits));
    return sorted.take(n).toList();
  }

  static Map<String, double> roomWiseConsumption(
    List<RoomModel> rooms,
    List<ApplianceModel> allAppliances,
  ) {
    final Map<String, double> result = {};
    for (final room in rooms) {
      final roomAppliances =
          allAppliances.where((a) => a.roomId == room.roomId).toList();
      result[room.name] = totalMonthlyUnits(roomAppliances);
    }
    return result;
  }

  static double energyHealthScore({
    required int applianceCount,
    required double estimatedBill,
    required double budget,
  }) {
    if (budget <= 0) return 50;
    double budgetRatio = estimatedBill / budget;
    double score = 100 - (budgetRatio * 40) - (applianceCount * 0.5);
    return score.clamp(0, 100);
  }

  static double carbonFootprintKg(double monthlyUnits) {
    // Approx India grid emission factor: 0.82 kg CO2 per kWh
    return monthlyUnits * 0.82;
  }
}