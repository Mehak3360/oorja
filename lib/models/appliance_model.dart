class ApplianceModel {
  final String applianceId;
  final String roomId;
  final String name;
  final String category;
  final int quantity;
  final double wattage;
  final double hoursPerDay;
  final int daysPerWeek;

  ApplianceModel({
    required this.applianceId,
    required this.roomId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.wattage,
    required this.hoursPerDay,
    required this.daysPerWeek,
  });

  factory ApplianceModel.fromMap(Map<String, dynamic> map, String applianceId) {
    return ApplianceModel(
      applianceId: applianceId,
      roomId: map['roomId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? 1,
      wattage: (map['wattage'] ?? 0).toDouble(),
      hoursPerDay: (map['hoursPerDay'] ?? 0).toDouble(),
      daysPerWeek: map['daysPerWeek'] ?? 7,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'wattage': wattage,
      'hoursPerDay': hoursPerDay,
      'daysPerWeek': daysPerWeek,
    };
  }

  // Derived calculation values
  double get dailyUnits => (wattage * quantity * hoursPerDay) / 1000;
  double get monthlyUnits => dailyUnits * (daysPerWeek / 7) * 30;
  double monthlyCost(double tariff) => monthlyUnits * tariff;
}