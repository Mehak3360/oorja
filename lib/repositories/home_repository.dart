import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/home_model.dart';

class HomeRepository {
  final CollectionReference _homes =
      FirebaseFirestore.instance.collection('home');

  Future<void> createHome(String uid, HomeModel home) async {
    await _homes.doc(uid).set(home.toMap());
  }

  Future<HomeModel?> getHome(String uid) async {
    final doc = await _homes.doc(uid).get();
    if (!doc.exists) return null;
    return HomeModel.fromMap(doc.data() as Map<String, dynamic>, uid);
  }

  Future<void> updateHome(String uid, Map<String, dynamic> data) async {
    await _homes.doc(uid).update(data);
  }

  Stream<HomeModel?> watchHome(String uid) {
    return _homes.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return HomeModel.fromMap(doc.data() as Map<String, dynamic>, uid);
    });
  }

  Future<bool> isSetupComplete(String uid) async {
    final home = await getHome(uid);
    return home?.setupComplete ?? false;
  }
}