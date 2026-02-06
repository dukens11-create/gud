# Firebase Remote Config Setup Guide

## Overview

Firebase Remote Config allows you to dynamically control app behavior and features without requiring an app update. GUD Express uses Remote Config for feature flags, location settings, geofence configuration, and app control.

## Prerequisites

1. Firebase project configured for your app
2. Remote Config enabled in Firebase Console
3. Appropriate permissions to manage Remote Config

## Configuration Parameters

### Feature Flags

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enable_biometric_auth` | Boolean | `true` | Enable/disable biometric authentication (fingerprint, face ID) |
| `enable_geofencing` | Boolean | `true` | Enable/disable geofence monitoring for pickup/delivery locations |
| `enable_offline_mode` | Boolean | `true` | Enable/disable offline data synchronization |
| `enable_analytics` | Boolean | `true` | Enable/disable Firebase Analytics tracking |
| `enable_crashlytics` | Boolean | `true` | Enable/disable crash reporting |
| `enable_push_notifications` | Boolean | `true` | Enable/disable push notifications |

### Location Settings

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location_update_interval_minutes` | Number | `5` | How often to update driver location (in minutes) |
| `location_accuracy_threshold_meters` | Number | `50.0` | Minimum acceptable GPS accuracy (in meters) |
| `enable_background_location` | Boolean | `true` | Enable/disable background location tracking |

### Geofence Settings

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `geofence_radius_meters` | Number | `200.0` | Radius of geofences around pickup/delivery locations (in meters) |
| `geofence_monitoring_interval_seconds` | Number | `30` | How often to check geofence status (in seconds) |
| `geofence_loitering_delay_ms` | Number | `60000` | Time to wait before triggering geofence event (in milliseconds) |

### App Control

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `maintenance_mode` | Boolean | `false` | Put app in maintenance mode (prevents access) |
| `maintenance_message` | String | "The app is currently under maintenance. Please check back later." | Message to show during maintenance |
| `force_update_required` | Boolean | `false` | Force users to update to newer version |
| `minimum_app_version` | String | "2.0.0" | Minimum required app version |

### Notification Settings

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `notification_priority` | String | "high" | Priority for push notifications (low, default, high) |
| `enable_notification_sound` | Boolean | `true` | Enable/disable notification sounds |

### Performance Settings

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `max_cache_size_mb` | Number | `100` | Maximum cache size in megabytes |
| `image_cache_days` | Number | `7` | How long to cache images (in days) |

### Business Logic

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `max_loads_per_driver` | Number | `5` | Maximum simultaneous loads per driver |
| `pod_upload_required` | Boolean | `true` | Require proof of delivery upload |
| `auto_calculate_earnings` | Boolean | `true` | Automatically calculate driver earnings on delivery |

## Firebase Console Setup

### Step 1: Navigate to Remote Config

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your GUD Express project
3. Navigate to **Engage** → **Remote Config** in the left sidebar

### Step 2: Add Parameters Manually

For each parameter listed above:

1. Click **Add parameter**
2. Enter the **Parameter key** (exact name from table above)
3. Set the **Default value** from the table
4. Add a **Description** (copy from table above)
5. Click **Save**

### Step 3: Publish Changes

1. Review all parameters
2. Click **Publish changes**
3. Confirm the publication

## Batch Import (Recommended)

Instead of adding parameters manually, you can import them all at once using the JSON template below.

### Step 1: Download Template

Save the following JSON as `remote_config_template.json`:

```json
{
  "parameters": {
    "enable_biometric_auth": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Enable/disable biometric authentication (fingerprint, face ID)",
      "valueType": "BOOLEAN"
    },
    "enable_geofencing": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Enable/disable geofence monitoring for pickup/delivery locations",
      "valueType": "BOOLEAN"
    },
    "enable_offline_mode": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Enable/disable offline data synchronization",
      "valueType": "BOOLEAN"
    },
    "enable_analytics": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Enable/disable Firebase Analytics tracking",
      "valueType": "BOOLEAN"
    },
    "enable_crashlytics": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Enable/disable crash reporting",
      "valueType": "BOOLEAN"
    },
    "enable_push_notifications": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Enable/disable push notifications",
      "valueType": "BOOLEAN"
    },
    "location_update_interval_minutes": {
      "defaultValue": {
        "value": "5"
      },
      "description": "How often to update driver location (in minutes)",
      "valueType": "NUMBER"
    },
    "location_accuracy_threshold_meters": {
      "defaultValue": {
        "value": "50.0"
      },
      "description": "Minimum acceptable GPS accuracy (in meters)",
      "valueType": "NUMBER"
    },
    "enable_background_location": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Enable/disable background location tracking",
      "valueType": "BOOLEAN"
    },
    "geofence_radius_meters": {
      "defaultValue": {
        "value": "200.0"
      },
      "description": "Radius of geofences around pickup/delivery locations (in meters)",
      "valueType": "NUMBER"
    },
    "geofence_monitoring_interval_seconds": {
      "defaultValue": {
        "value": "30"
      },
      "description": "How often to check geofence status (in seconds)",
      "valueType": "NUMBER"
    },
    "geofence_loitering_delay_ms": {
      "defaultValue": {
        "value": "60000"
      },
      "description": "Time to wait before triggering geofence event (in milliseconds)",
      "valueType": "NUMBER"
    },
    "maintenance_mode": {
      "defaultValue": {
        "value": "false"
      },
      "description": "Put app in maintenance mode (prevents access)",
      "valueType": "BOOLEAN"
    },
    "maintenance_message": {
      "defaultValue": {
        "value": "The app is currently under maintenance. Please check back later."
      },
      "description": "Message to show during maintenance",
      "valueType": "STRING"
    },
    "force_update_required": {
      "defaultValue": {
        "value": "false"
      },
      "description": "Force users to update to newer version",
      "valueType": "BOOLEAN"
    },
    "minimum_app_version": {
      "defaultValue": {
        "value": "2.0.0"
      },
      "description": "Minimum required app version",
      "valueType": "STRING"
    },
    "notification_priority": {
      "defaultValue": {
        "value": "high"
      },
      "description": "Priority for push notifications (low, default, high)",
      "valueType": "STRING"
    },
    "enable_notification_sound": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Enable/disable notification sounds",
      "valueType": "BOOLEAN"
    },
    "max_cache_size_mb": {
      "defaultValue": {
        "value": "100"
      },
      "description": "Maximum cache size in megabytes",
      "valueType": "NUMBER"
    },
    "image_cache_days": {
      "defaultValue": {
        "value": "7"
      },
      "description": "How long to cache images (in days)",
      "valueType": "NUMBER"
    },
    "max_loads_per_driver": {
      "defaultValue": {
        "value": "5"
      },
      "description": "Maximum simultaneous loads per driver",
      "valueType": "NUMBER"
    },
    "pod_upload_required": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Require proof of delivery upload",
      "valueType": "BOOLEAN"
    },
    "auto_calculate_earnings": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Automatically calculate driver earnings on delivery",
      "valueType": "BOOLEAN"
    }
  },
  "version": {
    "versionNumber": "1",
    "updateTime": "2024-01-01T00:00:00Z",
    "updateUser": {
      "email": "admin@gudexpress.com"
    },
    "description": "Initial GUD Express Remote Config setup"
  }
}
```

### Step 2: Import via Firebase CLI

```bash
# Make sure you're logged in
firebase login

# Set your project
firebase use YOUR_PROJECT_ID

# Import the config
firebase remoteconfig:get > backup.json  # Backup existing config (optional)
firebase deploy --only remoteconfig
```

### Step 3: Import via Console

1. Go to **Remote Config** in Firebase Console
2. Click the **⋮** menu (three dots)
3. Select **Publish from file**
4. Upload `remote_config_template.json`
5. Review changes
6. Click **Publish**

## Testing Remote Config

### Test in Development

The app automatically uses shorter fetch intervals (1 minute) in debug mode:

```dart
// In lib/services/remote_config_service.dart
minimumFetchInterval: kDebugMode 
    ? const Duration(minutes: 1)  // Short interval for testing
    : const Duration(hours: 1);   // Production interval
```

### Force Refresh in App

To test config changes immediately:

1. Open the app
2. Navigate to Settings/Debug menu (if available)
3. Use the force refresh method:

```dart
await RemoteConfigService().forceRefresh();
```

### View Current Values

Use the debug method to see all current values:

```dart
final values = RemoteConfigService().getAllValues();
print(values);
```

## Common Use Cases

### 1. Emergency Maintenance

To put the app in maintenance mode:

1. Go to Remote Config
2. Set `maintenance_mode` to `true`
3. Update `maintenance_message` if needed
4. Publish changes
5. Users will see maintenance screen on next app launch

### 2. Force Update

To require users update to a newer version:

1. Set `force_update_required` to `true`
2. Set `minimum_app_version` to minimum required version (e.g., "2.1.0")
3. Publish changes

### 3. Disable Feature Remotely

To disable a problematic feature:

1. Set the feature flag to `false` (e.g., `enable_geofencing`)
2. Publish changes
3. Feature will be disabled on next config fetch

### 4. Adjust Performance

To improve battery life:

1. Increase `location_update_interval_minutes` (e.g., from 5 to 10)
2. Increase `geofence_monitoring_interval_seconds`
3. Publish changes

## Best Practices

1. **Test Changes First**: Use conditions to target a small percentage of users before full rollout
2. **Document Changes**: Add meaningful descriptions to each parameter
3. **Backup Before Publishing**: Always backup current config before major changes
4. **Monitor Impact**: Check Firebase Analytics after config changes
5. **Use Conditions**: Target specific platforms, app versions, or user segments
6. **Version Control**: Keep a copy of your config JSON in version control (without sensitive data)

## Troubleshooting

### Config Not Updating

- Check minimum fetch interval (1 hour in production)
- Force refresh using `forceRefresh()` method
- Check Firebase Console for published changes
- Verify app has network connection

### Wrong Values

- Check default values in `lib/services/remote_config_service.dart`
- Verify parameter names match exactly (case-sensitive)
- Check value type (Boolean vs String vs Number)

### Performance Issues

- Reduce fetch frequency in production
- Don't call `forceRefresh()` too often (quota limits)
- Use default values as fallback

## Additional Resources

- [Firebase Remote Config Documentation](https://firebase.google.com/docs/remote-config)
- [Flutter Remote Config Package](https://pub.dev/packages/firebase_remote_config)
- [Remote Config Best Practices](https://firebase.google.com/docs/remote-config/best-practices)

## Support

For issues with Remote Config:
1. Check Firebase Status Dashboard
2. Review Cloud Functions logs
3. Check app logs for error messages
4. Contact Firebase Support if needed
