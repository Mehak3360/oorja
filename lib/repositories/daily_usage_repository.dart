import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/daily_usage_model.dart';

class DailyUsageRepository {
  final CollectionReference _logs =
      FirebaseFirestore.instance.collection('daily_usage_logs');

  Future<void> logTodayUsage(String homeId, double units, double cost) async {
    // Don't overwrite today's log with a zero from a transient empty snapshot
    if (units <= 0) return;

    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final docId = '${homeId}_$dateStr';

    // Always update today's log with the latest calculated value
    await _logs.doc(docId).set({
      'homeId': homeId,
      'date': dateStr,
      'units': units,
      'cost': cost,
    });
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

  /// Backfills the past [days] (excluding today) with usage logs derived from
  /// [avgDailyUnits], adding light day-to-day random variation so the weekly
  /// chart looks realistic instead of a flat line. Used by DemoDataGenerator
  /// so the "This Week's Usage" chart isn't empty right after generating demo data.
  /// Existing logs are never overwritten.
  Future<void> backfillPastDays(
    String homeId,
    double avgDailyUnits,
    double tariffPerUnit, {
    int days = 6,
  }) async {
    final now = DateTime.now();
    final random = Random();
    final batch = FirebaseFirestore.instance.batch();

    for (int i = 1; i <= days; i++) {
      final day = now.subtract(Duration(days: i));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final docId = '${homeId}_$dateStr';
      final docRef = _logs.doc(docId);

      final existing = await docRef.get();
      if (existing.exists) continue; // never overwrite real logged data

      // +/- 15% random variation so the bars aren't perfectly flat
      final variation = 0.85 + random.nextDouble() * 0.3;
      final units = avgDailyUnits * variation;
      final cost = units * tariffPerUnit;

      batch.set(docRef, {
        'homeId': homeId,
        'date': dateStr,
        'units': units,
        'cost': cost,
      });
    }

    await batch.commit();
  }
}