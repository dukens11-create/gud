# GUD Express Testing Guide

**Last Updated:** 2026-02-06

This guide covers both **automated testing** and **manual testing** procedures for the GUD Express app.

---

## 🧪 Automated Testing

The GUD Express app includes a comprehensive automated testing suite with **213+ tests** covering:
- **Unit Tests**: Service layer logic (130+ tests)
- **Widget Tests**: UI components and interactions (60+ tests)  
- **Integration Tests**: End-to-end user flows (23+ tests)

### Quick Start - Running Automated Tests

```bash
# Run all tests (unit + widget + model tests)
flutter test

# Run integration tests
flutter test integration_test

# Run with coverage report
flutter test --coverage

# Run specific test category
flutter test test/unit/          # Unit tests only
flutter test test/widget/        # Widget tests only
flutter test integration_test/   # Integration tests only
```

### Test Coverage

- **Overall Coverage:** ~93%
- **Services (Unit):** 95%
- **Screens (Widget):** 90%
- **Critical Flows (Integration):** 100%

**📖 For complete automated testing documentation, see:**
- **[test/README.md](test/README.md)** - Comprehensive test documentation
- **[test/unit/README.md](test/unit/README.md)** - Unit test details
- **[test/widget/README.md](test/widget/README.md)** - Widget test details
- **[integration_test/README.md](integration_test/README.md)** - Integration test details

---

## 📱 Manual Testing Guide

### Prerequisites

Before manual testing, ensure:
1. Firebase project is created and configured (see FIREBASE_SETUP.md)
2. `google-services.json` is placed in `android/app/`
3. Firebase Authentication, Firestore, and Storage are enabled
4. Security rules are deployed
5. At least one admin user is created

## Build Verification

### Option 1: Using Flutter CLI

```bash
# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Build for Android
flutter build apk

# Or run on connected device/emulator
flutter run
```

### Option 2: Using Android Studio

1. Open the project in Android Studio
2. Click **File** → **Sync Project with Gradle Files**
3. Wait for sync to complete
4. Click the **Run** button or press Shift+F10

## Expected Build Output

The application should build successfully with:
- ✅ No compilation errors
- ✅ All dependencies resolved
- ✅ Firebase services initialized
- ✅ All imports valid

## Functional Testing

### Test 1: Authentication Flow

#### 1.1 Admin Login
1. Launch the app
2. You should see the login screen with email/password fields
3. Enter admin credentials created in Firebase setup
4. Tap **Sign In**
5. **Expected**: Navigate to Admin Dashboard

#### 1.2 Driver Login
1. Log out from admin account
2. Enter driver credentials
3. Tap **Sign In**
4. **Expected**: Navigate to Driver Dashboard

#### 1.3 Invalid Login
1. Enter invalid credentials
2. Tap **Sign In**
3. **Expected**: Error message displayed

### Test 2: Admin Functionality

#### 2.1 View Loads
1. Log in as admin
2. **Expected**: See list of all loads or "No loads yet" message
3. **Expected**: Each load shows load number, driver ID, status, and rate

#### 2.2 Create Driver
1. Tap the **People icon** (bottom-right)
2. Fill in the form:
   - Email: driver1@test.com
   - Password: test1234
   - Name: John Doe
   - Phone: +1234567890
   - Truck Number: TRK-001
3. Tap **Create Driver**
4. **Expected**: "Driver created successfully" message
5. **Expected**: Driver appears in the list below

#### 2.3 Create Load
1. Tap the **Plus icon** (bottom-right)
2. Fill in the form:
   - Load Number: LOAD-001
   - Pickup Address: 123 Main St, Los Angeles, CA
   - Delivery Address: 456 Oak Ave, San Francisco, CA
   - Rate: 1500
   - Select a driver from dropdown
3. Tap **Create Load**
4. **Expected**: "Load created successfully" message
5. **Expected**: Navigate back to Admin Dashboard
6. **Expected**: New load appears in the list

### Test 3: Driver Functionality

#### 3.1 View My Loads
1. Log in as driver
2. **Expected**: See only loads assigned to this driver
3. **Expected**: Each load shows:
   - Load number
   - Pickup address
   - Delivery address
   - Rate
   - Status badge

#### 3.2 View Earnings
1. From Driver Dashboard, tap **Money icon** in app bar
2. **Expected**: Navigate to Earnings screen
3. **Expected**: Shows total earnings from delivered loads
4. **Expected**: Initial earnings = $0.00

### Test 4: Real-time Updates

#### 4.1 Admin Creates Load
1. Have two devices/emulators (or one device + browser)
2. Device 1: Log in as admin
3. Device 2: Log in as driver
4. On Device 1: Create a new load for the driver
5. **Expected**: Load appears on Device 2 immediately (real-time)

#### 4.2 Driver Count Updates
1. Device 1: Log in as admin, navigate to Manage Drivers
2. Device 2: Create a new driver account
3. **Expected**: New driver appears in Device 1's list immediately

### Test 5: Logout

1. From any screen, tap **Exit icon** in app bar
2. **Expected**: Navigate back to login screen
3. **Expected**: Cannot access protected screens without login

## Edge Cases & Error Handling

### Test 6: Network Issues

1. Turn off WiFi/Data
2. Try to log in
3. **Expected**: Appropriate error message
4. Turn on network
5. **Expected**: Can log in successfully

### Test 7: Empty States

1. Log in as admin with no loads
2. **Expected**: "No loads yet. Create your first load!" message
3. Navigate to Create Load with no drivers
4. **Expected**: "No drivers available. Create a driver first." message

### Test 8: Form Validation

1. Try to create driver with empty fields
2. **Expected**: "All fields are required" error
3. Try to create load with empty fields
4. **Expected**: "All fields are required" error
5. Try to create load with invalid rate (letters)
6. **Expected**: "Invalid rate amount" error

## Performance Testing

### Test 9: Large Data Sets

1. Create 50+ loads
2. **Expected**: Smooth scrolling in load list
3. **Expected**: Fast loading times
4. **Expected**: No UI lag

### Test 10: Concurrent Access

1. Have 3+ users accessing simultaneously
2. Create/update data from different accounts
3. **Expected**: All users see updates in real-time
4. **Expected**: No data conflicts or loss

## Security Testing

### Test 11: Role-Based Access

1. Log in as driver
2. Try to access `/admin` route manually
3. **Expected**: Cannot access admin screens
4. Log in as admin
5. Try to access driver-only features
6. **Expected**: Can access all features

### Test 12: Data Isolation

1. Create Load A for Driver 1
2. Create Load B for Driver 2
3. Log in as Driver 1
4. **Expected**: See only Load A, not Load B
5. Log in as Driver 2
6. **Expected**: See only Load B, not Load A

## Known Limitations

1. **No Firebase Config**: The app requires `google-services.json` which is not included in the repo for security reasons
2. **POD Upload Not Implemented**: POD model exists but UI for upload is not yet implemented
3. **Load Status Updates**: Drivers cannot update load status yet (future feature)
4. **No Offline Support**: App requires internet connection

## Success Criteria

✅ **Phase 1-6 Complete**: All code implemented
✅ **Dependencies Added**: Firebase packages in pubspec.yaml
✅ **Android Config**: Firebase configured in gradle files
✅ **Models Created**: 4 models with Firebase serialization
✅ **Services Created**: 3 services (Auth, Firestore, Storage)
✅ **Main App Updated**: Firebase initialization and auth flow
✅ **Screens Updated**: All screens use real Firebase data
✅ **Documentation**: FIREBASE_SETUP.md created

## Next Steps (Post-Testing)

1. **Fix any bugs** found during testing
2. **Add POD upload** functionality
3. **Add load status updates** for drivers
4. **Add trip tracking** (start/end trip)
5. **Add notifications**
6. **Add analytics**
7. **Add offline support**
8. **Deploy to stores**

## Troubleshooting

### Build Fails

```
Error: google-services.json missing
Solution: Follow FIREBASE_SETUP.md Step 3
```

```
Error: Firebase not initialized
Solution: Ensure main.dart has Firebase.initializeApp()
```

```
Error: Duplicate plugins
Solution: Run flutter clean && flutter pub get
```

### Runtime Issues

```
Error: User not authenticated
Solution: Ensure you're logged in before accessing protected screens
```

```
Error: Permission denied (Firestore)
Solution: Check security rules in Firebase Console
```

```
Error: No data showing
Solution: Create data first (drivers, loads) as admin
```

## Contact

For issues or questions, refer to:
- FIREBASE_SETUP.md for setup help
- ARCHITECTURE.md for code structure
- PROJECT_SUMMARY.md for project overview
