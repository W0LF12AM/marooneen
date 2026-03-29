import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String classId;
  final String userId;
  final String status; // 'Hadir' or 'Telat'
  final DateTime timestamp;
  final String userName;
  final String userNpm;
  final String className;
  final String pertemuan;
  final String? keterangan;

  AttendanceModel({
    required this.id,
    required this.classId,
    required this.userId,
    required this.status,
    required this.timestamp,
    required this.userName,
    required this.userNpm,
    required this.className,
    required this.pertemuan,
    this.keterangan,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'Hadir',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userName: data['userName'] ?? '',
      userNpm: data['userNpm'] ?? '',
      className: data['className'] ?? 'Unknown Class',
      pertemuan: data['pertemuan'] ?? '-',
      keterangan: data['keterangan'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'userId': userId,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'userName': userName,
      'userNpm': userNpm,
      'className': className,
      'pertemuan': pertemuan,
      if (keterangan != null) 'keterangan': keterangan,
    };
  }
}
