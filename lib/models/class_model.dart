import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseTanggal(dynamic value) {
  if (value == null) {
    return DateTime.now();
  }

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  return DateTime.now();
}

class ClassModel {
  final String id;
  final String jam;
  final String kelas;
  final double latitude;
  final double longitude;
  final String pertemuan;
  final int radius;
  final DateTime tanggal;
  final String tempat;
  final String tipeKelas;

  ClassModel({
    required this.id,
    required this.jam,
    required this.kelas,
    required this.latitude,
    required this.longitude,
    required this.pertemuan,
    required this.radius,
    required this.tanggal,
    required this.tempat,
    required this.tipeKelas,
  });

  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      id: doc.id,
      jam: data['jam'] ?? '',
      kelas: data['kelas'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      pertemuan: data['pertemuan'] ?? '',
      radius: (data['radius'] ?? 0).toInt(),
      tanggal: _parseTanggal(data['tanggal']),
      tempat: data['tempat'] ?? '',
      tipeKelas: data['tipe_kelas'] ?? 'Offline',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'jam': jam,
      'kelas': kelas,
      'latitude': latitude,
      'longitude': longitude,
      'pertemuan': pertemuan,
      'radius': radius,
      'tanggal': Timestamp.fromDate(tanggal),
      'tempat': tempat,
      'tipe_kelas': tipeKelas,
    };
  }
}
