import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String role,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (userCredential.user != null) {
        final appUser = AppUser(
          uid: userCredential.user!.uid,
          email: email,
          role: role,
        );
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(appUser.toMap());
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Ensure user document exists
  Future<void> ensureUserDocument(User user, String role) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final appUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          role: role,
        );
        await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }
}
