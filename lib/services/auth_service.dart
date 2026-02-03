import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _db;
  final bool _isOffline;

  AuthService()
      : _auth = _getFirebaseAuth(),
        _db = _getFirestore(),
        _isOffline = _getFirebaseAuth() == null;

  static FirebaseAuth? _getFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      return null;
    }
  }

  static FirebaseFirestore? _getFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  User? get currentUser => _auth?.currentUser;
  Stream<User?> get authStateChanges {
    if (_isOffline) {
      return Stream.value(null);
    }
    return _auth!.authStateChanges();
  }

  Future<UserCredential?> signIn(String email, String password) async {
    if (_isOffline) {
      // Mock authentication for offline mode
      if (email == 'admin@gud.com' && password == 'admin123') {
        return null; // Mock success
      }
      if (email == 'driver@gud.com' && password == 'driver123') {
        return null; // Mock success
      }
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Invalid credentials (offline mode)',
      );
    }
    return _auth!.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    if (_isOffline) return;
    await _auth!.signOut();
  }

  Future<UserCredential?> createUser(String email, String password) async {
    if (_isOffline) {
      throw FirebaseAuthException(
        code: 'unavailable',
        message: 'User creation not available in offline mode',
      );
    }
    return _auth!.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? truckNumber,
  }) async {
    if (_isOffline) {
      throw FirebaseAuthException(
        code: 'unavailable',
        message: 'User registration not available in offline mode',
      );
    }

    final credential = await _auth!.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db!.collection('users').doc(credential.user!.uid).set({
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
    if (_isOffline) return;
    await _db!.collection('users').doc(uid).set({
      'role': role,
      'name': name,
      'phone': phone,
      'truckNumber': truckNumber,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> getUserRole(String uid) async {
    if (_isOffline) {
      return 'driver'; // Default role in offline mode
    }
    final doc = await _db!.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'driver';
  }

  Future<void> resetPassword(String email) async {
    if (_isOffline) {
      throw FirebaseAuthException(
        code: 'unavailable',
        message: 'Password reset not available in offline mode',
      );
    }
    await _auth!.sendPasswordResetEmail(email: email);
  }
}
