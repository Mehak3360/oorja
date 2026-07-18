class DailyUsageModel {
  final String date; // YYYY-MM-DD
  final double units;
  final double cost;

  DailyUsageModel({
    required this.date,
    required this.units,
    required this.cost,
  });

  factory DailyUsageModel.fromMap(Map<String, dynamic> map) {
    return DailyUsageModel(
      date: map['date'] ?? '',
      units: (map['units'] ?? 0).toDouble(),
      cost: (map['cost'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap(String homeId) {
    return {
      'homeId': homeId,
      'date': date,
      'units': units,
      'cost': cost,
    };
  }
}