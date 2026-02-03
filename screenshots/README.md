# GUD Express Screenshots

This directory contains screenshots of the GUD Express Trucking Management application across different platforms and screen sizes.

## 📱 Mobile Screenshots

### Authentication
- **login.png** - Login screen with email/password fields and demo credentials

### Driver Screens
- **driver-dashboard.png** - Driver home screen showing assigned loads
- **driver-load-detail.png** - Detailed view of a specific load
- **upload-pod.png** - Proof of Delivery upload screen with camera/gallery options
- **driver-earnings.png** - Earnings summary screen
- **driver-expenses.png** - Driver's personal expense tracking

### Admin Screens
- **admin-dashboard.png** - Admin home screen with all loads and quick actions
- **admin-create-load.png** - Load creation form
- **admin-manage-drivers.png** - Driver management screen
- **admin-expenses.png** - Expense management dashboard
- **admin-statistics.png** - Statistics and analytics dashboard

## 💻 Desktop Screenshots

- **login-desktop.png** - Desktop view of login screen
- **driver-dashboard-desktop.png** - Desktop driver dashboard
- **admin-dashboard-desktop.png** - Desktop admin dashboard
- **statistics-desktop.png** - Desktop statistics view

---

## 📸 How to Take Screenshots

### For Mobile (Android/iOS)

#### Using Physical Device
1. Build and install the app:
   ```bash
   flutter build apk --release
   # or
   flutter build ios --release
   ```
2. Install on device
3. Navigate through each screen
4. Take screenshots using device controls:
   - Android: Power + Volume Down
   - iOS: Side Button + Volume Up

#### Using Emulator/Simulator
1. Run app in emulator:
   ```bash
   flutter run
   ```
2. Use emulator screenshot tools:
   - Android Studio: Camera icon in emulator toolbar
   - iOS Simulator: File → New Screen Shot (Cmd+S)

### For Desktop

1. Run app in Chrome:
   ```bash
   flutter run -d chrome
   ```
2. Set window to appropriate size (1280x720 or 1920x1080)
3. Take screenshots:
   - Windows: Win + Shift + S
   - Mac: Cmd + Shift + 4
   - Linux: PrtScn or use Screenshot tool

### For Web (PWA)

1. Deploy to Render or GitHub Pages
2. Open in browser
3. Use browser DevTools device emulation
4. Take screenshots at standard mobile sizes:
   - 375x667 (iPhone SE)
   - 390x844 (iPhone 12/13)
   - 360x800 (Android)

---

## 🤖 Automated Screenshot Generation

### Using Flutter Integration Tests

We've set up automated screenshot generation using integration tests.

#### Run Automated Screenshots

```bash
# Generate all screenshots
flutter test integration_test/screenshot_test.dart

# Screenshots will be saved to screenshots/ directory
```

#### Setup (if not already configured)

1. Ensure integration_test is in pubspec.yaml
2. Run the screenshot test
3. Screenshots automatically saved with proper naming

### Using Screenshots Package

For more control:

```bash
# Add to pubspec.yaml dev_dependencies
screenshots: ^2.7.0

# Create screenshots.yaml config
screenshots:
  tests:
    - test_driver/screenshots.dart
  staging: screenshots/staging
  locales:
    - en-US
  devices:
    android:
      - Pixel 6
    ios:
      - iPhone 14

# Run
flutter pub run screenshots:main
```

---

## 📐 Screenshot Specifications

### Mobile Screenshots
- **Format**: PNG
- **Size**: 
  - Portrait: 1080x1920 or 1242x2688
  - Landscape: 1920x1080 or 2688x1242
- **Content**: Clean UI, no personal data

### Desktop Screenshots
- **Format**: PNG
- **Size**: 1920x1080 or 1280x720
- **Content**: Responsive layout demonstration

### Store Requirements

#### Google Play Store
- At least 2 screenshots required
- Max 8 screenshots
- Dimensions: 
  - Min: 320px
  - Max: 3840px
- Aspect ratio: 16:9 or 9:16

#### Apple App Store
- At least 3 screenshots required
- Specific sizes for each device:
  - iPhone 6.5": 1242x2688 or 1284x2778
  - iPhone 5.5": 1242x2208
  - iPad Pro 12.9": 2048x2732

---

## ✨ Screenshot Best Practices

### Content Guidelines
✅ Use demo data (no real customer information)  
✅ Show complete features  
✅ Use consistent branding  
✅ Clean, professional appearance  
✅ Show key functionality  

### Technical Guidelines
✅ High resolution (at least 1080p)  
✅ PNG format for quality  
✅ Proper lighting/contrast  
✅ No personal data visible  
✅ Status bar cleaned (optional)  

### What to Capture
✅ Login screen  
✅ Main dashboards (driver & admin)  
✅ Key features (load management, POD upload, expenses)  
✅ Statistics/analytics  
✅ Mobile and desktop views  

---

## 🔄 Updating Screenshots

When the UI changes:
1. Delete old screenshots
2. Follow the screenshot guide above
3. Replace with new screenshots
4. Update README.md if new screens added
5. Commit and push changes

---

## 📝 Notes

- Screenshots are for documentation and store listings
- Keep screenshots up-to-date with latest UI
- Use placeholder/demo data only
- Ensure GDPR/privacy compliance (no real user data)

---

**Last Updated**: February 3, 2026  
**App Version**: 1.0.0
