class ApplianceBenchmarks {
  // Typical vs efficient wattage benchmarks for common Indian household appliances
  static const Map<String, Map<String, dynamic>> benchmarks = {
    'AC': {'typical_watt': 1500, 'efficient_watt': 1200, 'tip': '5-star rated inverter ACs use up to 30% less power'},
    'Fan': {'typical_watt': 75, 'efficient_watt': 35, 'tip': 'BLDC fans use up to 50% less power than regular fans'},
    'Refrigerator': {'typical_watt': 200, 'efficient_watt': 150, 'tip': '5-star rated fridges save significant standby power'},
    'Washing Machine': {'typical_watt': 800, 'efficient_watt': 500, 'tip': 'Front-load machines are typically more efficient'},
    'Geyser': {'typical_watt': 2000, 'efficient_watt': 1500, 'tip': 'Instant geysers use less power than storage geysers'},
    'TV': {'typical_watt': 150, 'efficient_watt': 60, 'tip': 'LED TVs use significantly less power than older LCDs'},
    'Microwave': {'typical_watt': 1200, 'efficient_watt': 1000, 'tip': 'Use for shorter durations at higher power settings'},
    'LED Bulb': {'typical_watt': 9, 'efficient_watt': 5, 'tip': 'Smart LED bulbs can be dimmed to save more power'},
    'Iron': {'typical_watt': 1000, 'efficient_watt': 800, 'tip': 'Iron in bulk to reduce heating cycles'},
    'Laptop': {'typical_watt': 65, 'efficient_watt': 45, 'tip': 'Enable power-saving mode when on battery'},
  };

  // Returns a formatted string summary for appliances matching what the user has,
  // to be injected into the AI prompt as reference context
  static String getRelevantBenchmarks(List<String> applianceNames) {
    final matched = <String>[];
    for (final name in applianceNames) {
      for (final key in benchmarks.keys) {
        if (name.toLowerCase().contains(key.toLowerCase())) {
          final b = benchmarks[key]!;
          matched.add(
            '$key: typical ${b['typical_watt']}W vs efficient ${b['efficient_watt']}W. Tip: ${b['tip']}',
          );
          break;
        }
      }
    }
    return matched.isEmpty ? 'No specific benchmark data available.' : matched.join('\n');
  }
}