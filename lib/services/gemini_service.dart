import '../models/home_model.dart';
import '../models/room_model.dart';
import '../models/appliance_model.dart';

class GeminiService {
  // DEMO MODE: Generates realistic, data-driven recommendations
  // without calling a live API. This avoids billing dependency
  // while still producing genuinely personalized suggestions
  // based on the user's actual appliance and usage data.

  Future<List<String>> generateRecommendations({
    required HomeModel home,
    required List<RoomModel> rooms,
    required List<ApplianceModel> appliances,
    required double estimatedMonthlyBill,
    required double estimatedMonthlyUnits,
  }) async {
    // Simulate network delay for realistic UX
    await Future.delayed(const Duration(milliseconds: 800));

    final List<String> recommendations = [];

    if (appliances.isEmpty) {
      return ['Add appliances to your rooms to get personalized energy-saving recommendations.'];
    }

    // 1. Budget-based recommendation
    if (home.monthlyBudget > 0) {
      final ratio = estimatedMonthlyBill / home.monthlyBudget;
      if (ratio > 1.0) {
        recommendations.add(
          'Your estimated bill of ₹${estimatedMonthlyBill.toStringAsFixed(0)} exceeds your budget of ₹${home.monthlyBudget.toStringAsFixed(0)} — consider reducing usage on your highest-consuming appliances.',
        );
      } else if (ratio > 0.8) {
        recommendations.add(
          'You are close to your monthly budget. Small changes like reducing AC usage by 1 hour a day could help you stay within limits.',
        );
      } else {
        recommendations.add(
          'Great job! Your estimated usage is well within your ₹${home.monthlyBudget.toStringAsFixed(0)} budget.',
        );
      }
    }

    // 2. Top consumer-based recommendation
    final sorted = List<ApplianceModel>.from(appliances)
      ..sort((a, b) => b.monthlyUnits.compareTo(a.monthlyUnits));
    final topAppliance = sorted.first;
    recommendations.add(
      '${topAppliance.name} is your highest energy consumer at ${topAppliance.monthlyUnits.toStringAsFixed(0)} units/month. Reducing its daily usage by even 1 hour could meaningfully lower your bill.',
    );

    // 3. Category-based tip
    final coolingAppliances = appliances.where((a) => a.category == 'Cooling').toList();
    if (coolingAppliances.isNotEmpty) {
      recommendations.add(
        'Cooling appliances make up a significant share of your usage. Setting your AC to 24-26°C instead of lower temperatures can cut cooling costs by up to 20%.',
      );
    } else {
      final lightingAppliances = appliances.where((a) => a.category == 'Lighting').toList();
      if (lightingAppliances.isNotEmpty) {
        recommendations.add(
          'Switching to LED bulbs for all lighting appliances can reduce lighting-related energy consumption by up to 75%.',
        );
      } else {
        recommendations.add(
          'Regularly maintaining your appliances (cleaning filters, checking seals) helps them run efficiently and reduces energy waste.',
        );
      }
    }

    // 4. General sustainability tip
    recommendations.add(
      'Unplugging devices on standby mode can save an additional 5-10% on your monthly electricity bill.',
    );

    return recommendations;
  }
}