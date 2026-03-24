import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marooneen/models/user_model.dart';

class UserService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// Get all users (one-time fetch)
  Future<List<UserModel>> getUsers() async {
    final snapshot = await _usersCollection.get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  /// Get a single user by ID
  Future<UserModel?> getUserById(String id) async {
    final doc = await _usersCollection.doc(id).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  /// Stream all users (real-time updates)
  Stream<List<UserModel>> streamUsers() {
    return _usersCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  /// Add a new user
  // Future<void> addUser(UserModel user) async {
  //   await _usersCollection.add(user.toFirestore());
  // }

  /// Update an existing user
  // Future<void> updateUser(UserModel user) async {
  //   await _usersCollection.doc(user.id).update(user.toFirestore());
  // }

  /// Delete a user
  // Future<void> deleteUser(String id) async {
  //   await _usersCollection.doc(id).delete();
  // }
}
