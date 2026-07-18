import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportRepository {
  final CollectionReference _reports =
      FirebaseFirestore.instance.collection('reports');

  Future<String> saveReport(ReportModel report) async {
    final docRef = await _reports.add(report.toMap());
    return docRef.id;
  }

  Stream<List<ReportModel>> watchReports(String homeId) {
    return _reports
        .where('homeId', isEqualTo: homeId)
        .orderBy('generatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<ReportModel?> getLatestReport(String homeId) async {
    final snapshot = await _reports
        .where('homeId', isEqualTo: homeId)
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ReportModel.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
  }
}