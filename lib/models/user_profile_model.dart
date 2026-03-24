import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String name;
  final String kelas;
  final String npm;
  final String fakultas;
  final String jurusan;
  final String phone;
  final String gender;
  final List<double>? faceEmbedding; // ← Array penyimpan data wajah

  UserProfileModel({
    required this.kelas,
    required this.name,
    required this.npm,
    required this.fakultas,
    required this.jurusan,
    required this.phone,
    required this.gender,
    this.faceEmbedding,
  });

  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Konversi bentuk dinamis List<dynamic> dari Firestore balik jadi List<double>
    List<double>? extractedEmbedding;
    if (data['faceEmbedding'] != null) {
      extractedEmbedding = List<double>.from(
        data['faceEmbedding'].map((e) => e.toDouble()),
      );
    }

    return UserProfileModel(
      kelas: data['kelas'] ?? '',
      name: data['name'] ?? '',
      npm: data['npm'] ?? '',
      fakultas: data['fakultas'] ?? '',
      jurusan: data['jurusan'] ?? '',
      phone: data['phone'] ?? '',
      gender: data['gender'] ?? '',
      faceEmbedding: extractedEmbedding,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'kelas': kelas,
      'name': name,
      'npm': npm,
      'fakultas': fakultas,
      'jurusan': jurusan,
      'phone': phone,
      'gender': gender,
    };

    if (faceEmbedding != null) map['faceEmbedding'] = faceEmbedding;

    return map;
  }
}
