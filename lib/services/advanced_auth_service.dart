import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

/// Advanced Authentication Service
/// 
/// Provides extended authentication capabilities:
/// - Email/password authentication (existing)
/// - Google Sign-In (OAuth)
/// - Apple Sign-In (iOS)
/// - Two-factor authentication (2FA)
/// - Phone number verification
/// - Biometric authentication
/// 
/// Setup Requirements:
/// 1. Configure OAuth providers in Firebase Console
/// 2. Add SHA-1/SHA-256 fingerprints for Android
/// 3. Enable Sign in with Apple capability for iOS
/// 4. Configure redirect URIs
/// 
/// TODO: Implement biometric authentication
/// TODO: Add session management
/// TODO: Implement account linking
/// TODO: Add password strength requirements
class AdvancedAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? _verificationId; // For phone verification

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // =========================
  // Email/Password Auth
  // =========================

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Signed in: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('❌ Sign in error: ${e.message}');
      rethrow;
    }
  }

  /// Create account with email and password
  Future<UserCredential> createAccountWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Account created: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('❌ Account creation error: ${e.message}');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      print('❌ Password reset error: ${e.message}');
      rethrow;
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
      print('✅ Password updated successfully');
    } on FirebaseAuthException catch (e) {
      print('❌ Password update error: ${e.message}');
      rethrow;
    }
  }

  // =========================
  // Google Sign-In
  // =========================

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('⚠️ Google sign-in cancelled by user');
        return null;
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user document
      await _createOrUpdateUserDocument(
        userCredential.user!,
        authProvider: 'google',
      );

      print('✅ Google sign-in successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      print('❌ Google sign-in error: $e');
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  // =========================
  // Apple Sign-In
  // =========================

  /// Sign in with Apple (iOS only)
  Future<UserCredential?> signInWithApple() async {
    if (!Platform.isIOS) {
      throw UnsupportedError('Apple Sign-In is only available on iOS');
    }

    try {
      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw UnsupportedError('Apple Sign-In not available on this device');
      }

      // Request credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuth credential for Firebase
      final oAuthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(oAuthCredential);

      // Create or update user document
      await _createOrUpdateUserDocument(
        userCredential.user!,
        authProvider: 'apple',
        displayName: appleCredential.givenName != null
            ? '${appleCredential.givenName} ${appleCredential.familyName}'
            : null,
      );

      print('✅ Apple sign-in successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      print('❌ Apple sign-in error: $e');
      rethrow;
    }
  }

  // =========================
  // Phone Authentication (2FA)
  // =========================

  /// Send verification code to phone number
  Future<void> sendPhoneVerificationCode(
    String phoneNumber, {
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
    Function(PhoneAuthCredential credential)? onAutoVerify,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Phone auto-verified');
          if (onAutoVerify != null) {
            onAutoVerify(credential);
          } else {
            // Auto-verify for Android
            await _auth.signInWithCredential(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Phone verification failed: ${e.message}');
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ Verification code sent to: $phoneNumber');
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      print('❌ Error sending verification code: $e');
      rethrow;
    }
  }

  /// Verify phone number with code
  Future<UserCredential> verifyPhoneCode(String smsCode) async {
    if (_verificationId == null) {
      throw Exception('No verification ID available. Send code first.');
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      print('✅ Phone verified successfully');
      return userCredential;
    } catch (e) {
      print('❌ Phone verification error: $e');
      rethrow;
    }
  }

  /// Link phone number to existing account (for 2FA)
  Future<void> linkPhoneNumber(String smsCode) async {
    if (_verificationId == null) {
      throw Exception('No verification ID available. Send code first.');
    }

    if (currentUser == null) {
      throw Exception('No user signed in');
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await currentUser!.linkWithCredential(credential);
      
      // Update user document with phone verified status
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'phoneVerified': true,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Phone number linked to account');
    } catch (e) {
      print('❌ Error linking phone number: $e');
      rethrow;
    }
  }

  // =========================
  // Two-Factor Authentication
  // =========================

  /// Enable 2FA for current user
  Future<void> enable2FA(String phoneNumber) async {
    if (currentUser == null) {
      throw Exception('No user signed in');
    }

    // Send verification code
    await sendPhoneVerificationCode(
      phoneNumber,
      onCodeSent: (verificationId) {
        print('✅ 2FA setup code sent');
      },
      onVerificationFailed: (error) {
        throw Exception('2FA setup failed: ${error.message}');
      },
    );
  }

  /// Verify 2FA setup with code
  Future<void> verify2FASetup(String smsCode) async {
    await linkPhoneNumber(smsCode);
    
    // Mark 2FA as enabled
    await _firestore.collection('users').doc(currentUser!.uid).update({
      '2faEnabled': true,
      '2faEnabledAt': FieldValue.serverTimestamp(),
    });

    print('✅ 2FA enabled successfully');
  }

  /// Disable 2FA for current user
  Future<void> disable2FA() async {
    if (currentUser == null) {
      throw Exception('No user signed in');
    }

    // TODO: Implement phone credential unlinking
    // Note: Firebase doesn't directly support unlinking phone
    // Consider using custom backend logic
    
    await _firestore.collection('users').doc(currentUser!.uid).update({
      '2faEnabled': false,
      '2faDisabledAt': FieldValue.serverTimestamp(),
    });

    print('✅ 2FA disabled');
  }

  // =========================
  // Email Verification
  // =========================

  /// Send email verification
  Future<void> sendEmailVerification() async {
    if (currentUser == null) {
      throw Exception('No user signed in');
    }

    if (currentUser!.emailVerified) {
      print('⚠️ Email already verified');
      return;
    }

    try {
      await currentUser!.sendEmailVerification();
      print('✅ Verification email sent to: ${currentUser!.email}');
    } catch (e) {
      print('❌ Error sending verification email: $e');
      rethrow;
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    await currentUser?.reload();
    return currentUser?.emailVerified ?? false;
  }

  // =========================
  // Account Management
  // =========================

  /// Delete current user account
  Future<void> deleteAccount() async {
    if (currentUser == null) {
      throw Exception('No user signed in');
    }

    final userId = currentUser!.uid;

    try {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete Firebase Auth account
      await currentUser!.delete();
      
      print('✅ Account deleted successfully');
    } catch (e) {
      print('❌ Error deleting account: $e');
      rethrow;
    }
  }

  /// Re-authenticate user (required before sensitive operations)
  Future<void> reauthenticate(String password) async {
    if (currentUser == null || currentUser!.email == null) {
      throw Exception('No user signed in or email not available');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );

      await currentUser!.reauthenticateWithCredential(credential);
      print('✅ Re-authenticated successfully');
    } catch (e) {
      print('❌ Re-authentication failed: $e');
      rethrow;
    }
  }

  // =========================
  // Sign Out
  // =========================

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    print('✅ Signed out successfully');
  }

  // =========================
  // Helper Methods
  // =========================

  /// Create or update user document in Firestore after OAuth sign-in
  Future<void> _createOrUpdateUserDocument(
    User user, {
    String? authProvider,
    String? displayName,
  }) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    final userData = {
      'email': user.email,
      'displayName': displayName ?? user.displayName,
      'photoURL': user.photoURL,
      'authProvider': authProvider,
      'lastSignIn': FieldValue.serverTimestamp(),
    };

    if (!docSnapshot.exists) {
      // Create new user document
      await userDoc.set({
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'driver', // Default role, admin should change if needed
      });
      print('✅ User document created');
    } else {
      // Update existing user document
      await userDoc.update(userData);
      print('✅ User document updated');
    }
  }

  /// Get user role from Firestore
  Future<String?> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['role'];
    } catch (e) {
      print('❌ Error getting user role: $e');
      return null;
    }
  }
}

// TODO: Implement biometric authentication
// Use local_auth package for Face ID, Touch ID, fingerprint
// Example:
// final localAuth = LocalAuthentication();
// final canAuthenticate = await localAuth.canCheckBiometrics;
// final didAuthenticate = await localAuth.authenticate(
//   localizedReason: 'Please authenticate to sign in',
// );

// TODO: Add account linking
// Allow users to link multiple auth providers (Google + Email, Apple + Email)
// Example:
// final googleCredential = GoogleAuthProvider.credential(...);
// await currentUser.linkWithCredential(googleCredential);

// TODO: Implement session management
// Track active sessions across devices
// Allow users to view and revoke sessions
// Store session info in Firestore:
// users/{userId}/sessions/{sessionId}

// TODO: Add password strength requirements
// Minimum 8 characters
// At least one uppercase letter
// At least one lowercase letter
// At least one number
// At least one special character

// TODO: Implement account recovery options
// Security questions
// Recovery email
// Trusted devices
// Backup codes for 2FA
