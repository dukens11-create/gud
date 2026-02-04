# Post-CodeMagic Android Build Guide

## 🎉 Congratulations on Your Successful CodeMagic Build!

Your Android app has been successfully built on CodeMagic. This guide will walk you through the next steps for distribution, deployment, and ongoing maintenance.

---

## 📋 Table of Contents

1. [Download Your Build Artifacts](#1-download-your-build-artifacts)
2. [Test Your Build](#2-test-your-build)
3. [Distribution Options](#3-distribution-options)
4. [Google Play Store Deployment](#4-google-play-store-deployment)
5. [Firebase App Distribution](#5-firebase-app-distribution)
6. [Beta Testing](#6-beta-testing)
7. [Monitoring & Analytics](#7-monitoring--analytics)
8. [Maintenance & Updates](#8-maintenance--updates)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Download Your Build Artifacts

### From CodeMagic Dashboard

1. **Access Your Build:**
   - Go to [CodeMagic Dashboard](https://codemagic.io/apps)
   - Click on your GUD Express project
   - Find the successful build (green checkmark ✅)
   - Click on the build number

2. **Download Artifacts:**
   
   You should see two main files:
   
   **APK File** (for direct installation/testing):
   - `app-release.apk` (~20-50 MB)
   - Click download icon
   - Save to a secure location
   
   **AAB File** (for Google Play Store):
   - `app-release.aab` (~15-30 MB)
   - This is the App Bundle format
   - Required for Play Store submission
   - Click download icon
   - Save to a secure location

3. **Save Build Information:**
   ```
   Build Number: #___
   Build Date: ___________
   Version: 1.0.0+1 (check your pubspec.yaml)
   Git Commit: ___________ (from CodeMagic)
   ```

### Build Artifacts Explained

| File Type | Purpose | Size | Use Case |
|-----------|---------|------|----------|
| **APK** | Direct installation | Larger | Testing, internal distribution |
| **AAB** | Play Store bundle | Smaller | Production Play Store deployment |
| **Build logs** | Debugging | Text | Troubleshooting build issues |

---

## 2. Test Your Build

### Option A: Test APK on Physical Device

**Prerequisites:**
- Android device
- USB cable or cloud transfer

**Steps:**

1. **Transfer APK to Device:**
   ```bash
   # Via USB (using adb)
   adb install app-release.apk
   
   # Or upload to Google Drive/Dropbox and download on device
   ```

2. **Enable Installation from Unknown Sources:**
   - Go to **Settings** → **Security** → **Install unknown apps**
   - Select your browser or file manager
   - Enable **Allow from this source**

3. **Install APK:**
   - Open the APK file on your device
   - Tap **Install**
   - Wait for installation to complete
   - Tap **Open**

4. **Test Checklist:**
   
   ✅ **App Launch**
   - [ ] App opens without crashing
   - [ ] Splash screen displays correctly
   - [ ] No immediate errors

   ✅ **Authentication**
   - [ ] Login screen appears
   - [ ] Can login as admin (admin@gud.com / admin123)
   - [ ] Can login as driver (driver@gud.com / driver123)
   - [ ] Logout works

   ✅ **Admin Functions**
   - [ ] Can view all loads
   - [ ] Can view drivers list
   - [ ] Statistics display correctly
   - [ ] No crashes when navigating

   ✅ **Driver Functions**
   - [ ] Can view assigned loads
   - [ ] Can see load details
   - [ ] Can update load status
   - [ ] Earnings display correctly

   ✅ **General**
   - [ ] All screens load properly
   - [ ] Navigation works smoothly
   - [ ] No performance issues
   - [ ] App icon displays correctly
   - [ ] App name is correct

### Option B: Test on Emulator

```bash
# Start Android emulator
emulator -avd YOUR_AVD_NAME

# Install APK
adb install app-release.apk

# Run tests
flutter test
```

---

## 3. Distribution Options

Now that your app is built, you have several distribution options:

### Option 1: 🏪 Google Play Store (Recommended for Production)
- **Best for:** Public release, wide distribution
- **Requirements:** Google Play Developer account ($25 one-time)
- **Review time:** 1-7 days
- **Reach:** Billions of users
- **See:** [Section 4](#4-google-play-store-deployment)

### Option 2: 🔥 Firebase App Distribution (Recommended for Testing)
- **Best for:** Beta testing, internal distribution
- **Requirements:** Free Firebase account
- **Setup time:** 10-15 minutes
- **Reach:** Unlimited testers via email
- **See:** [Section 5](#5-firebase-app-distribution)

### Option 3: 📧 Direct APK Distribution
- **Best for:** Small team testing
- **Requirements:** None
- **Distribution:** Email, cloud storage, USB
- **Limitations:** Manual updates, no analytics

### Option 4: 🏢 Enterprise Distribution
- **Best for:** Company-specific deployment
- **Requirements:** MDM solution or company portal
- **Distribution:** Controlled internal channels

---

## 4. Google Play Store Deployment

### Prerequisites

- ✅ Google Play Developer account ($25 one-time fee)
- ✅ App Bundle file (AAB) from CodeMagic
- ✅ App assets ready (icons, screenshots, descriptions)
- ✅ Privacy policy URL (required)

### Step-by-Step Guide

#### Step 1: Create Developer Account

1. Go to [Google Play Console](https://play.google.com/console/signup)
2. Pay the $25 one-time registration fee
3. Complete account verification
4. Accept developer agreement

#### Step 2: Create New App

1. **In Play Console:**
   - Click **"Create app"**
   - Fill in details:
     - **App name:** GUD Express
     - **Default language:** English (United States)
     - **App or game:** App
     - **Free or paid:** Free (or Paid if applicable)
   - Declare if app is for kids
   - Accept declarations
   - Click **"Create app"**

#### Step 3: Complete Store Listing

Navigate to **Store presence** → **Main store listing**:

1. **App Details:**
   ```
   App name: GUD Express
   Short description (80 chars max):
   "Trucking management app for drivers and fleet managers."
   
   Full description (4000 chars max):
   """
   GUD Express is a comprehensive trucking management solution designed for 
   truck drivers and fleet managers. 
   
   🚛 FOR DRIVERS:
   • View assigned loads in real-time
   • Track load status from pickup to delivery
   • Monitor earnings and completed trips
   • Simple, intuitive interface
   • Update delivery status on-the-go
   
   📊 FOR ADMINS/DISPATCHERS:
   • Manage all loads and drivers
   • Real-time load tracking
   • Driver performance monitoring
   • Quick operational overview
   • Statistics and reporting
   
   ✨ KEY FEATURES:
   • Real-time load updates
   • Earnings tracking
   • Load status management
   • Driver assignments
   • Proof of delivery support
   • Expense tracking
   • Mobile-optimized interface
   
   Perfect for trucking companies of any size looking to streamline their 
   operations and improve driver communication.
   """
   ```

2. **App Icon:**
   - Size: 512 x 512 pixels
   - Format: 32-bit PNG
   - No transparency
   - Upload from your project: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

3. **Screenshots (Required):**
   
   You need at least **2 screenshots** per device type:
   
   **Phone Screenshots (Required):**
   - Minimum 2 screenshots
   - Size: 16:9 or 9:16 aspect ratio
   - Resolution: 320px to 3840px
   
   **Tablet Screenshots (Recommended):**
   - Size: 1920x1200 or 1200x1920
   
   **Take screenshots:**
   ```bash
   # Install app on device/emulator
   # Take screenshots of:
   1. Login screen
   2. Driver home screen (with loads list)
   3. Load details screen
   4. Admin dashboard
   5. Earnings/statistics screen
   ```

4. **Feature Graphic (Required):**
   - Size: 1024 x 500 pixels
   - Format: PNG or JPEG
   - Use for promotional banner

#### Step 4: Set App Categorization

1. **Go to:** Store presence → Store settings
2. **Category:** Business or Productivity
3. **Tags:** Trucking, Logistics, Fleet Management, Business

#### Step 5: Privacy Policy

**Required:** You must provide a privacy policy URL

**Quick Option:** Create a privacy policy page:

```markdown
# Privacy Policy for GUD Express

Last updated: [Date]

## Information We Collect
- User account information (email, name)
- Load and delivery data
- Location data for delivery tracking
- Device information

## How We Use Information
- Provide trucking management services
- Track deliveries and loads
- Calculate earnings
- Improve app functionality

## Data Security
We implement security measures to protect your data.

## Contact Us
Email: support@gudexpress.com
```

Host this on:
- GitHub Pages (free)
- Firebase Hosting (free)
- Your company website

Then paste the URL in Play Console.

#### Step 6: Content Rating

1. **Go to:** Policy → App content → Content rating
2. Click **Start questionnaire**
3. Enter email address
4. Select category: **Utility, Productivity, Communication**
5. Answer questions honestly (typically all "No" for business app)
6. Submit
7. You'll get a rating (typically "Everyone")

#### Step 7: Target Audience

1. **Go to:** Policy → App content → Target audience
2. Select target age group: **18+** (Business app)
3. Appeal: **Older users**

#### Step 8: Set Up App Access

1. **Go to:** Policy → App content → App access
2. If app requires login:
   - Provide demo credentials
   ```
   Admin: admin@gud.com / admin123
   Driver: driver@gud.com / driver123
   ```
3. Save

#### Step 9: Upload App Bundle

1. **Go to:** Release → Production → Create new release
2. Click **Upload** and select your **app-release.aab** file
3. Wait for upload and processing (2-10 minutes)
4. Review any warnings (fix if critical)
5. **Release name:** Version 1.0.0
6. **Release notes:**
   ```
   Initial release of GUD Express
   
   Features:
   • Driver load management
   • Real-time load tracking
   • Earnings tracking
   • Admin dashboard
   • Proof of delivery support
   ```

#### Step 10: Review and Rollout

1. **Review release:**
   - Check all information is correct
   - Verify all required sections are complete
   - Green checkmarks on all items

2. **Start rollout:**
   - Click **Review release**
   - Review summary
   - Click **Start rollout to Production**

3. **Submit for review:**
   - Confirm submission
   - Google will review your app

#### Step 11: Wait for Review

- **Timeline:** Usually 1-7 days
- **Status:** Check Play Console for updates
- **Email:** Google will email you when approved/rejected

**Common Review Times:**
- Initial review: 2-5 days
- Updates: 1-3 days
- Expedited (if available): 24-48 hours

### After Approval

Once approved, your app will be live on Google Play Store!

**Your app URL will be:**
```
https://play.google.com/store/apps/details?id=com.gudexpress.gud_app
```
(Replace with your actual package name)

---

## 5. Firebase App Distribution

Perfect for beta testing before Play Store submission!

### Why Firebase App Distribution?

✅ **Free** - No cost for unlimited distribution  
✅ **Fast** - Share with testers instantly  
✅ **Easy** - No app store submission required  
✅ **Analytics** - Track installations and feedback  
✅ **Control** - Choose who gets access  

### Setup Guide

#### Step 1: Set Up Firebase Project

1. **Create Firebase Project:**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Click **Add project**
   - Name: **GUD Express**
   - Enable Google Analytics (optional)
   - Click **Create project**

2. **Add Android App:**
   - Click **Android icon**
   - Package name: `com.gudexpress.gud_app` (check your AndroidManifest.xml)
   - App nickname: **GUD Express Android**
   - Click **Register app**
   - Download `google-services.json` (save for later updates)

#### Step 2: Enable App Distribution

1. **In Firebase Console:**
   - Click **Release & Monitor** → **App Distribution**
   - Click **Get started**

2. **Install Firebase CLI:**
   ```bash
   npm install -g firebase-tools
   
   # Login
   firebase login
   ```

#### Step 3: Upload APK to Firebase

You can upload via:

**Option A: Web Console (Easiest)**

1. Go to Firebase Console → App Distribution
2. Click **Get started** (if first time)
3. Click **Upload new release**
4. Drag and drop your **app-release.apk** file
5. Add release notes:
   ```
   Version 1.0.0 Beta
   - Initial release for testing
   - Driver load management
   - Admin dashboard
   ```
6. Click **Next**

**Option B: Firebase CLI (Advanced)**

```bash
# Upload APK
firebase appdistribution:distribute app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --release-notes "Version 1.0.0 Beta - Initial release for testing" \
  --groups testers

# Find your Firebase App ID in Project Settings
```

#### Step 4: Invite Testers

1. **Create tester group:**
   - In App Distribution → Testers & Groups
   - Click **Add Group**
   - Name: **Beta Testers**
   - Click **Create**

2. **Add testers:**
   - Click on **Beta Testers** group
   - Click **Add testers**
   - Enter email addresses (one per line):
     ```
     tester1@example.com
     tester2@example.com
     manager@company.com
     ```
   - Click **Add testers**

3. **Distribute to group:**
   - Go back to Releases
   - Click on your release
   - Click **Distribute**
   - Select **Beta Testers** group
   - Click **Distribute**

#### Step 5: Testers Install App

Testers will receive an email with:

1. **Email invitation** from Firebase
2. Click **Get started** link
3. Install Firebase App Distribution app (if first time)
4. Accept invitation
5. Download and install GUD Express
6. Start testing!

**Tester Instructions to Share:**

```
You've been invited to test GUD Express!

1. Check your email for Firebase App Distribution invite
2. Click "Get started" link in email
3. Install "Firebase App Distribution" from Play Store (if needed)
4. Accept the invitation
5. Download GUD Express
6. Install and test the app

Test Accounts:
Admin: admin@gud.com / admin123
Driver: driver@gud.com / driver123

Please report any issues you find!
```

#### Step 6: Collect Feedback

Create a feedback form:
- Google Forms
- Typeform
- Email
- In-app feedback (if implemented)

**Feedback Template:**
```
GUD Express Beta Testing Feedback

1. What device are you using?
2. Did the app install successfully? (Yes/No)
3. Were you able to login? (Yes/No)
4. What features did you test?
5. Did you encounter any bugs or issues?
6. What did you like about the app?
7. What could be improved?
8. Overall rating (1-5 stars):
```

---

## 6. Beta Testing

### Beta Testing Checklist

#### Pre-Beta Launch
- [ ] Define testing goals
- [ ] Identify beta testers (5-20 people recommended)
- [ ] Create test plan document
- [ ] Set up feedback collection method
- [ ] Prepare tester instructions
- [ ] Set testing timeline (1-2 weeks typical)

#### During Beta Testing

**Week 1: Initial Testing**
- [ ] Distribute app via Firebase App Distribution
- [ ] Send tester instructions and credentials
- [ ] Monitor crash reports
- [ ] Check Firebase Analytics
- [ ] Respond to tester questions
- [ ] Log all reported issues

**Week 2: Bug Fixes & Re-test**
- [ ] Fix critical bugs found in Week 1
- [ ] Release updated version to testers
- [ ] Verify fixes work
- [ ] Collect final feedback

#### Testing Scenarios

Share these scenarios with testers:

**For Driver Role:**
```
1. Login as driver (driver@gud.com / driver123)
2. View your assigned loads
3. Open a load and check details
4. Try updating load status
5. Check earnings section
6. Test navigation between screens
7. Logout and login again
```

**For Admin Role:**
```
1. Login as admin (admin@gud.com / admin123)
2. View all loads dashboard
3. Check driver statistics
4. View load details
5. Test filtering/search (if available)
6. Check all navigation menus
7. Verify data displays correctly
```

**Edge Cases to Test:**
```
1. Poor internet connection (airplane mode)
2. App backgrounding and returning
3. Device rotation
4. Different screen sizes
5. Multiple rapid taps
6. Very long text inputs
7. Back button behavior
```

### Common Issues Found in Beta

| Issue | Impact | Priority | Typical Fix Time |
|-------|--------|----------|------------------|
| Crash on startup | Critical | P0 | 1-2 days |
| Login failure | Critical | P0 | 1-2 days |
| UI misalignment | Low | P2 | 1-2 hours |
| Slow loading | Medium | P1 | 2-4 hours |
| Missing data | High | P1 | 2-6 hours |

### When to End Beta

End beta testing when:
- ✅ No critical (P0) bugs remain
- ✅ All major features tested
- ✅ Positive tester feedback (>80%)
- ✅ Performance is acceptable
- ✅ All P1 bugs fixed or documented
- ✅ Testing timeline complete

---

## 7. Monitoring & Analytics

### Set Up Monitoring Tools

#### Firebase Analytics (Recommended)

**Already included if you're using Firebase!**

1. **Enable in Firebase Console:**
   - Firebase Console → Analytics
   - View dashboard

2. **Key Metrics to Track:**
   - Daily Active Users (DAU)
   - User retention (1-day, 7-day, 30-day)
   - Screen views (most used features)
   - User engagement time
   - Crash-free users %

#### Firebase Crashlytics

**Set up crash reporting:**

1. **Add to your app:**
   ```yaml
   # In pubspec.yaml (if not already added)
   dependencies:
     firebase_crashlytics: ^latest_version
   ```

2. **Initialize in main.dart:**
   ```dart
   // Add crash reporting
   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
   ```

3. **View crashes:**
   - Firebase Console → Crashlytics
   - See crash reports, stack traces
   - Filter by version, device, OS

#### Google Play Console Analytics

Once on Play Store, you'll get:
- Install/uninstall statistics
- User ratings and reviews
- Crashes and ANRs
- User acquisition sources

### Monitoring Dashboard Checklist

**Daily Checks (5 minutes):**
- [ ] Check for new crashes (Crashlytics)
- [ ] Review user ratings (Play Console)
- [ ] Check active users (Analytics)
- [ ] Monitor error rate

**Weekly Reviews (30 minutes):**
- [ ] Analyze user retention trends
- [ ] Review feature usage
- [ ] Check performance metrics
- [ ] Read user reviews and respond
- [ ] Update roadmap based on feedback

**Monthly Reviews (2 hours):**
- [ ] Full analytics review
- [ ] User feedback analysis
- [ ] Performance optimization plan
- [ ] Feature prioritization
- [ ] Cost analysis (Firebase usage)

---

## 8. Maintenance & Updates

### Regular Maintenance Schedule

#### Weekly Tasks
- [ ] Monitor crash reports
- [ ] Review user feedback
- [ ] Check Firebase quotas
- [ ] Respond to app reviews
- [ ] Update bug tracking

#### Monthly Tasks
- [ ] Update dependencies
  ```bash
  flutter pub outdated
  flutter pub upgrade
  ```
- [ ] Security review
- [ ] Performance optimization
- [ ] Backup user data
- [ ] Review Firebase costs

#### Quarterly Tasks
- [ ] Major feature updates
- [ ] UI/UX improvements
- [ ] User survey
- [ ] Documentation updates
- [ ] Marketing review

### Pushing Updates

#### Update Process

1. **Make changes locally**
2. **Update version number** in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # version+build
   #        ↑    ↑
   #        |    └── Build number (increment)
   #        └─────── Version name (semantic versioning)
   ```

3. **Update on CodeMagic:**
   - Push code to repository
   - CodeMagic will automatically build (if configured)
   - Or trigger manual build

4. **Download new AAB/APK**

5. **Test new version**

6. **Upload to Play Store:**
   - Go to Play Console
   - Create new release
   - Upload new AAB
   - Add release notes
   - Start rollout

#### Version Numbering Guide

**Semantic Versioning:** MAJOR.MINOR.PATCH

```
1.0.0 → Initial release
1.0.1 → Bug fixes
1.1.0 → New features (backwards compatible)
2.0.0 → Major changes (breaking changes)
```

**Build Number:** Increment for every release
```
1.0.0+1 → First release
1.0.0+2 → Second build of same version
1.0.1+3 → Bug fix with new build
```

#### Staged Rollout Strategy

**Recommended for production updates:**

1. **10% rollout** (Day 1)
   - Monitor for crashes
   - Check error rates
   - Review user feedback

2. **50% rollout** (Day 3)
   - If metrics look good
   - Continue monitoring

3. **100% rollout** (Day 5)
   - Full deployment
   - All users get update

**In Play Console:**
- Release → Create new release
- After upload, select "Staged rollout"
- Choose percentage

---

## 9. Troubleshooting

### Common Issues & Solutions

#### 1. App Not Installing on Device

**Error:** "App not installed"

**Solutions:**
```
✓ Check if old version installed → Uninstall first
✓ Check storage space → Free up 100MB+
✓ Check Android version → Needs 5.0+ (API 21+)
✓ Verify APK not corrupted → Re-download
✓ Enable unknown sources → Settings → Security
```

#### 2. CodeMagic Build Failed

**Check build logs:**
```
1. Open CodeMagic dashboard
2. Click on failed build
3. Check "Build" logs
4. Look for error message (usually near end)
```

**Common errors:**
```
- "Gradle build failed" → Check build.gradle syntax
- "Signing config not found" → Add keystore config
- "Dependencies not found" → Run flutter pub get
- "Out of memory" → Reduce build complexity
```

#### 3. App Crashes on Startup

**Debug steps:**
```bash
# View device logs
adb logcat | grep GUD

# Look for:
- Java exceptions
- Flutter errors
- Missing libraries
```

**Common causes:**
- Firebase not initialized
- Missing google-services.json
- Incompatible dependencies
- Memory issues

#### 4. Play Store Review Rejected

**Common rejection reasons:**

| Reason | Solution |
|--------|----------|
| Privacy policy missing | Add privacy policy URL |
| Broken functionality | Fix bugs, re-test thoroughly |
| Misleading description | Update store listing to be accurate |
| Permissions not justified | Remove unnecessary permissions |
| Inappropriate content | Review and remove |

**Appeal process:**
1. Read rejection reason carefully
2. Fix the issue
3. Update app (new version)
4. Re-submit
5. Add note explaining changes

#### 5. Firebase App Distribution Not Working

**Tester can't download:**
```
✓ Check tester email is correct
✓ Verify tester accepted invitation
✓ Check Firebase App Distribution app installed
✓ Try re-sending invitation
```

**Upload fails:**
```
✓ Check APK file not corrupted
✓ Verify Firebase project configured
✓ Check internet connection
✓ Try uploading via web console instead of CLI
```

### Getting Help

#### Support Resources

**Firebase:**
- Documentation: https://firebase.google.com/docs
- Support: https://firebase.google.com/support
- Community: Stack Overflow (tag: firebase)

**Google Play:**
- Help Center: https://support.google.com/googleplay/android-developer
- Community: https://support.google.com/googleplay/android-developer/community

**CodeMagic:**
- Documentation: https://docs.codemagic.io/
- Support: support@codemagic.io
- Slack Community: https://codemagic.io/slack

**Flutter:**
- Documentation: https://flutter.dev/docs
- GitHub Issues: https://github.com/flutter/flutter/issues
- Discord: https://discord.gg/flutter

---

## 🎯 Quick Reference - Next Steps Summary

Now that your Android app is built on CodeMagic, here's what to do:

### Immediate Actions (Today)
1. ✅ Download APK and AAB from CodeMagic
2. ✅ Test APK on your device
3. ✅ Verify all features work correctly
4. ✅ Note any bugs or issues

### Short-term (This Week)
1. 🔥 Set up Firebase App Distribution
2. 📧 Invite 5-10 beta testers
3. 📝 Collect feedback
4. 🐛 Fix any critical bugs

### Medium-term (Next 2 Weeks)
1. 🏪 Create Google Play Developer account
2. 📸 Prepare app store assets (screenshots, descriptions)
3. 📄 Create privacy policy
4. 🎨 Final testing and polish

### Long-term (Month 1)
1. 🚀 Submit to Google Play Store
2. 📊 Set up monitoring (Analytics, Crashlytics)
3. 👥 Plan for user feedback
4. 📈 Marketing and promotion

---

## 🎉 Congratulations!

You've successfully built your Android app and now have a clear path forward. 

**Choose your path:**

- **Fast Track Testing:** Go to [Section 5 - Firebase App Distribution](#5-firebase-app-distribution)
- **Production Release:** Go to [Section 4 - Google Play Store](#4-google-play-store-deployment)
- **Both:** Start with Firebase, then move to Play Store

**Remember:**
- Test thoroughly before public release
- Gather feedback from beta testers
- Monitor your app after launch
- Keep your app updated

**Good luck with your deployment! 🚀**

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-03  
**For:** GUD Express Trucking Management App

---

## Additional Resources

- **Project Documentation:** [README.md](./README.md)
- **Deployment Guide:** [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Production Deployment:** [DEPLOYMENT_PRODUCTION.md](./DEPLOYMENT_PRODUCTION.md)
- **Firebase Setup:** [FIREBASE_SETUP.md](./FIREBASE_SETUP.md)
