import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class LiveReading {
  final String channel; // "CT1", "CT2" ya "CT3"
  final double amps;
  final DateTime? updatedAt;

  const LiveReading({
    required this.channel,
    required this.amps,
    this.updatedAt,
  });

  // Voltage sensor nahi hai, isliye nominal 230V assume kiya hai
  static const double nominalVoltage = 230.0;

  double get watts => amps * nominalVoltage;

  // updatedAt null ho toh (ESP32 pe ts abhi add nahi hua) stale nahi maante
  bool get isStale =>
      updatedAt != null &&
      DateTime.now().difference(updatedAt!) > const Duration(seconds: 30);
}

class LiveReadingService {
  LiveReadingService._();
  static final LiveReadingService instance = LiveReadingService._();

  static const String _dbUrl =
      'https://oorja-4a18a-default-rtdb.asia-southeast1.firebasedatabase.app';

  static const List<String> channels = ['CT1', 'CT2', 'CT3'];

  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: _dbUrl,
  );

  /// Har channel ki latest reading, key = "CT1" / "CT2" / "CT3"
  Stream<Map<String, LiveReading>> watch() {
    return _db.ref('current').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <String, LiveReading>{};

      final ts = raw['ts'];
      final updatedAt =
          ts is int ? DateTime.fromMillisecondsSinceEpoch(ts) : null;

      final result = <String, LiveReading>{};
      for (final ch in channels) {
        final v = raw[ch];
        if (v is num) {
          result[ch] = LiveReading(
            channel: ch,
            amps: v.toDouble(),
            updatedAt: updatedAt,
          );
        }
      }
      return result;
    });
  }
}