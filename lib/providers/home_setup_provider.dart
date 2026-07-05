import 'package:flutter/material.dart';
import '../repositories/home_repository.dart';
import '../models/home_model.dart';

class HomeSetupProvider extends ChangeNotifier {
  final HomeRepository _homeRepository = HomeRepository();

  bool isLoading = false;
  String? errorMessage;

  Future<bool> submitHomeSetup(String uid, HomeModel home) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _homeRepository.createHome(uid, home);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}