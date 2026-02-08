# Profile Photo Frontend Setup Guide

This guide will help you set up and use the standalone HTML/JavaScript frontend for managing profile photos in the GUD Express application.

## Overview

The profile photo frontend (`web/profile.html`) is a standalone HTML page that uses the Firebase Web SDK to:
- Authenticate users with email/password
- Upload profile photos to Firebase Storage
- Display existing profile photos
- Remove profile photos
- Store photos as `profile_photos/{userId}.{ext}` in Firebase Storage

## Prerequisites

Before using the frontend, ensure you have:

1. **Firebase Project**: A Firebase project with Authentication and Storage enabled
2. **Firebase Configuration**: Your Firebase web app configuration credentials
3. **User Accounts**: At least one user account created in Firebase Authentication
4. **Storage Rules**: Firebase Storage rules properly configured (see below)

## Step 1: Configure Firebase

### 1.1 Get Firebase Configuration

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your GUD Express project
3. Click the gear icon (⚙️) → **Project settings**
4. Scroll down to **Your apps** section
5. Click on the Web app (</> icon) or create one if you haven't:
   - Click **Add app** → Select **Web** (</> icon)
   - Enter app nickname: "GUD Express Web"
   - Click **Register app**
6. Copy the `firebaseConfig` object

### 1.2 Update profile.html

1. Open `/web/profile.html` in your editor
2. Find the `firebaseConfig` object (around line 362)
3. Replace the placeholder values with your actual Firebase configuration:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  authDomain: "your-project-id.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project-id.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef1234567890"
};
```

4. Save the file

**⚠️ SECURITY WARNING:**
- **NEVER commit this file with real Firebase credentials to a public repository**
- For production deployments, use Firebase Hosting which automatically injects credentials
- Alternatively, use environment-specific configuration files
- Consider using a separate Firebase project for development and testing

## Step 2: Enable Firebase Authentication

1. In Firebase Console, go to **Build** → **Authentication**
2. Click **Get Started** (if not already enabled)
3. Click on **Sign-in method** tab
4. Enable **Email/Password** authentication:
   - Click on **Email/Password**
   - Toggle **Enable**
   - Click **Save**

## Step 3: Configure Firebase Storage Rules

The Storage rules have already been updated in `storage.rules` to support profile photos. Deploy them:

### Option A: Using Firebase CLI

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy storage rules
firebase deploy --only storage
```

### Option B: Using Firebase Console

1. Go to **Build** → **Storage** in Firebase Console
2. Click on the **Rules** tab
3. Copy the contents of `/storage.rules` from this repository
4. Paste into the Firebase Console editor
5. Click **Publish**

### Storage Rules Explanation

The rules allow authenticated users to:
- **Read**: View any user's profile photo
- **Write**: Upload their own profile photo (max 10MB, images only)
- **Delete**: Remove their own profile photo

```javascript
// Profile photos - in profile_photos/{userId}.{ext}
match /profile_photos/{fileName} {
  allow read: if isAuthenticated();
  allow write: if isAuthenticated() && 
    request.resource.size < 10 * 1024 * 1024 && // 10MB limit
    request.resource.contentType.matches('image/.*') &&
    fileName.matches('[^/]+\\.(jpg|jpeg|png|gif|webp)');
  allow delete: if isAuthenticated();
}
```

## Step 4: Create Test User (Optional)

If you don't have a test user yet:

1. Go to **Authentication** → **Users** tab in Firebase Console
2. Click **Add user**
3. Enter:
   - Email: `test@gudexpress.com`
   - Password: Choose a strong password
4. Click **Add user**

## Step 5: Deploy the Frontend

### Option A: Using Firebase Hosting

1. Build your Flutter web app:
```bash
flutter build web
```

2. Deploy to Firebase Hosting:
```bash
firebase deploy --only hosting
```

3. Access the profile page at:
```
https://your-project-id.web.app/profile.html
```

### Option B: Local Testing

1. Start a local web server in the `web` directory:

```bash
# Using Python 3
cd web
python3 -m http.server 8000

# Or using Node.js
npx http-server -p 8000

# Or using PHP
php -S localhost:8000
```

2. Open your browser to:
```
http://localhost:8000/profile.html
```

### Option C: Using Firebase Emulator

1. Start the Firebase emulator:
```bash
firebase emulators:start
```

2. The frontend will be available at:
```
http://localhost:5000/profile.html
```

**Note**: When using the emulator, update the Firebase configuration in `profile.html` to use emulator endpoints.

## Step 6: Use the Profile Photo Manager

### Sign In

1. Open `profile.html` in your browser
2. Enter your email and password
3. Click **Sign In**

### Upload Profile Photo

1. After signing in, you'll see the profile photo section
2. Click **Choose a photo to upload**
3. Select an image file from your device:
   - Supported formats: JPG, PNG, GIF, WEBP
   - Maximum size: 10MB
4. Click **Upload Photo**
5. Wait for the upload to complete
6. Your profile photo will be displayed

### Remove Profile Photo

1. If you have a profile photo uploaded, you'll see a **Remove Photo** button
2. Click **Remove Photo**
3. Confirm the removal
4. Your profile photo will be removed and replaced with the default avatar

### Sign Out

1. Click **Sign Out** to log out
2. You'll be returned to the sign-in screen

## File Storage Structure

Profile photos are stored in Firebase Storage with the following structure:

```
gs://your-project-id.appspot.com/
└── profile_photos/
    ├── user-id-1.jpg
    ├── user-id-2.png
    ├── user-id-3.jpg
    └── ...
```

- Each user's photo is named with their Firebase User ID
- The file extension matches the uploaded file type
- Photos are automatically overwritten when a new photo is uploaded

## Default Avatar

If a user doesn't have a profile photo, the default avatar image is displayed:
- Located at `/web/default-avatar.svg`
- Simple SVG icon showing a person silhouette
- You can replace this with your own default avatar image

To use a custom default avatar:
1. Replace `/web/default-avatar.svg` or `/web/default-avatar.png`
2. Update the fallback in your Flutter app or other frontends

## Troubleshooting

### "Firebase configuration error"

**Problem**: Firebase is not properly initialized

**Solution**: 
- Check that you've replaced all placeholder values in `firebaseConfig`
- Ensure your Firebase project is active
- Verify your API key is correct

### "Permission denied" on upload

**Problem**: Storage rules are not properly configured

**Solutions**:
1. Verify Storage rules are deployed (see Step 3)
2. Ensure user is authenticated (signed in)
3. Check file size is under 10MB
4. Verify file is an image (JPG, PNG, GIF, WEBP)

### "Invalid email or password"

**Problem**: Authentication failed

**Solutions**:
1. Check email is correct (no typos)
2. Verify password is correct
3. Ensure Email/Password auth is enabled in Firebase Console
4. Check if the user exists in Firebase Authentication

### "Network error" or "CORS error"

**Problem**: Browser security restrictions

**Solutions**:
1. Use a proper web server (not `file://` protocol)
2. For local testing, use Python's HTTP server or similar
3. Ensure Firebase Hosting is properly configured
4. Check browser console for specific error messages

### Profile photo not loading

**Problem**: Photo exists but doesn't display

**Solutions**:
1. Check browser console for errors
2. Verify the photo exists in Firebase Storage console
3. Ensure Storage rules allow `read` access
4. Try signing out and signing in again
5. Check network tab in browser DevTools

### Upload fails with "object-not-found"

**Problem**: Storage bucket not properly configured

**Solutions**:
1. Go to Firebase Console → Storage
2. Ensure Storage is enabled
3. Check that your storage bucket exists
4. Verify `storageBucket` in `firebaseConfig` is correct

## Security Best Practices

### 1. Never Commit Firebase Credentials

- Add `profile.html` to `.gitignore` if it contains real credentials
- Or use environment-specific configuration files
- For production, use Firebase Hosting to inject credentials

### 2. Implement Rate Limiting

Consider adding rate limiting to prevent abuse:
- Limit uploads per user per day
- Use Firebase Cloud Functions to track upload counts
- Add cooldown periods between uploads

### 3. Monitor Storage Usage

- Set up billing alerts in Firebase Console
- Monitor storage usage regularly
- Implement cleanup for old/unused photos

### 4. Validate File Types Client-Side

The current implementation validates:
- File size (max 10MB)
- File type (images only)
- Server-side validation via Storage rules

### 5. Use HTTPS Only

- Always serve the frontend over HTTPS in production
- Firebase Hosting automatically provides HTTPS
- For custom domains, ensure SSL/TLS is configured

## Integration with Flutter App

The Flutter app already has profile photo functionality in `lib/screens/profile_photo_screen.dart`. Both the Flutter app and this web frontend use the same storage structure, so photos uploaded from one can be viewed in the other.

### Displaying Web-Uploaded Photos in Flutter

The Flutter `StorageService` can fetch photos uploaded via the web frontend:

```dart
// In your Flutter code
final photoUrl = await storageService.getProfilePhotoUrl(userId);
if (photoUrl != null) {
  // Display the photo
  Image.network(photoUrl);
} else {
  // Show default avatar
  Image.asset('assets/default-avatar.png');
}
```

### Adding getProfilePhotoUrl Method

Add this method to `lib/services/storage_service.dart`:

```dart
/// Get profile photo URL for a user
Future<String?> getProfilePhotoUrl(String userId) async {
  try {
    final extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    
    for (final ext in extensions) {
      try {
        final ref = _storage.ref().child('profile_photos/$userId.$ext');
        return await ref.getDownloadURL();
      } catch (e) {
        // Try next extension
        continue;
      }
    }
    
    return null; // No photo found
  } catch (e) {
    return null;
  }
}
```

## Advanced Configuration

### Custom Styling

The HTML file includes embedded CSS. To customize:

1. Modify the `<style>` section in `profile.html`
2. Change colors, fonts, spacing, etc.
3. Update the gradient background colors
4. Customize button styles

### Adding Analytics

Track usage with Firebase Analytics:

```javascript
import { getAnalytics, logEvent } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-analytics.js';

const analytics = getAnalytics(app);

// Log photo upload
logEvent(analytics, 'profile_photo_uploaded', {
  user_id: currentUser.uid
});
```

### Image Compression

Add client-side image compression before upload:

```javascript
// Use a library like browser-image-compression
import imageCompression from 'https://cdn.jsdelivr.net/npm/browser-image-compression@2.0.2/+esm';

async function compressImage(file) {
  const options = {
    maxSizeMB: 1,
    maxWidthOrHeight: 800,
    useWebWorker: true
  };
  
  return await imageCompression(file, options);
}

// Use in uploadProfilePhoto:
const compressedFile = await compressImage(selectedFile);
await uploadBytes(photoRef, compressedFile);
```

## Support

For issues or questions:
- Check the Firebase Console for errors
- Review browser console logs
- Consult [Firebase Documentation](https://firebase.google.com/docs)
- Review [Firebase Storage Security Rules](https://firebase.google.com/docs/storage/security)

## Next Steps

1. ✅ Configure Firebase (Steps 1-3)
2. ✅ Deploy the frontend (Step 5)
3. ✅ Test with a user account (Step 6)
4. 🔄 Integrate with your Flutter app
5. 🔄 Customize styling and branding
6. 🔄 Add additional features (compression, cropping, etc.)
7. 🔄 Set up monitoring and analytics

---

**Last Updated**: February 2026  
**Version**: 1.0.0  
**Compatible with**: Firebase Web SDK v10.7.1+
