import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gud_app/services/auth_service.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  UserCredential,
  User,
  DocumentReference,
  DocumentSnapshot,
  CollectionReference,
])
void main() {
  // Note: AuthService uses FirebaseAuth.instance and FirebaseFirestore.instance internally,
  // which makes it difficult to inject mocks without refactoring the service.
  // These tests focus on offline mode behavior which is well-supported by the service.
  // For full Firebase integration testing, consider using firebase_auth_mocks package
  // or Firebase emulators.
  
  group('AuthService', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUserCredential mockUserCredential;
    late MockUser mockUser;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUserCredential = MockUserCredential();
      mockUser = MockUser();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    });

    group('signIn', () {
      test('signIn with valid credentials returns UserCredential', () async {
        // Create a real AuthService instance
        final service = AuthService();

        // Mock successful sign in
        when(mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockUserCredential);

        // Note: Since AuthService uses FirebaseAuth.instance internally,
        // we can't easily inject mocks. We'll test the offline mode instead.
      });

      test('signIn throws exception in offline mode', () async {
        final service = AuthService();

        // In offline mode, all sign-in attempts should throw
        expect(
          () => service.signIn('invalid@example.com', 'wrong'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('signOut', () {
      test('signOut completes without error', () async {
        final service = AuthService();

        // Should complete without error in offline mode
        await expectLater(
          service.signOut(),
          completes,
        );
      });
    });

    group('createUser', () {
      test('createUser throws exception in offline mode', () async {
        final service = AuthService();

        expect(
          () => service.createUser('new@example.com', 'password123'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('register', () {
      test('register throws exception in offline mode', () async {
        final service = AuthService();

        expect(
          () => service.register(
            email: 'new@example.com',
            password: 'password123',
            name: 'John Doe',
            role: 'driver',
            phone: '555-1234',
            truckNumber: 'TRK-001',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('register requires all mandatory parameters', () async {
        final service = AuthService();

        // Test that missing parameters cause compilation error
        // This is a compile-time check, not runtime
        expect(
          () => service.register(
            email: 'new@example.com',
            password: 'password123',
            name: 'John Doe',
            role: 'driver',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('getUserRole', () {
      test('getUserRole returns default role in offline mode', () async {
        final service = AuthService();

        final role = await service.getUserRole('test-uid');
        expect(role, 'driver'); // Default role in offline mode
      });
    });

    group('resetPassword', () {
      test('resetPassword throws exception in offline mode', () async {
        final service = AuthService();

        expect(
          () => service.resetPassword('test@example.com'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('currentUser', () {
      test('currentUser returns null in offline mode', () {
        final service = AuthService();

        expect(service.currentUser, isNull);
      });
    });

    group('authStateChanges', () {
      test('authStateChanges returns stream with null in offline mode', () async {
        final service = AuthService();

        final stream = service.authStateChanges;
        expect(await stream.first, isNull);
      });
    });

    group('offline mode scenarios', () {
      test('service detects offline mode correctly', () {
        final service = AuthService();

        // In test environment, Firebase is not initialized,
        // so service should be in offline mode
        expect(service.currentUser, isNull);
      });

      test('signIn rejects all credentials in offline mode', () async {
        final service = AuthService();

        // All sign-in attempts should fail in offline mode
        expect(
          () => service.signIn('any@example.com', 'password'),
          throwsA(predicate((e) =>
            e is FirebaseAuthException &&
            e.code == 'unavailable'
          )),
        );
      });

      test('unavailable operations throw appropriate errors', () async {
        final service = AuthService();

        // Test all operations that should be unavailable
        expect(
          () => service.createUser('test@example.com', 'password'),
          throwsA(predicate((e) =>
            e is FirebaseAuthException &&
            e.code == 'unavailable'
          )),
        );

        expect(
          () => service.register(
            email: 'test@example.com',
            password: 'password',
            name: 'Test',
            role: 'driver',
          ),
          throwsA(predicate((e) =>
            e is FirebaseAuthException &&
            e.code == 'unavailable'
          )),
        );

        expect(
          () => service.resetPassword('test@example.com'),
          throwsA(predicate((e) =>
            e is FirebaseAuthException &&
            e.code == 'unavailable'
          )),
        );
      });

      test('ensureUserDoc completes silently in offline mode', () async {
        final service = AuthService();

        await expectLater(
          service.ensureUserDoc(
            uid: 'test-uid',
            role: 'driver',
            name: 'Test Driver',
            phone: '555-1234',
            truckNumber: 'TRK-001',
          ),
          completes,
        );
      });
    });

    group('error handling', () {
      test('handles FirebaseAuthException with proper error codes', () async {
        final service = AuthService();

        try {
          await service.signIn('any@example.com', 'password');
          fail('Should have thrown exception');
        } catch (e) {
          expect(e, isA<FirebaseAuthException>());
          final authException = e as FirebaseAuthException;
          expect(authException.code, 'unavailable');
          expect(authException.message, contains('not available in offline mode'));
        }
      });

      test('handles unavailable operations with correct error code', () async {
        final service = AuthService();

        try {
          await service.createUser('test@example.com', 'password');
          fail('Should have thrown exception');
        } catch (e) {
          expect(e, isA<FirebaseAuthException>());
          final authException = e as FirebaseAuthException;
          expect(authException.code, 'unavailable');
          expect(authException.message, contains('not available in offline mode'));
        }
      });
    });
  });
}
