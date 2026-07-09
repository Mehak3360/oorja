import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';

class RoomRepository {
  final CollectionReference _rooms =
      FirebaseFirestore.instance.collection('rooms');

  Future<String> addRoom(RoomModel room) async {
    final docRef = await _rooms.add(room.toMap());
    return docRef.id;
  }

  Future<void> deleteRoom(String roomId) async {
    await _rooms.doc(roomId).delete();
  }

  Stream<List<RoomModel>> watchRooms(String homeId) {
    return _rooms
        .where('homeId', isEqualTo: homeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}