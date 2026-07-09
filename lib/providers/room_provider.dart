import 'package:flutter/material.dart';
import '../repositories/room_repository.dart';
import '../models/room_model.dart';

class RoomProvider extends ChangeNotifier {
  final RoomRepository _roomRepository = RoomRepository();

  List<RoomModel> rooms = [];
  bool isLoading = false;

  void listenToRooms(String homeId) {
    isLoading = true;
    notifyListeners();

    _roomRepository.watchRooms(homeId).listen((roomList) {
      rooms = roomList;
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addRoom(String homeId, String name, String type) async {
    final room = RoomModel(
      roomId: '',
      homeId: homeId,
      name: name,
      type: type,
    );
    await _roomRepository.addRoom(room);
    // No need to manually update `rooms` list — the stream listener will do it automatically
  }

  Future<void> deleteRoom(String roomId) async {
    await _roomRepository.deleteRoom(roomId);
  }
}