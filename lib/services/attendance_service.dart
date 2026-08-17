import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
  String calculateStatus(ClassModel kelas, {int toleranceMinutes = 15}) {
    final now = DateTime.now();
    final localKelasTanggal = kelas.tanggal.toLocal();

    // 1. Validasi Beda Hari: Kalau absen di hari yang BUKAN hari H kelasnya, otomatis Telat
    if (now.year != localKelasTanggal.year ||
        now.month != localKelasTanggal.month ||
        now.day != localKelasTanggal.day) {
      return 'Telat';
    }

    // 2. Validasi Jam / Waktu Presensi
    try {
      if (kelas.jam.trim().isEmpty) return 'Hadir';

      // Ambil bagian jam mulai (sebelum tanda '-')
      final startPart = kelas.jam.split('-')[0].trim();

      // Bersihkan karakter selain angka dan separator (: atau .)
      final cleanTimeStr = startPart.replaceAll(RegExp(r'[^\d:\.]'), '');

      // Standardisasi titik (.) menjadi titik dua (:)
      final timeComponents = cleanTimeStr.replaceAll('.', ':').split(':');

      if (timeComponents.length >= 2) {
        final startHour = int.parse(timeComponents[0]);
        final startMinute = int.parse(timeComponents[1]);

        // Waktu mulai kelas
        final startTime = DateTime(
          now.year,
          now.month,
          now.day,
          startHour,
          startMinute,
        );

        // Batas akhir toleransi presensi (StartTime + toleranceMinutes)
        final lateThreshold = startTime.add(Duration(minutes: toleranceMinutes));

        // Jika waktu presensi sekarang MELEBIHI batas toleransi -> TELAT
        if (now.isAfter(lateThreshold)) {
          return 'Telat';
        }

        return 'Hadir';
      }
    } catch (e) {
      debugPrint('Error parsing class time "${kelas.jam}": $e');
    }

    return 'Hadir';
  }

  // Cek apakah user sudah pernah presensi di kelas ini
  Future<bool> hasUserAttended(String classId, String userId) async {
    final doc = await _db
        .collection('presensi')
        .doc('${classId}_$userId')
        .get();
    return doc.exists;
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
