class RoomModel {
  final String roomId;
  final String homeId;
  final String name;
  final String type;

  RoomModel({
    required this.roomId,
    required this.homeId,
    required this.name,
    required this.type,
  });

  factory RoomModel.fromMap(Map<String, dynamic> map, String roomId) {
    return RoomModel(
      roomId: roomId,
      homeId: map['homeId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'homeId': homeId,
      'name': name,
      'type': type,
    };
  }
}
