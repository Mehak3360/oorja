class ReportModel {
  final String reportId;
  final String homeId;
  final DateTime generatedAt;
  final double totalUnits;
  final double totalCost;
  final double energyHealthScore;
  final double carbonFootprintKg;
  final Map<String, double> roomWiseBreakdown;
  final List<Map<String, dynamic>> top5Appliances;
  final List<String> recommendations;

  ReportModel({
    required this.reportId,
    required this.homeId,
    required this.generatedAt,
    required this.totalUnits,
    required this.totalCost,
    required this.energyHealthScore,
    required this.carbonFootprintKg,
    required this.roomWiseBreakdown,
    required this.top5Appliances,
    required this.recommendations,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String reportId) {
    return ReportModel(
      reportId: reportId,
      homeId: map['homeId'] ?? '',
      generatedAt: (map['generatedAt'] is DateTime) ? map['generatedAt'] : DateTime.now(),
      totalUnits: (map['totalUnits'] ?? 0).toDouble(),
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      energyHealthScore: (map['energyHealthScore'] ?? 0).toDouble(),
      carbonFootprintKg: (map['carbonFootprintKg'] ?? 0).toDouble(),
      roomWiseBreakdown: Map<String, double>.from(map['roomWiseBreakdown'] ?? {}),
      top5Appliances: List<Map<String, dynamic>>.from(map['top5Appliances'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'homeId': homeId,
      'generatedAt': generatedAt,
      'totalUnits': totalUnits,
      'totalCost': totalCost,
      'energyHealthScore': energyHealthScore,
      'carbonFootprintKg': carbonFootprintKg,
      'roomWiseBreakdown': roomWiseBreakdown,
      'top5Appliances': top5Appliances,
      'recommendations': recommendations,
    };
  }
}