# Unit Tests for GUD Express Services

This directory contains comprehensive unit tests for the core services in the GUD Express Flutter app.

## Test Files

### 1. auth_service_test.dart
Tests for authentication service (`lib/services/auth_service.dart`):
- ✅ `signIn()` with valid credentials (admin and driver)
- ✅ `signIn()` with invalid credentials
- ✅ `signOut()` functionality
- ✅ `createUser()` method
- ✅ `register()` with all parameters
- ✅ `getUserRole()` retrieval
- ✅ `resetPassword()` functionality
- ✅ Offline mode scenarios
- ✅ `currentUser` getter
- ✅ `authStateChanges` stream
- ✅ Error handling for all operations

### 2. firestore_service_test.dart
Tests for Firestore service (`lib/services/firestore_service.dart`):
- ✅ `createDriver()` with required fields
- ✅ `streamDrivers()` stream functionality
- ✅ `updateDriver()` with partial updates
- ✅ `getDriver()` retrieval
- ✅ `updateDriverStats()` for earnings tracking
- ✅ `updateDriverLocation()` GPS updates
- ✅ `createLoad()` with required and optional fields
- ✅ `streamAllLoads()` stream
- ✅ `streamDriverLoads()` filtered stream
- ✅ `getLoad()` retrieval
- ✅ `updateLoadStatus()` with timestamps
- ✅ `startTrip()` and `endTrip()` methods
- ✅ `getDriverCompletedLoads()` counter
- ✅ `streamDashboardStats()` aggregation
- ✅ `deleteLoad()` with cascading deletes
- ✅ `addPod()` with optional notes
- ✅ `streamPods()` for a load
- ✅ `deletePod()` removal
- ✅ `getDriverEarnings()` calculation
- ✅ `streamDriverEarnings()` stream
- ✅ `generateLoadNumber()` sequential IDs
- ✅ `getUserRole()` retrieval
- ✅ Data validation tests
- ✅ Error scenario handling
- ✅ Stream type validation

### 3. storage_service_test.dart
Tests for storage service (`lib/services/storage_service.dart`):
- ✅ `pickImage()` from camera
- ✅ `pickImage()` from gallery
- ✅ User cancellation handling
- ✅ Image quality settings validation
- ✅ `uploadPodImage()` with file upload
- ✅ Storage path generation
- ✅ Unique filename with timestamp
- ✅ Upload failure handling
- ✅ `deletePOD()` file removal
- ✅ Invalid URL handling
- ✅ Missing file handling
- ✅ Silent error handling
- ✅ Integration scenarios
- ✅ File validation tests
- ✅ ImageSource parameter tests
- ✅ Storage path format tests
- ✅ Concurrent operations

## Running the Tests

### Run all unit tests:
```bash
flutter test test/unit/
```

### Run specific test file:
```bash
flutter test test/unit/auth_service_test.dart
flutter test test/unit/firestore_service_test.dart
flutter test test/unit/storage_service_test.dart
```

### Run with coverage:
```bash
flutter test --coverage test/unit/
```

### Generate coverage report:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Mock Files

The tests use Mockito for mocking Firebase dependencies. Mock files are generated:
- `auth_service_test.mocks.dart` - Mocks for FirebaseAuth and Firestore
- `firestore_service_test.mocks.dart` - Mocks for Firestore operations
- `storage_service_test.mocks.dart` - Mocks for Firebase Storage and ImagePicker

To regenerate mocks after changing test annotations:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Test Structure

Each test file follows this structure:
1. **Imports** - Test framework, mocks, and service under test
2. **Mock generation annotations** - `@GenerateMocks` for Mockito
3. **setUp()** - Initialize mocks before each test
4. **Test groups** - Organized by method/functionality
5. **Assertions** - Verify expected behavior

## Testing Philosophy

These tests focus on:
- **Offline mode behavior** - Since Firebase isn't initialized in tests
- **Method signatures** - Ensuring correct parameters
- **Stream types** - Validating return types
- **Error handling** - Testing exception cases
- **Data validation** - Ensuring data integrity

Note: Due to the nature of Firebase services using static instances, these tests primarily validate:
1. The service can be instantiated
2. Methods can be called with correct parameters
3. Offline mode behavior works as expected
4. Stream types are correct
5. Error handling is appropriate

For full integration tests with real Firebase operations, see `test/integration/`.

## Dependencies

Required test dependencies (already in `pubspec.yaml`):
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

## Notes

- Tests are designed to run in CI/CD environments
- Mock files are included in the repository
- Tests focus on offline behavior since Firebase isn't available in test environment
- For testing with real Firebase, consider using `fake_cloud_firestore` and `firebase_auth_mocks` packages
- All tests follow Flutter testing best practices
- Tests use the same style as existing model tests for consistency

## Future Improvements

Potential enhancements:
1. Add `fake_cloud_firestore` for more realistic Firestore testing
2. Add `firebase_auth_mocks` for better auth testing
3. Add more edge case tests
4. Add performance tests
5. Add integration tests with real Firebase emulators
