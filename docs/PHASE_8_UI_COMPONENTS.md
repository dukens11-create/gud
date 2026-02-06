# Phase 8 UI Components - Usage Guide

This guide explains how to use the new UI components created for Phase 8.

## 1. Offline Indicator

The `OfflineIndicator` widget displays a banner at the top of the screen when the app is offline, showing pending sync operations.

### Features
- ✅ Red banner when offline
- ✅ Yellow banner when syncing
- ✅ Auto-hides when back online (with fade-out animation)
- ✅ Shows pending operations count
- ✅ Tap to view detailed pending operations list
- ✅ Smooth animations using AnimatedContainer and FadeTransition

### Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:gud_app/services/offline_support_service.dart';
import 'package:gud_app/widgets/offline_indicator.dart';

class MyScreen extends StatelessWidget {
  final OfflineSupportService offlineService;

  const MyScreen({
    super.key,
    required this.offlineService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Add offline indicator at the top
          OfflineIndicator(offlineService: offlineService),
          
          // Your screen content
          Expanded(
            child: YourContent(),
          ),
        ],
      ),
    );
  }
}
```

### Integration with App

To integrate the offline indicator across all screens:

```dart
// In your app.dart or main layout
class AppLayout extends StatefulWidget {
  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  late OfflineSupportService _offlineService;

  @override
  void initState() {
    super.initState();
    _offlineService = OfflineSupportService();
    _offlineService.initialize();
  }

  @override
  void dispose() {
    _offlineService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OfflineIndicator(offlineService: _offlineService),
        Expanded(
          child: Navigator(
            // Your navigation logic
          ),
        ),
      ],
    );
  }
}
```

## 2. Enhanced Onboarding Screen

The onboarding screen has been enhanced with smooth animations, swipe gestures, and proper navigation flow.

### Features
- ✅ Smooth page transitions using PageView
- ✅ Swipe gestures (built-in with PageView)
- ✅ Skip button in top-right corner
- ✅ Animated dot indicators
- ✅ Page content animations (scale, fade, bounce effects)
- ✅ Stores completion flag in SharedPreferences
- ✅ Navigates to login screen after completion
- ✅ Role-specific content (admin vs driver)

### Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:gud_app/screens/onboarding_screen.dart';

// Show onboarding for a new user
class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final showOnboarding = await shouldShowOnboarding();
    
    if (showOnboarding) {
      // Show onboarding for new users
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(userRole: 'driver'),
        ),
      );
    } else {
      // Go directly to login for returning users
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

### Helper Functions

The onboarding screen provides utility functions:

```dart
// Check if onboarding should be shown
final shouldShow = await shouldShowOnboarding();

// Reset onboarding (for testing)
await resetOnboarding();
```

### Customization

The onboarding content is role-specific:
- **Admin role**: 4 pages covering fleet management, live tracking, notifications, and dashboard
- **Driver role**: 5 pages covering deliveries, GPS tracking, POD, and earnings

To show onboarding for different roles:

```dart
// For admin users
OnboardingScreen(userRole: 'admin')

// For driver users
OnboardingScreen(userRole: 'driver')
```

## Animation Details

### Offline Indicator Animations
1. **Fade In/Out**: FadeTransition with 300ms duration
2. **Color Change**: AnimatedContainer for smooth color transitions
3. **Icon Rotation**: AnimatedRotation for syncing spinner effect

### Onboarding Screen Animations
1. **Page Transitions**: Custom scale and opacity based on page position
2. **Icon Entrance**: TweenAnimationBuilder with elastic curve (600ms)
3. **Text Fade**: AnimatedOpacity for title (800ms) and description (1000ms)
4. **Dot Indicators**: AnimatedContainer with width changes (300ms)
5. **Button Text**: AnimatedSwitcher for smooth text changes (300ms)
6. **Screen Fade**: Overall fade controller for entrance/exit (500ms)

## Material Design Compliance

Both components follow Material Design principles:
- Proper elevation and shadows
- Standard Material colors and themes
- Appropriate touch targets (minimum 48dp)
- Smooth, natural animations
- Accessibility considerations

## Best Practices

1. **Offline Indicator**
   - Place at the top of the screen (SafeArea)
   - Don't duplicate across nested screens
   - Keep in a persistent layout component

2. **Onboarding Screen**
   - Show only once per user
   - Provide skip option for returning users
   - Keep content concise and visual
   - Use role-specific content when possible

## Testing

To test the components:

```dart
// Test offline indicator
final offlineService = OfflineSupportService();
await offlineService.initialize();

// Simulate offline mode
// (Toggle network in device/emulator settings)

// Test onboarding reset
await resetOnboarding();
// Restart app to see onboarding again
```

## Future Enhancements

Potential improvements for future versions:
- Add Lottie animations for onboarding illustrations
- Add permission requests during onboarding
- Add progress saving for onboarding
- Add localization support
- Add video tutorials
- Add interactive tutorial mode
