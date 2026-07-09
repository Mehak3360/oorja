import 'package:flutter/material.dart';
import '../repositories/appliance_repository.dart';
import '../models/appliance_model.dart';

class ApplianceProvider extends ChangeNotifier {
  final ApplianceRepository _applianceRepository = ApplianceRepository();

  List<ApplianceModel> appliances = [];
  bool isLoading = false;

  void listenToAppliances(String roomId) {
    isLoading = true;
    notifyListeners();

    _applianceRepository.watchAppliances(roomId).listen((list) {
      appliances = list;
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addAppliance(ApplianceModel appliance) async {
    await _applianceRepository.addAppliance(appliance);
  }

  Future<void> deleteAppliance(String applianceId) async {
    await _applianceRepository.deleteAppliance(applianceId);
  }

  Future<void> updateAppliance(String applianceId, Map<String, dynamic> data) async {
    await _applianceRepository.updateAppliance(applianceId, data);
  }
}