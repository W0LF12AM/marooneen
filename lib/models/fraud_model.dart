import 'package:cloud_firestore/cloud_firestore.dart';

class FraudModel {
  final String id;
  final String userId;
  final String userName;
  final String userNpm;
  final String classId;
  final String className;
  final String fraudType; // 'out_of_radius' | 'fake_gps' | 'face_mismatch'
  final String description;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final double? distanceFromClass;
  final double? faceScore; // Euclidean distance score (face_mismatch)

  FraudModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userNpm,
    required this.classId,
    required this.className,
    required this.fraudType,
    required this.description,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.distanceFromClass,
    this.faceScore,
  });

  factory FraudModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FraudModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userNpm: data['userNpm'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      fraudType: data['fraudType'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      distanceFromClass: (data['distanceFromClass'] as num?)?.toDouble(),
      faceScore: (data['faceScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
  }
}
