import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserCredential> createUser(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> ensureUserDoc({
    required String uid,
    required String role,
    required String name,
    required String phone,
    required String truckNumber,
  }) async {
    await _db.collection('users').doc(uid).set({
      'role': role,
      'name': name,
      'phone': phone,
      'truckNumber': truckNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'driverId': uid,
    }, SetOptions(merge: true));
  }
}