import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserCredential> createUser(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? truckNumber,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('users').doc(credential.user!.uid).set({
      'name': name,
      'email': email,
      'role': role,
      'phone': phone ?? '',
      'truckNumber': truckNumber ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });

    return credential;
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
    }, SetOptions(merge: true));
  }

  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'driver';
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
