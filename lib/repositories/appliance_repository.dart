import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appliance_model.dart';

class ApplianceRepository {
  final CollectionReference _appliances =
      FirebaseFirestore.instance.collection('appliances');

  Future<String> addAppliance(ApplianceModel appliance) async {
    final docRef = await _appliances.add(appliance.toMap());
    return docRef.id;
  }

  Future<void> updateAppliance(String applianceId, Map<String, dynamic> data) async {
    await _appliances.doc(applianceId).update(data);
  }

  Future<void> deleteAppliance(String applianceId) async {
    await _appliances.doc(applianceId).delete();
  }

  Stream<List<ApplianceModel>> watchAppliances(String roomId) {
    return _appliances
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApplianceModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());

  }
  Stream<List<ApplianceModel>> watchAllAppliancesForHome(List<String> roomIds) {
      if (roomIds.isEmpty) {
        return Stream.value([]);
      }
      return _appliances
          .where('roomId', whereIn: roomIds)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ApplianceModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList());
    }
}