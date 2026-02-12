## Problem

The "My Expenses" screen shows "Authentication required" error for **drivers**, even when they are logged in with Firebase Auth.

## Root Cause

`lib/screens/driver/driver_expenses_screen.dart` was using `MockDataService` to get the current user ID:

```dart
final mockService = MockDataService();
final currentUserId = mockService.currentUserId;  // Always returns null!
```

**Why this doesn't work:**
- MockDataService is designed for offline testing only
- It throws an exception when `signIn()` is called
- The `_currentUserId` property is never initialized
- Your app uses Firebase Auth for real authentication, not MockDataService

## Solution

Replace MockDataService with Firebase Auth:

**Changes:**
- ✅ Removed `import '../../services/mock_data_service.dart';`
- ✅ Added `import 'package:firebase_auth/firebase_auth.dart';`
- ✅ Changed authentication check from `mockService.currentUserId` to `FirebaseAuth.instance.currentUser?.uid`

**Modified code (lines 13-14):**
```dart
// Before:
final mockService = MockDataService();
final currentUserId = mockService.currentUserId;

// After:
final currentUser = FirebaseAuth.instance.currentUser;
final currentUserId = currentUser?.uid;
```

## Testing

✅ **Tested:**
- Driver can now access "My Expenses" without authentication error
- Expenses load correctly for authenticated drivers
- Admin expenses functionality unchanged (already uses Firebase Auth)

## Impact

- **Fixes:** Driver expenses authentication error
- **No breaking changes:** Admin functionality unaffected
- **Consistency:** All screens now use Firebase Auth

## Files Changed

- `lib/screens/driver/driver_expenses_screen.dart` (3 lines modified)

---

Fixes: Driver authentication error on expenses screen