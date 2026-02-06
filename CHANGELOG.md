# Changelog

All notable changes to the GUD Express app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-02-06

### Added - Production Readiness Features

#### Service Initialization
- **AnalyticsService**: Comprehensive analytics wrapper for Firebase Analytics
  - Screen view tracking
  - Event logging with parameters
  - User property management
  - Pre-built methods for common events (login, search, select content)

- **OfflineSupportService**: Offline mode management
  - Network connectivity detection
  - Local data caching with SharedPreferences
  - Operation queuing for later sync
  - Offline mode toggle

- **SyncService**: Background synchronization
  - Periodic sync of queued operations (every 5 minutes)
  - Conflict resolution
  - Manual force sync capability
  - Integration with OfflineSupportService

- **Service initialization in main.dart**:
  - All services initialized on app startup in dependency order
  - Comprehensive error handling with graceful degradation
  - Environment configuration loading
  - Enhanced global error handling for Flutter and async errors

#### Email Verification
- **EmailVerificationScreen**: Dedicated screen for email verification
  - Auto-checking verification status every 3 seconds
  - Resend verification email with 60-second cooldown
  - Clear instructions and user-friendly UI
  - Integration with analytics

- **EmailVerificationBanner**: Persistent banner widget
  - Shows warning for unverified users
  - Quick resend and refresh actions
  - Auto-hides when email is verified

- **AuthWrapper**: Authentication flow management
  - Checks authentication state
  - Enforces email verification before app access
  - Routes users to appropriate screens based on role
  - Error handling for role fetching failures

- **AuthService enhancements**:
  - Added `reloadUser()` method for checking verification status

#### Search and Filter UI
- **Admin Home Screen**:
  - Full-text search across load number, driver ID, pickup/delivery locations
  - Status filter chips (All, Assigned, In Transit, Delivered)
  - Debounced search (300ms) to reduce excessive queries
  - Empty state handling with clear filters button
  - Enhanced load cards with status badges and better formatting
  - Analytics tracking for search and filter usage

- **Driver Home Screen**:
  - Search functionality for load number and locations
  - Status filter chips for quick filtering
  - Enhanced load cards with color-coded status indicators
  - Empty state handling
  - Analytics tracking for interactions
  - Location update analytics

#### Analytics Integration
- **Login Screen**:
  - Screen view tracking
  - Login success/failure events
  - User role tracking
  - User ID and properties setup

- **Home Screens**:
  - Screen view tracking
  - Search query logging
  - Filter usage tracking
  - Content selection tracking
  - Location update tracking

#### Environment Configuration
- Environment variable loading in main.dart
- Integration with EnvironmentConfig service
- Graceful handling of missing .env file

### Changed
- **Version**: Updated from 2.0.0 to 2.1.0
- **App.dart**: Replaced direct LoginScreen with AuthWrapper
- **Admin Home**: Converted from StatelessWidget to StatefulWidget for search/filter state
- **Driver Home**: Enhanced with search, filter, and analytics
- **Login Screen**: Enhanced with analytics and user property tracking

### Technical Improvements
- Better error handling throughout the app
- Consistent analytics tracking patterns
- Improved UI/UX with search and filter capabilities
- Enhanced accessibility with semantic labels
- Better state management for search and filters

## [2.0.0] - 2026-02-05

### Initial Production Release
- Complete Firebase integration
- Admin and Driver dashboards
- Load management system
- GPS location tracking
- Proof of delivery upload
- Expense tracking
- Statistics and reporting
- 213+ automated tests
- Complete CI/CD pipeline
- Comprehensive documentation

---

## Release Notes

### Upgrading to 2.1.0

1. **New Services**: The app now initializes several new services on startup. These services are designed to fail gracefully if there are issues, so the app will still function even if some services can't initialize.

2. **Email Verification**: Users will now be required to verify their email addresses before accessing the app. Existing users with unverified emails will see the verification screen on next login.

3. **Search and Filter**: Both admin and driver screens now have search and filter capabilities. This uses in-memory filtering of streamed data, so no backend changes are required.

4. **Analytics**: The app now tracks user interactions for analytics. Make sure Firebase Analytics is properly configured in your Firebase console.

### Migration Notes

- No database migrations required
- No breaking changes to existing APIs
- All changes are additive and backward compatible
- Existing tests should continue to pass

### Known Issues

- None reported

### Future Enhancements (Planned for 2.2.0)
- Verification enforcement in FirestoreService for critical operations
- Load history screen with advanced filtering
- Enhanced notification system
- Real-time sync improvements
- Performance optimizations
