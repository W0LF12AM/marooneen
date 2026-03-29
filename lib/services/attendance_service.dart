import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marooneen/models/attendance_model.dart';
import 'package:marooneen/models/class_model.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream list presensi mahasiswa buat suatu kelas
  Stream<List<AttendanceModel>> getAttendeesForClass(String classId) {
    return _db
        .collection('presensi')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList();
          list.sort(
            (a, b) => b.timestamp.compareTo(a.timestamp),
          ); // Sort lokal biar ga perlu setting Index Firebase
          return list;
        });
  }

  // Stream riwayat pribadi si user aja ntar buat HistoryTab
  Stream<List<AttendanceModel>> getUserAttendances(String userId) {
    return _db
        .collection('presensi')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList();
          list.sort(
            (a, b) => b.timestamp.compareTo(a.timestamp),
          ); // Sort lokal biar ga perlu setting Index Firebase
          return list;
        });
  }

  // Logika ngitung "Ini telat atau engga"
  String calculateStatus(ClassModel kelas) {
    final now = DateTime.now();

    // 1. Validasi Beda Hari: Kalau lu absen di hari yang BUKAN hari H kelasnya, otomatis Telat
    if (now.year != kelas.tanggal.year ||
        now.month != kelas.tanggal.month ||
        now.day != kelas.tanggal.day) {
      return 'Telat';
    }

    // 2. Validasi Range Waktu Jam (contoh format: "08:00 - 10:30")
    try {
      final parts = kelas.jam.split('-');
      
      if (parts.length == 2) {
        // Ada rentang waktu awal dan akhir
        final startParts = parts[0].trim().split(':');
        final endParts = parts[1].trim().split(':');

        final startTime = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
        final endTime = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));

        // Kalau absen diluar range (sebelum mulai atau sesudah tutup), diitung telat 
        if (now.isBefore(startTime) || now.isAfter(endTime)) return 'Telat';
        return 'Hadir';

      } else {
        // Cuma format 1 angka "08:00"
        final singleParts = parts[0].trim().split(':');
        final exactTime = DateTime(now.year, now.month, now.day, int.parse(singleParts[0]), int.parse(singleParts[1]));
        
        if (now.isAfter(exactTime)) return 'Telat';
        return 'Hadir';
      }
    } catch (e) {
      // Ignored format fallback
    }
    
    return 'Hadir';
  }

  // Eksekusi nancet pin absen ke Firebase
  Future<void> submitAttendance(
    ClassModel kelas,
    String userId,
    String userName,
    String userNpm, {
    String? statusOverride,
    String? keterangan,
  }) async {
    final status = statusOverride ?? calculateStatus(kelas);
    final record = {
      'classId': kelas.id,
      'userId': userId,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
      'userName': userName,
      'userNpm': userNpm,
      'className': kelas.kelas,
      'pertemuan': kelas.pertemuan.toString(),
      if (keterangan != null) 'keterangan': keterangan,
    };

    // Pake format "classId_userId" jadi doc ID biar nggak bisa diabsen 2 kali
    await _db
        .collection('presensi')
        .doc('${kelas.id}_$userId')
        .set(record, SetOptions(merge: true));
  }
}
