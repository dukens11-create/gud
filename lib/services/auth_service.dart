import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Authentication service for managing user authentication and user data.
/// 
/// Provides methods for sign in, sign out, user registration, and role management.
/// Supports Firebase authentication for production use.
/// 
/// Features:
/// - Email/password authentication
/// - User registration with role assignment
/// - Password reset functionality
/// - Automatic error logging to Crashlytics
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

  /// Returns the currently authenticated user, or null if not authenticated
  User? get currentUser => _auth?.currentUser;
  
  /// Stream of authentication state changes
  /// 
  /// Emits whenever the user signs in or out
  Stream<User?> get authStateChanges {
    if (_isOffline) {
      return Stream.value(null);
    }
    return _auth!.authStateChanges();
  }

  /// Sign in a user with email and password
  /// 
  /// Returns [UserCredential] on success
  /// Throws [FirebaseAuthException] on authentication failure
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      if (_isOffline) {
        throw FirebaseAuthException(
          code: 'unavailable',
          message: 'Authentication not available in offline mode',
        );
      }
      return await _auth!.signInWithEmailAndPassword(email: email, password: password);
    } catch (e, stackTrace) {
      // Log error to Crashlytics
      if (!_isOffline) {
        await FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason: 'Sign in failed for email: $email',
          fatal: false,
        );
      }
      rethrow;
    }
  }

  /// Sign out the currently authenticated user
  Future<void> signOut() async {
    if (_isOffline) return;
    await _auth!.signOut();
  }

  /// Create a new user account with email and password
  /// 
  /// Returns [UserCredential] on success
  /// Throws [FirebaseAuthException] if user creation fails
  /// Not available in offline mode
  Future<UserCredential?> createUser(String email, String password) async {
    try {
      if (_isOffline) {
        throw FirebaseAuthException(
          code: 'unavailable',
          message: 'User creation not available in offline mode',
        );
      }
      return await _auth!.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e, stackTrace) {
      // Log error to Crashlytics
      if (!_isOffline) {
        await FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason: 'Create user failed for email: $email',
          fatal: false,
        );
      }
      rethrow;
    }
  }

  /// Register a new user with full profile information
  /// 
  /// Creates Firebase Authentication account and user profile in Firestore
  /// 
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  /// - [name]: User's full name
  /// - [role]: User role ('admin' or 'driver')
  /// - [phone]: Optional phone number
  /// - [truckNumber]: Optional truck number (for drivers)
  /// 
  /// Returns [UserCredential] on success
  /// Throws [FirebaseAuthException] on failure
  Future<UserCredential?> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? truckNumber,
  }) async {
    try {
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

      // Send email verification immediately after account creation
      await credential.user!.sendEmailVerification();
      print('✅ Verification email sent to: $email');

      await _db!.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'role': role,
        'phone': phone ?? '',
        'truckNumber': truckNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'emailVerified': false,
        'verificationEmailSentAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } catch (e, stackTrace) {
      // Log error to Crashlytics
      if (!_isOffline) {
        await FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason: 'User registration failed for email: $email, role: $role',
          fatal: false,
        );
      }
      rethrow;
    }
  }

  /// Ensure user document exists in Firestore
  /// 
  /// Creates or updates user document with provided data.
  /// Uses merge: true to preserve existing fields.
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

  /// Get user's role from Firestore
  /// 
  /// Returns 'admin' or 'driver', defaults to 'driver' if not found
  Future<String> getUserRole(String uid) async {
    if (_isOffline) {
      return 'driver'; // Default role in offline mode
    }
    final doc = await _db!.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'driver';
  }

  /// Send password reset email
  /// 
  /// Sends password reset email to the specified address
  /// Throws [FirebaseAuthException] if email is invalid
  /// Not available in offline mode
  Future<void> resetPassword(String email) async {
    if (_isOffline) {
      throw FirebaseAuthException(
        code: 'unavailable',
        message: 'Password reset not available in offline mode',
      );
    }
    await _auth!.sendPasswordResetEmail(email: email);
  }

  /// Reload the current user's data
  /// 
  /// Fetches the latest user data from Firebase Auth
  /// This is useful for checking email verification status
  Future<void> reloadUser() async {
    if (_isOffline || _auth?.currentUser == null) return;
    await _auth!.currentUser!.reload();
  }
}
