# Quick Start Guide - GUD Express Firebase App

Get the GUD Express Trucking Management app up and running in minutes.

## 🚀 Prerequisites

Before you begin, ensure you have:
- [ ] Google account for Firebase
- [ ] Flutter SDK installed (3.0.0+)
- [ ] Android Studio or VS Code
- [ ] Git installed

## ⚡ Quick Setup (5 Steps)

### Step 1: Clone and Install Dependencies (2 minutes)

```bash
# Clone the repository
git clone https://github.com/dukens11-create/gud.git
cd gud

# Get Flutter packages
flutter pub get
```

### Step 2: Create Firebase Project (3 minutes)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add Project"
3. Name: "GUD Express" (or your choice)
4. Enable Google Analytics: Yes
5. Click "Create Project"

### Step 3: Add Your App to Firebase (2 minutes)

#### For Android:
```bash
1. In Firebase Console, click Android icon
2. Package name: com.gudexpress.gud_app
3. Download google-services.json
4. Move to: android/app/google-services.json
```

#### For iOS (if needed):
```bash
1. In Firebase Console, click iOS icon
2. Bundle ID: com.gudexpress.gudApp
3. Download GoogleService-Info.plist
4. Move to: ios/Runner/GoogleService-Info.plist
```

#### For Web:
```bash
1. In Firebase Console, click Web icon
2. Copy configuration
3. Update lib/firebase_options.dart with your values
```

### Step 4: Enable Firebase Services (3 minutes)

#### Enable Authentication:
```
Firebase Console → Authentication → Get Started
→ Email/Password → Enable → Save
```

#### Enable Firestore:
```
Firebase Console → Firestore Database → Create Database
→ Production mode → Select location → Enable
```

#### Enable Storage:
```
Firebase Console → Storage → Get Started
→ Production mode → Done
```

#### Deploy Security Rules:
```
1. Firestore → Rules tab → Copy rules from FIRESTORE_RULES.md → Publish
2. Storage → Rules tab → Copy rules from STORAGE_RULES.md → Publish
```

### Step 5: Create Admin User (2 minutes)

```
Firebase Console → Authentication → Users → Add User
Email: admin@yourcompany.com
Password: [Choose strong password]

Then:
Firestore → Data → users → + Add Document
Document ID: [Paste User UID from Authentication]
Fields:
  role: "admin"
  name: "Admin User"
  email: "admin@yourcompany.com"
  phone: "+1234567890"
  truckNumber: "N/A"
  isActive: true
  createdAt: [Current timestamp]
```

## ▶️ Run the App

```bash
# Run on Android
flutter run

# Or run on iOS
flutter run -d ios

# Or run on web
flutter run -d chrome
```

## 🔐 Login Credentials

After setup, use these credentials:

**Admin Account:**
- Email: admin@yourcompany.com
- Password: [Your password from Step 5]

**Driver Account:**
- Create through the app using Admin account
- Manage Drivers → Fill form → Create Driver

## 🎯 Quick Feature Tour

### As Admin:
1. **Login** with admin credentials
2. **Create Driver**:
   - Tap People icon (bottom right)
   - Fill in driver details
   - Click "Create Driver"
3. **Create Load**:
   - Tap Plus icon (bottom right)
   - Fill in load details
   - Auto-generated load number
   - Select driver from dropdown
   - Click "Create Load"
4. **View All Loads**:
   - Real-time list on home screen
   - See all drivers' loads

### As Driver:
1. **Login** with driver credentials (created by admin)
2. **View Your Loads**:
   - See only loads assigned to you
   - Real-time updates
3. **Update Load Status**:
   - Tap on a load
   - "Mark as Picked Up"
   - "Start Trip"
   - "Upload POD" (camera or gallery)
   - "Complete Delivery" (enter miles)
4. **Check Earnings**:
   - Tap dollar icon in app bar
   - See total from delivered loads

## 📱 Test Workflow

Complete workflow to test all features:

1. **As Admin:**
   ```
   Login → Create Driver → Create Load → Assign to Driver → Logout
   ```

2. **As Driver:**
   ```
   Login → View Loads → Open Load Detail → 
   Mark Picked Up → Start Trip → 
   Upload POD → Complete Delivery → 
   Check Earnings
   ```

3. **As Admin (again):**
   ```
   Login → View All Loads → See Updated Status
   ```

## ❓ Troubleshooting

### "Firebase not initialized"
```bash
Solution:
✓ Ensure google-services.json is in android/app/
✓ Run: flutter clean && flutter pub get
✓ Restart app
```

### "Permission denied"
```bash
Solution:
✓ Check user exists in Firestore /users/{uid}
✓ Verify role field is "admin" or "driver"
✓ Ensure security rules are published
```

### "Can't create driver"
```bash
Solution:
✓ Verify you're logged in as admin
✓ Check all fields are filled
✓ Ensure email is unique
```

### "Can't upload POD"
```bash
Solution:
✓ Grant camera permissions
✓ Check file size under 10MB
✓ Ensure image format (jpg/png)
✓ Verify Storage rules published
```

## 📚 Next Steps

After basic setup:

1. **Read Full Documentation**:
   - `FIREBASE_SETUP.md` - Detailed Firebase guide
   - `FIRESTORE_RULES.md` - Security rules explained
   - `STORAGE_RULES.md` - Storage rules explained

2. **Configure Production**:
   - Follow `DEPLOYMENT_PRODUCTION.md`
   - Set up separate dev/prod environments
   - Configure billing alerts

3. **Customize**:
   - Update app name and branding
   - Modify colors and theme
   - Add your company logo
   - Customize load statuses if needed

4. **Monitor**:
   - Enable Performance Monitoring
   - Set up Crashlytics
   - Review Analytics

## 🆘 Need Help?

### Documentation
- `README.md` - Project overview
- `ARCHITECTURE.md` - System design
- `FIREBASE_SETUP.md` - Detailed setup
- `IMPLEMENTATION_COMPLETE.md` - What was built

### External Resources
- [Firebase Docs](https://firebase.google.com/docs)
- [Flutter Docs](https://flutter.dev/docs)
- [FlutterFire](https://firebase.flutter.dev)

### Common Commands

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run app
flutter run

# Build release (Android)
flutter build apk --release

# Build release (iOS)
flutter build ios --release
```

## ✅ Verification Checklist

After setup, verify everything works:

- [ ] App launches without errors
- [ ] Can login as admin
- [ ] Can create driver
- [ ] Can create load with auto-generated number
- [ ] Can logout and login as driver
- [ ] Driver sees only their loads
- [ ] Can update load status
- [ ] Can upload POD image
- [ ] Can complete delivery
- [ ] Earnings update in real-time
- [ ] All features work smoothly

## 🎉 You're Ready!

If all checks pass, your GUD Express app is ready to use!

**Time to Setup**: ~15 minutes  
**Status**: Production Ready  
**Next**: Start managing your trucking operations!

---

**Questions?** Check the full documentation in the repository.

**Issues?** Review troubleshooting section or Firebase Console logs.

**Ready to Deploy?** Follow `DEPLOYMENT_PRODUCTION.md`.

---

*Last Updated: 2026-02-02*  
*Version: 1.0*
