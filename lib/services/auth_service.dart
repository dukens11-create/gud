import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// Sign in with email and password
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Sign out
  Future<void> signOut() => _auth.signOut();

  /// Create a new user account
  Future<UserCredential> createUser(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Create or update user document in Firestore with role
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

  /// Get user role from Firestore
  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data()?['role'] ?? 'driver') as String;
  }

  /// Reset password via email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Update user profile (display name)
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
