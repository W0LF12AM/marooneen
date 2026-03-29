import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marooneen/models/fraud_model.dart';

class FraudService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Simpan log fraud ke collection 'fraud_logs'
  Future<void> logFraud({
    required String userId,
    required String userName,
    required String userNpm,
    required String classId,
    required String className,
    required String fraudType,
    required String description,
    double? latitude,
    double? longitude,
    double? distanceFromClass,
    double? faceScore,
  }) async {
    final data = {
      'userId': userId,
      'userName': userName,
      'userNpm': userNpm,
      'classId': classId,
      'className': className,
      'fraudType': fraudType,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (distanceFromClass != null) 'distanceFromClass': distanceFromClass,
      if (faceScore != null) 'faceScore': faceScore,
    };

    await _db.collection('fraud_logs').add(data);
  }

  /// Stream semua fraud logs (untuk admin dashboard)
  Stream<List<FraudModel>> getAllFraudLogs() {
    return _db
        .collection('fraud_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FraudModel.fromFirestore(doc)).toList());
  }

  /// Stream fraud logs milik user tertentu
  Stream<List<FraudModel>> getUserFraudLogs(String userId) {
    return _db
        .collection('fraud_logs')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => FraudModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }
}
