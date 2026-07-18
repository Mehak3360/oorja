import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_usage_model.dart';

class DailyUsageRepository {
  final CollectionReference _logs =
      FirebaseFirestore.instance.collection('daily_usage_logs');

  Future<void> logTodayUsage(String homeId, double units, double cost) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final docId = '${homeId}_$dateStr';

    // Only write if today's log doesn't already exist
    final existing = await _logs.doc(docId).get();
    if (!existing.exists) {
      await _logs.doc(docId).set({
        'homeId': homeId,
        'date': dateStr,
        'units': units,
        'cost': cost,
      });
    }
  }

  Future<List<DailyUsageModel>> getLastNDays(String homeId, int n) async {
    final now = DateTime.now();
    final List<DailyUsageModel> result = [];

    for (int i = n - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final docId = '${homeId}_$dateStr';

      final doc = await _logs.doc(docId).get();
      if (doc.exists) {
        result.add(DailyUsageModel.fromMap(doc.data() as Map<String, dynamic>));
      } else {
        result.add(DailyUsageModel(date: dateStr, units: 0, cost: 0));
      }
    }

    return result;
  }
}