class HomeModel {
  final String homeId;
  final String houseType;
  final int familyMembers;
  final String city;
  final String electricityProvider;
  final double monthlyBudget;
  final double tariffPerUnit;
  final bool setupComplete;

  HomeModel({
    required this.homeId,
    required this.houseType,
    required this.familyMembers,
    required this.city,
    required this.electricityProvider,
    required this.monthlyBudget,
    required this.tariffPerUnit,
    this.setupComplete = false,
  });

  factory HomeModel.fromMap(Map<String, dynamic> map, String homeId) {
    return HomeModel(
      homeId: homeId,
      houseType: map['houseType'] ?? '',
      familyMembers: map['familyMembers'] ?? 1,
      city: map['city'] ?? '',
      electricityProvider: map['electricityProvider'] ?? '',
      monthlyBudget: (map['monthlyBudget'] ?? 0).toDouble(),
      tariffPerUnit: (map['tariffPerUnit'] ?? 0).toDouble(),
      setupComplete: map['setupComplete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'houseType': houseType,
      'familyMembers': familyMembers,
      'city': city,
      'electricityProvider': electricityProvider,
      'monthlyBudget': monthlyBudget,
      'tariffPerUnit': tariffPerUnit,
      'setupComplete': setupComplete,
    };
  }
}