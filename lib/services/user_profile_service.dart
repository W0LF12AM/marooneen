import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marooneen/models/user_profile_model.dart';

class UserProfileService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// Ambil profil berdasarkan UID (null kalau belum ada)
  Future<UserProfileModel?> getProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists) return UserProfileModel.fromFirestore(doc);
    return null;
  }

  /// Simpan/update profil berdasarkan UID dengan metode merge
  Future<void> saveProfile(String uid, UserProfileModel profile) async {
    await _usersCollection.doc(uid).set(
      profile.toFirestore(),
      SetOptions(merge: true),
    );
  }

  /// Stream profil real-time
  Stream<UserProfileModel?> streamProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) return UserProfileModel.fromFirestore(doc);
      return null;
    });
  }
}
