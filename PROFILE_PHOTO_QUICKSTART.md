# Profile Photo Feature - Quick Start Guide

This guide will help you quickly set up and start using the new profile photo management feature.

## 🚀 Quick Overview

The profile photo feature allows users to upload, view, and manage their profile pictures through a web interface. It uses Firebase Storage and Authentication for secure photo management.

## 📋 Prerequisites

- [ ] Firebase project set up
- [ ] Firebase Authentication enabled (Email/Password)
- [ ] Firebase Storage enabled
- [ ] At least one user account created

## ⚡ 5-Minute Setup

### Step 1: Get Firebase Configuration (2 minutes)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click ⚙️ → Project Settings
4. Scroll to "Your apps" → Web app
5. Copy the `firebaseConfig` object

### Step 2: Configure profile.html (1 minute)

1. Open `web/profile.html`
2. Find line 362 (search for `firebaseConfig`)
3. Replace placeholder values with your actual config:

```javascript
const firebaseConfig = {
  apiKey: "YOUR_ACTUAL_API_KEY",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123"
};
```

### Step 3: Deploy Storage Rules (1 minute)

```bash
firebase deploy --only storage
```

### Step 4: Test Locally (1 minute)

```bash
cd web
python3 -m http.server 8000
```

Open: `http://localhost:8000/profile.html`

## ✅ Quick Test

1. Sign in with your test user credentials
2. Click "Choose a photo to upload"
3. Select an image file
4. Click "Upload Photo"
5. See your photo displayed!

## 📁 What You Get

### Files Added:
- `web/profile.html` - Profile photo web interface
- `web/default-avatar.svg` - Default avatar image
- `PROFILE_PHOTO_FRONTEND_SETUP.md` - Detailed setup guide
- `PROFILE_PHOTO_IMPLEMENTATION_SUMMARY.md` - Technical documentation
- `PROFILE_PHOTO_QUICKSTART.md` - This file

### Files Updated:
- `storage.rules` - Added profile_photos security rules
- `STORAGE_RULES.md` - Documentation updated

## 🔐 Security Features

✅ Users can only manage their own photos
✅ Authentication required for all operations
✅ File size limited to 10MB
✅ Only image files accepted
✅ Exact filename matching (no regex exploits)

## 🎨 Customization

### Change Default Avatar

Replace `web/default-avatar.svg` with your own image:
```bash
cp your-avatar.png web/default-avatar.png
```

### Modify Styling

Edit the `<style>` section in `web/profile.html` to customize:
- Colors (currently purple gradient)
- Fonts
- Button styles
- Layout

## 📱 Mobile-Friendly

The interface is fully responsive and works on:
- Desktop browsers
- Mobile browsers
- Tablets
- PWAs

## 🔗 Integration with Flutter App

The web frontend uses the same storage structure as your Flutter app:

**Storage Path**: `profile_photos/{userId}.{ext}`

Photos uploaded via web are instantly visible in the Flutter app and vice versa.

## 🐛 Troubleshooting

**"Firebase configuration error"**
→ Update `firebaseConfig` in profile.html

**"Permission denied"**
→ Deploy storage rules: `firebase deploy --only storage`

**Photo not loading**
→ Check if file exists in Firebase Storage console

**"Network error"**
→ Use a web server (not file:// protocol)

## 📚 Full Documentation

For detailed information, see:

1. **Setup Guide**: `PROFILE_PHOTO_FRONTEND_SETUP.md`
   - Complete Firebase setup
   - Production deployment
   - Advanced configuration

2. **Implementation Summary**: `PROFILE_PHOTO_IMPLEMENTATION_SUMMARY.md`
   - Technical details
   - Security features
   - Integration guide

3. **Storage Rules**: `STORAGE_RULES.md`
   - Complete rules documentation
   - Security explanations
   - Testing procedures

## 🚀 Production Deployment

When ready for production:

1. Build Flutter web app:
   ```bash
   flutter build web
   ```

2. Deploy to Firebase Hosting:
   ```bash
   firebase deploy
   ```

3. Access at:
   ```
   https://your-project.web.app/profile.html
   ```

## 💡 Tips

- Test with multiple user accounts to verify isolation
- Monitor storage usage in Firebase Console
- Set up billing alerts to avoid surprises
- Keep Firebase SDK updated
- Use separate projects for dev/prod

## 🎯 Next Steps

After setup:

1. ✅ Test photo upload/removal
2. ✅ Verify security rules work correctly
3. ✅ Test on mobile devices
4. ✅ Integrate with your Flutter app
5. ✅ Deploy to production

## 💬 Support

If you encounter issues:

1. Check browser console for errors
2. Review Firebase Console for rule violations
3. Consult the full documentation files
4. Check Firebase status page

## ✨ Features

Current:
- ✅ Upload profile photos
- ✅ Display profile photos
- ✅ Remove profile photos
- ✅ Default avatar
- ✅ User authentication
- ✅ Secure storage rules

Potential Future Enhancements:
- Image cropping
- Client-side compression
- Multiple photo support
- Photo history/versions

---

**Setup Time**: ~5 minutes  
**Difficulty**: Easy  
**Status**: Ready to Use

Happy coding! 🎉
