# GUD Express - Monitoring & Analytics Guide

**Last Updated:** 2026-02-06  
**Status:** Production Ready ✅

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Firebase Crashlytics](#firebase-crashlytics)
3. [Firebase Analytics](#firebase-analytics)
4. [Performance Monitoring](#performance-monitoring)
5. [Custom Metrics](#custom-metrics)
6. [Dashboards](#dashboards)
7. [Alerts & Notifications](#alerts--notifications)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

---

## Overview

The GUD Express app implements comprehensive monitoring and analytics using Firebase services:

### Monitoring Stack
- **🔥 Firebase Crashlytics** - Crash reporting and error tracking
- **📊 Firebase Analytics** - User behavior and event tracking
- **⚡ Firebase Performance** - App performance monitoring (ready to enable)
- **📈 Custom Metrics** - Business-specific analytics

### What We Monitor
- ✅ **Crashes & Errors**: All app crashes and non-fatal errors
- ✅ **User Events**: Authentication, load management, POD uploads
- ✅ **Screen Views**: Page navigation and user flows
- ✅ **Custom Events**: Business-specific actions
- 🔄 **Performance**: Network requests, screen render times (ready to enable)

---

## Firebase Crashlytics

### Implementation

Firebase Crashlytics is fully integrated and automatically captures:

1. **Fatal Crashes**: All uncaught exceptions that cause the app to crash
2. **Non-Fatal Errors**: Handled exceptions in critical functions
3. **Flutter Errors**: Widget build errors and async errors
4. **Stack Traces**: Full stack traces for debugging

### Configuration

Crashlytics is initialized in `lib/main.dart`:

```dart
// Capture Flutter framework errors
FlutterError.onError = (errorDetails) {
  FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
};

// Capture async errors
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

### Error Tracking in Services

Critical services log errors with context:

```dart
try {
  // Critical operation
  await _auth!.signInWithEmailAndPassword(email: email, password: password);
} catch (e, stackTrace) {
  // Log to Crashlytics with context
  await FirebaseCrashlytics.instance.recordError(
    e,
    stackTrace,
    reason: 'Sign in failed for email: $email',
    fatal: false,
  );
  rethrow;
}
```

### Custom Error Logging

To manually log errors in your code:

```dart
// Log non-fatal error
try {
  await riskyOperation();
} catch (e, stack) {
  await FirebaseCrashlytics.instance.recordError(
    e, 
    stack,
    reason: 'Failed to perform risky operation',
    fatal: false,
  );
}

// Log with custom keys for filtering
await FirebaseCrashlytics.instance.log('User attempted dangerous action');
await FirebaseCrashlytics.instance.setCustomKey('user_role', 'admin');
await FirebaseCrashlytics.instance.setCustomKey('load_count', 42);
```

### User Attribution

Set user identifiers for better crash tracking:

```dart
// Set user ID (do this after login)
await FirebaseCrashlytics.instance.setUserIdentifier(userId);

// Set custom attributes
await FirebaseCrashlytics.instance.setCustomKey('user_role', role);
await FirebaseCrashlytics.instance.setCustomKey('driver_id', driverId);
```

### Viewing Crash Reports

1. **Firebase Console** → **Crashlytics**
2. View dashboard showing:
   - Crash-free users percentage
   - Crash trends over time
   - Top crashes by occurrence
3. Click on crash to see:
   - Stack trace
   - Device information
   - Custom keys and logs
   - User path leading to crash

### Crash Report Filters

Filter crashes by:
- **Version**: Compare crash rates across versions
- **Device**: Identify problematic devices
- **OS Version**: Track OS-specific issues
- **Custom Keys**: Filter by role, feature, etc.

---

## Firebase Analytics

### Implementation

Firebase Analytics is initialized in `lib/main.dart`:

```dart
FirebaseAnalytics analytics = FirebaseAnalytics.instance;
await analytics.logAppOpen();
```

### Automatic Events

Firebase Analytics automatically tracks:
- ✅ **App Opens** (`app_open`)
- ✅ **First Opens** (`first_open`)
- ✅ **Session Start** (`session_start`)
- ✅ **User Engagement** (`user_engagement`)

### Custom Events

Log custom business events throughout the app:

#### Authentication Events

```dart
// User signed in
await FirebaseAnalytics.instance.logLogin(
  loginMethod: 'email',
);

// User signed up
await FirebaseAnalytics.instance.logSignUp(
  signUpMethod: 'email',
);

// User signed out
await FirebaseAnalytics.instance.logEvent(
  name: 'sign_out',
  parameters: {'user_role': role},
);
```

#### Load Management Events

```dart
// Load created
await FirebaseAnalytics.instance.logEvent(
  name: 'load_created',
  parameters: {
    'load_id': loadId,
    'driver_id': driverId,
    'rate': rate,
    'created_by': 'admin',
  },
);

// Load status updated
await FirebaseAnalytics.instance.logEvent(
  name: 'load_status_changed',
  parameters: {
    'load_id': loadId,
    'old_status': oldStatus,
    'new_status': newStatus,
  },
);

// Load completed
await FirebaseAnalytics.instance.logEvent(
  name: 'load_completed',
  parameters: {
    'load_id': loadId,
    'driver_id': driverId,
    'miles': miles,
    'earnings': rate,
  },
);
```

#### POD Upload Events

```dart
// POD uploaded
await FirebaseAnalytics.instance.logEvent(
  name: 'pod_uploaded',
  parameters: {
    'load_id': loadId,
    'has_notes': notes != null,
    'image_source': 'camera', // or 'gallery'
  },
);

// POD deleted
await FirebaseAnalytics.instance.logEvent(
  name: 'pod_deleted',
  parameters: {
    'load_id': loadId,
    'pod_id': podId,
  },
);
```

#### Screen View Events

```dart
// Track screen views
await FirebaseAnalytics.instance.logScreenView(
  screenName: 'DriverHomeScreen',
  screenClass: 'DriverHomeScreen',
);

await FirebaseAnalytics.instance.logScreenView(
  screenName: 'AdminDashboard',
  screenClass: 'AdminHomeScreen',
);
```

### User Properties

Set user properties for segmentation:

```dart
// Set user properties after login
await FirebaseAnalytics.instance.setUserProperty(
  name: 'user_role',
  value: role, // 'admin' or 'driver'
);

await FirebaseAnalytics.instance.setUserProperty(
  name: 'user_type',
  value: 'premium', // or 'standard'
);

// For drivers
await FirebaseAnalytics.instance.setUserProperty(
  name: 'truck_number',
  value: truckNumber,
);
```

### Viewing Analytics

1. **Firebase Console** → **Analytics**
2. Access dashboards:
   - **Overview**: Active users, engagement, retention
   - **Events**: Event counts and parameters
   - **Conversions**: Conversion funnels
   - **Audiences**: User segments
   - **User Properties**: Property distributions

### Key Metrics to Monitor

| Metric | Description | Good Target |
|--------|-------------|-------------|
| **Daily Active Users (DAU)** | Unique users per day | Growing trend |
| **Session Duration** | Average session length | 5-10 minutes |
| **Screens per Session** | Pages viewed per session | 8-12 screens |
| **Retention (Day 1)** | Users returning next day | >40% |
| **Retention (Day 7)** | Users returning after 7 days | >20% |
| **Crash-Free Users** | Users without crashes | >99.5% |

---

## Performance Monitoring

### Setup (Ready to Enable)

Firebase Performance Monitoring is included in the dependencies but not yet initialized. To enable:

```dart
// In lib/main.dart
import 'package:firebase_performance/firebase_performance.dart';

// After Firebase.initializeApp()
FirebasePerformance performance = FirebasePerformance.instance;
print('✅ Firebase Performance Monitoring initialized');
```

### What It Tracks

Once enabled, Performance Monitoring automatically tracks:
- ✅ **App Start Time**: Time from launch to first render
- ✅ **Network Requests**: HTTP request duration and success rate
- ✅ **Screen Rendering**: Frame rendering times

### Custom Traces

Add custom performance traces for critical operations:

```dart
// Start trace
final Trace trace = FirebasePerformance.instance.newTrace('load_creation');
await trace.start();

// Add attributes
trace.putAttribute('user_role', 'admin');

// Perform operation
await createLoad(...);

// Add metrics
trace.setMetric('loads_created', 1);

// Stop trace
await trace.stop();
```

### Common Traces to Add

```dart
// Authentication trace
final authTrace = FirebasePerformance.instance.newTrace('authentication');

// Load list fetch trace
final loadListTrace = FirebasePerformance.instance.newTrace('fetch_loads');

// POD upload trace
final podUploadTrace = FirebasePerformance.instance.newTrace('pod_upload');

// Image processing trace
final imageTrace = FirebasePerformance.instance.newTrace('image_processing');
```

---

## Custom Metrics

### Business Metrics

Track business-specific KPIs:

```dart
// Track earnings
await FirebaseAnalytics.instance.logEvent(
  name: 'earnings_updated',
  parameters: {
    'driver_id': driverId,
    'total_earnings': totalEarnings,
    'loads_completed': completedLoads,
  },
);

// Track expenses
await FirebaseAnalytics.instance.logEvent(
  name: 'expense_added',
  parameters: {
    'load_id': loadId,
    'expense_type': type,
    'amount': amount,
  },
);

// Track location updates
await FirebaseAnalytics.instance.logEvent(
  name: 'location_shared',
  parameters: {
    'driver_id': driverId,
    'accuracy': accuracy,
    'method': 'manual', // or 'automatic'
  },
);
```

### Conversion Funnels

Track user journeys:

```dart
// Step 1: Load assigned
await FirebaseAnalytics.instance.logEvent(
  name: 'funnel_load_assigned',
  parameters: {'load_id': loadId},
);

// Step 2: Load accepted
await FirebaseAnalytics.instance.logEvent(
  name: 'funnel_load_accepted',
  parameters: {'load_id': loadId},
);

// Step 3: Trip started
await FirebaseAnalytics.instance.logEvent(
  name: 'funnel_trip_started',
  parameters: {'load_id': loadId},
);

// Step 4: POD uploaded
await FirebaseAnalytics.instance.logEvent(
  name: 'funnel_pod_uploaded',
  parameters: {'load_id': loadId},
);

// Step 5: Load completed
await FirebaseAnalytics.instance.logEvent(
  name: 'funnel_load_completed',
  parameters: {'load_id': loadId},
);
```

---

## Dashboards

### Firebase Console Dashboards

Access all monitoring data in Firebase Console:

1. **Crashlytics Dashboard**
   - URL: `https://console.firebase.google.com/project/[PROJECT_ID]/crashlytics`
   - Shows: Crash trends, top crashes, affected users

2. **Analytics Dashboard**
   - URL: `https://console.firebase.google.com/project/[PROJECT_ID]/analytics`
   - Shows: User metrics, event analytics, conversions

3. **Performance Dashboard**
   - URL: `https://console.firebase.google.com/project/[PROJECT_ID]/performance`
   - Shows: App startup, network requests, custom traces

### Custom Reports

Create custom reports in Analytics:

1. Navigate to **Analytics** → **Custom Reports**
2. Click **Create Custom Report**
3. Select metrics and dimensions
4. Save and share with team

### Example Reports

**Load Completion Rate Report**:
- Event: `load_completed`
- Dimension: `user_role`
- Metric: Event count
- Timeframe: Last 30 days

**Driver Performance Report**:
- Event: `load_completed`
- Dimension: `driver_id`
- Metrics: Event count, `earnings`, `miles`
- Timeframe: Last 7 days

---

## Alerts & Notifications

### Crashlytics Alerts

Set up alerts for critical crashes:

1. **Firebase Console** → **Crashlytics** → **Settings**
2. Enable **Email Alerts**
3. Set thresholds:
   - Alert when crash-free users drops below 99%
   - Alert on new crash types
   - Daily digest of crash trends

### Analytics Alerts

Configure custom alerts in Analytics:

1. **Firebase Console** → **Analytics** → **Custom Alerts**
2. Create alerts for:
   - Sudden drop in active users
   - Spike in error events
   - Conversion rate changes

### Integration with External Services

Forward alerts to:
- **Slack**: Use Zapier or Cloud Functions
- **PagerDuty**: For critical production issues
- **Email**: Team distribution lists
- **SMS**: For urgent crashes

---

## Best Practices

### Error Logging

✅ **DO**:
- Log errors with meaningful context
- Include user actions leading to error
- Set custom keys for filtering
- Log non-fatal errors for debugging
- Use appropriate error severity

❌ **DON'T**:
- Log sensitive user data (passwords, tokens)
- Log expected errors (like network timeouts)
- Spam logs with too much detail
- Log in tight loops (impacts performance)

### Analytics Events

✅ **DO**:
- Use standard event names when possible
- Keep parameter names consistent
- Limit parameters to 25 per event
- Use snake_case for event names
- Track user flows and conversions

❌ **DON'T**:
- Create too many unique events (limits: 500)
- Use overly generic names (`action`, `click`)
- Include PII in event parameters
- Log events in tight loops
- Use special characters in names

### Performance

✅ **DO**:
- Use traces for operations >1 second
- Add attributes for filtering
- Use appropriate trace names
- Monitor critical user paths
- Review performance regularly

❌ **DON'T**:
- Create traces for trivial operations
- Start traces without stopping them
- Nest traces too deeply
- Create too many unique traces

---

## Troubleshooting

### Crashes Not Appearing

**Problem**: Crashes not showing in Crashlytics dashboard

**Solutions**:
1. Verify Firebase configuration (google-services.json)
2. Check Crashlytics is initialized in main.dart
3. Ensure app has internet connection
4. Wait 5-10 minutes for data to appear
5. Check Firebase Console for errors

```bash
# Check Android logs
adb logcat | grep -i crashlytics

# Check iOS logs
xcrun simctl spawn booted log stream --predicate 'subsystem contains "firebase"'
```

### Analytics Events Not Recording

**Problem**: Custom events not appearing in Analytics

**Solutions**:
1. Wait 24 hours for events to process
2. Use DebugView for real-time testing
3. Verify event name length (<40 chars)
4. Check parameter count (<25 per event)
5. Verify Firebase Analytics is initialized

### Enable DebugView

**Android**:
```bash
adb shell setprop debug.firebase.analytics.app com.gud.express
```

**iOS**:
Add to Xcode scheme: `-FIRDebugEnabled`

### Performance Data Missing

**Problem**: Performance metrics not showing

**Solutions**:
1. Verify Performance Monitoring is initialized
2. Wait 12-24 hours for initial data
3. Check network connectivity
4. Verify app has required permissions
5. Review Firebase Console logs

### Common Errors

#### "Firebase app not initialized"
```dart
// Solution: Ensure Firebase.initializeApp() is called first
await Firebase.initializeApp();
```

#### "Crashlytics not collecting crashes"
```dart
// Solution: Verify error handlers are set up
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

#### "Analytics events not logging"
```dart
// Solution: Check Firebase is initialized and app has network
await Firebase.initializeApp();
await FirebaseAnalytics.instance.logAppOpen();
```

---

## Testing Monitoring

### Test Crash Reporting

Force a test crash:

```dart
// Add a test button in debug mode
ElevatedButton(
  onPressed: () {
    FirebaseCrashlytics.instance.crash(); // Causes fatal crash
  },
  child: Text('Test Crash'),
);
```

Or test non-fatal error:

```dart
try {
  throw Exception('Test exception');
} catch (e, stack) {
  await FirebaseCrashlytics.instance.recordError(
    e,
    stack,
    reason: 'Testing crash reporting',
    fatal: false,
  );
}
```

### Test Analytics

Use DebugView to see events in real-time:

1. Enable DebugView (see above)
2. Run app on device/emulator
3. Open **Firebase Console** → **Analytics** → **DebugView**
4. Perform actions in app
5. See events appear instantly

### Test Performance

Add test traces in debug mode:

```dart
final trace = FirebasePerformance.instance.newTrace('test_operation');
await trace.start();
await Future.delayed(Duration(seconds: 2)); // Simulate work
await trace.stop();
```

Check Performance dashboard after 5-10 minutes.

---

## Production Checklist

Before going to production:

- [ ] Firebase Crashlytics initialized in main.dart
- [ ] Firebase Analytics initialized in main.dart
- [ ] Error handlers configured for Flutter errors
- [ ] Critical services log errors with context
- [ ] Custom events logged for key user actions
- [ ] User properties set after authentication
- [ ] Screen views tracked for navigation
- [ ] Performance traces added for slow operations (optional)
- [ ] Alerts configured for critical issues
- [ ] Team has access to Firebase Console
- [ ] DebugView disabled in production build
- [ ] Tested crash reporting with test crash
- [ ] Verified analytics events appear in console

---

## Additional Resources

### Documentation
- [Firebase Crashlytics Docs](https://firebase.google.com/docs/crashlytics)
- [Firebase Analytics Docs](https://firebase.google.com/docs/analytics)
- [Firebase Performance Docs](https://firebase.google.com/docs/perf-mon)

### Internal Docs
- [Production Features Guide](../PRODUCTION_FEATURES_GUIDE.md)
- [Firebase Setup Guide](../FIREBASE_SETUP.md)
- [Testing Guide](../TESTING_GUIDE.md)

### Support
- Firebase Console for dashboards
- Stack Overflow for common issues
- Firebase Support for critical problems

---

## Summary

✅ **Firebase Crashlytics** - Fully integrated and capturing all crashes  
✅ **Firebase Analytics** - Initialized and tracking user events  
✅ **Error Tracking** - Critical services log errors with context  
🔄 **Performance Monitoring** - Ready to enable with simple initialization  
📊 **Custom Events** - Examples provided for all key features  
🔔 **Alerts** - Can be configured in Firebase Console  

The GUD Express app has production-ready monitoring and analytics that provide:
- Real-time crash detection and alerting
- Comprehensive user behavior tracking
- Performance monitoring capabilities
- Business metrics and KPIs
- Debugging tools for production issues

**Next Steps**: Monitor dashboards regularly, set up alerts, and add custom events as needed for your specific business requirements.

---

**Need Help?**  
- Review Firebase Console documentation
- Check troubleshooting section above
- Test using DebugView for real-time verification
- Contact Firebase Support for critical issues

**Happy Monitoring! 📊**
