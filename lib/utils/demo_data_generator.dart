import '../models/room_model.dart';
import '../models/appliance_model.dart';
import '../repositories/room_repository.dart';
import '../repositories/appliance_repository.dart';

class DemoDataGenerator {
  static Future<void> generate(String homeId) async {
    final roomRepo = RoomRepository();
    final applianceRepo = ApplianceRepository();

    // Define 6 rooms with realistic appliances
    final roomsData = [
      {
        'name': 'Bedroom',
        'type': 'Bedroom',
        'appliances': [
          {'name': 'AC', 'category': 'Cooling', 'qty': 1, 'watt': 1500.0, 'hours': 6.0, 'days': 7},
          {'name': 'Ceiling Fan', 'category': 'Cooling', 'qty': 1, 'watt': 75.0, 'hours': 10.0, 'days': 7},
          {'name': 'LED Bulb', 'category': 'Lighting', 'qty': 2, 'watt': 9.0, 'hours': 6.0, 'days': 7},
          {'name': 'TV', 'category': 'Entertainment', 'qty': 1, 'watt': 100.0, 'hours': 3.0, 'days': 7},
        ],
      },
      {
        'name': 'Kitchen',
        'type': 'Kitchen',
        'appliances': [
          {'name': 'Refrigerator', 'category': 'Kitchen', 'qty': 1, 'watt': 200.0, 'hours': 24.0, 'days': 7},
          {'name': 'Microwave', 'category': 'Kitchen', 'qty': 1, 'watt': 1200.0, 'hours': 0.5, 'days': 7},
          {'name': 'Mixer Grinder', 'category': 'Kitchen', 'qty': 1, 'watt': 500.0, 'hours': 0.3, 'days': 5},
          {'name': 'Tube Light', 'category': 'Lighting', 'qty': 1, 'watt': 20.0, 'hours': 4.0, 'days': 7},
        ],
      },
      {
        'name': 'Living Room',
        'type': 'Living Room',
        'appliances': [
          {'name': 'AC', 'category': 'Cooling', 'qty': 1, 'watt': 1500.0, 'hours': 4.0, 'days': 7},
          {'name': 'TV', 'category': 'Entertainment', 'qty': 1, 'watt': 150.0, 'hours': 4.0, 'days': 7},
          {'name': 'Ceiling Fan', 'category': 'Cooling', 'qty': 2, 'watt': 75.0, 'hours': 8.0, 'days': 7},
          {'name': 'LED Bulb', 'category': 'Lighting', 'qty': 3, 'watt': 9.0, 'hours': 5.0, 'days': 7},
        ],
      },
      {
        'name': 'Bathroom',
        'type': 'Bathroom',
        'appliances': [
          {'name': 'Geyser', 'category': 'Other', 'qty': 1, 'watt': 2000.0, 'hours': 0.5, 'days': 7},
          {'name': 'Exhaust Fan', 'category': 'Cooling', 'qty': 1, 'watt': 30.0, 'hours': 1.0, 'days': 7},
        ],
      },
      {
        'name': 'Study Room',
        'type': 'Study Room',
        'appliances': [
          {'name': 'Laptop', 'category': 'Entertainment', 'qty': 1, 'watt': 65.0, 'hours': 5.0, 'days': 7},
          {'name': 'Desktop', 'category': 'Entertainment', 'qty': 1, 'watt': 200.0, 'hours': 3.0, 'days': 5},
          {'name': 'LED Bulb', 'category': 'Lighting', 'qty': 1, 'watt': 9.0, 'hours': 4.0, 'days': 7},
          {'name': 'Fan', 'category': 'Cooling', 'qty': 1, 'watt': 75.0, 'hours': 6.0, 'days': 7},
        ],
      },
      {
        'name': 'Utility Room',
        'type': 'Utility Room',
        'appliances': [
          {'name': 'Washing Machine', 'category': 'Laundry', 'qty': 1, 'watt': 800.0, 'hours': 1.0, 'days': 3},
          {'name': 'Iron', 'category': 'Laundry', 'qty': 1, 'watt': 1000.0, 'hours': 0.5, 'days': 3},
        ],
      },
    ];

    for (final roomData in roomsData) {
      final room = RoomModel(
        roomId: '',
        homeId: homeId,
        name: roomData['name'] as String,
        type: roomData['type'] as String,
      );
      final newRoomId = await roomRepo.addRoom(room);

      final appliancesList = roomData['appliances'] as List<Map<String, dynamic>>;
      for (final a in appliancesList) {
        final appliance = ApplianceModel(
          applianceId: '',
          roomId: newRoomId,
          name: a['name'] as String,
          category: a['category'] as String,
          quantity: a['qty'] as int,
          wattage: a['watt'] as double,
          hoursPerDay: a['hours'] as double,
          daysPerWeek: a['days'] as int,
        );
        await applianceRepo.addAppliance(appliance);
      }
    }
  }
}