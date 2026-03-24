import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marooneen/models/class_model.dart';

class ClassService {
  final CollectionReference _kelasCollection =
      FirebaseFirestore.instance.collection('kelas');

  /// Get all kelas (one-time fetch)
  Future<List<ClassModel>> getKelas() async {
    final snapshot = await _kelasCollection.get();
    return snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList();
  }

  /// Get a single kelas by ID
  Future<ClassModel?> getKelasById(String id) async {
    final doc = await _kelasCollection.doc(id).get();
    if (doc.exists) return ClassModel.fromFirestore(doc);
    return null;
  }

  /// Stream all kelas (real-time updates)
  Stream<List<ClassModel>> streamKelas() {
    return _kelasCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList());
  }
}
