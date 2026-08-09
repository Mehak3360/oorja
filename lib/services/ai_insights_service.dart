import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/home_model.dart';
import '../models/room_model.dart';
import '../models/appliance_model.dart';
import '../utils/appliance_benchmarks.dart';

class AiInsightsService {
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  Future<List<String>> generateRecommendations({
    required HomeModel home,
    required List<RoomModel> rooms,
    required List<ApplianceModel> appliances,
    required double estimatedMonthlyBill,
    required double estimatedMonthlyUnits,
  }) async {
    if (appliances.isEmpty) {
      return ['Add appliances to your rooms to get personalized energy-saving recommendations.'];
    }

    try {
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception('No Groq API key found');
      }

      final prompt = _buildPrompt(
        home: home,
        rooms: rooms,
        appliances: appliances,
        estimatedMonthlyBill: estimatedMonthlyBill,
        estimatedMonthlyUnits: estimatedMonthlyUnits,
      );

      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 400,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        final lines = content
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .map((line) => line.replaceFirst(RegExp(r'^[\d\.\-\•\*]+\s*'), ''))
            .toList();

        if (lines.isNotEmpty) return lines;
      }

      return _fallbackRecommendations(home, appliances, estimatedMonthlyBill);
    } catch (e) {
      return _fallbackRecommendations(home, appliances, estimatedMonthlyBill);
    }
  }

  String _buildPrompt({
    required HomeModel home,
    required List<RoomModel> rooms,
    required List<ApplianceModel> appliances,
    required double estimatedMonthlyBill,
    required double estimatedMonthlyUnits,
  }) {
    final applianceList = appliances
        .map((a) => a.name + ' (' + a.category + ', ' + a.quantity.toString() + 'x, ' + a.wattage.toString() + 'W, ' + a.hoursPerDay.toString() + 'hrs/day)')
        .join(', ');

    final benchmarkData = ApplianceBenchmarks.getRelevantBenchmarks(
      appliances.map((a) => a.name).toList(),
    );

    final buffer = StringBuffer();
    buffer.writeln('You are an energy efficiency advisor for an Indian household.');
    buffer.writeln();
    buffer.writeln('Reference data on efficient appliance alternatives:');
    buffer.writeln(benchmarkData);
    buffer.writeln();
    buffer.writeln('Home details:');
    buffer.writeln('- House type: ' + home.houseType);
    buffer.writeln('- Family members: ' + home.familyMembers.toString());
    buffer.writeln('- City: ' + home.city);
    buffer.writeln('- Monthly budget: Rs. ' + home.monthlyBudget.toString());
    buffer.writeln('- Estimated monthly bill: Rs. ' + estimatedMonthlyBill.toStringAsFixed(0));
    buffer.writeln('- Estimated monthly units: ' + estimatedMonthlyUnits.toStringAsFixed(0) + ' kWh');
    buffer.writeln('- Number of rooms: ' + rooms.length.toString());
    buffer.writeln('- Appliances: ' + applianceList);
    buffer.writeln();
    buffer.writeln('Give exactly 4 short, practical recommendations to help this household save energy and reduce their bill.');
    buffer.writeln('Each recommendation should be one sentence, actionable, and specific to their appliances/usage.');
    buffer.writeln('Do not use markdown formatting, numbering, or bullet points. Just plain sentences, one per line.');

    return buffer.toString();
  }

  List<String> _fallbackRecommendations(
    HomeModel home,
    List<ApplianceModel> appliances,
    double estimatedMonthlyBill,
  ) {
    final List<String> recommendations = [];

    if (home.monthlyBudget > 0) {
      final ratio = estimatedMonthlyBill / home.monthlyBudget;
      if (ratio > 1.0) {
        recommendations.add(
          'Your estimated bill of Rs. ' +
              estimatedMonthlyBill.toStringAsFixed(0) +
              ' exceeds your budget of Rs. ' +
              home.monthlyBudget.toStringAsFixed(0) +
              ' - consider reducing usage on your highest-consuming appliances.',
        );
      } else if (ratio > 0.8) {
        recommendations.add(
          'You are close to your monthly budget. Small changes like reducing AC usage by 1 hour a day could help you stay within limits.',
        );
      } else {
        recommendations.add(
          'Great job! Your estimated usage is well within your Rs. ' +
              home.monthlyBudget.toStringAsFixed(0) +
              ' budget.',
        );
      }
    }

    final sorted = List<ApplianceModel>.from(appliances)
      ..sort((a, b) => b.monthlyUnits.compareTo(a.monthlyUnits));
    final topAppliance = sorted.first;
    recommendations.add(
      topAppliance.name +
          ' is your highest energy consumer at ' +
          topAppliance.monthlyUnits.toStringAsFixed(0) +
          ' units/month. Reducing its daily usage by even 1 hour could meaningfully lower your bill.',
    );

    final coolingAppliances = appliances.where((a) => a.category == 'Cooling').toList();
    if (coolingAppliances.isNotEmpty) {
      recommendations.add(
        'Cooling appliances make up a significant share of your usage. Setting your AC to 24-26 degrees instead of lower temperatures can cut cooling costs by up to 20%.',
      );
    } else {
      recommendations.add(
        'Regularly maintaining your appliances (cleaning filters, checking seals) helps them run efficiently and reduces energy waste.',
      );
    }

    recommendations.add(
      'Unplugging devices on standby mode can save an additional 5-10% on your monthly electricity bill.',
    );

    return recommendations;
  }
}