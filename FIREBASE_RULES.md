# Firebase Security Rules

This document outlines the Firebase Security Rules for the GUD Express Trucking Management application.

## Overview

These security rules ensure that:
- Only authenticated users can access the application
- Users can only access data they're authorized to see
- Admins have full access to manage the system
- Drivers can only see and update their assigned loads

---

## Firestore Security Rules

Deploy these rules to your Firestore Database:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is admin
    function isAdmin() {
      return request.auth != null && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Users collection
    match /users/{userId} {
      // Users can read their own document, admins can read all
      allow read: if isAuthenticated() && (request.auth.uid == userId || isAdmin());
      // Only admins can create/update user documents
      allow write: if isAdmin();
    }
    
    // Drivers collection
    match /drivers/{driverId} {
      // All authenticated users can read driver profiles
      allow read: if isAuthenticated();
      // Only admins can create/update/delete drivers
      allow create, update, delete: if isAdmin();
    }
    
    // Loads collection
    match /loads/{loadId} {
      // Drivers can only see their assigned loads, admins can see all
      allow read: if isAuthenticated() && 
                     (isAdmin() || resource.data.driverId == request.auth.uid);
      
      // Only admins can create loads
      allow create: if isAdmin();
      
      // Drivers can update their assigned loads, admins can update all
      allow update: if isAuthenticated() && 
                       (isAdmin() || resource.data.driverId == request.auth.uid);
      
      // Only admins can delete loads
      allow delete: if isAdmin();
      
      // POD subcollection
      match /pods/{podId} {
        // PODs can be read by the assigned driver and admins
        allow read: if isAuthenticated() && 
                       (isAdmin() || 
                        get(/databases/$(database)/documents/loads/$(loadId)).data.driverId == request.auth.uid);
        
        // PODs can be created by the assigned driver and admins
        allow create: if isAuthenticated() && 
                         (isAdmin() || 
                          get(/databases/$(database)/documents/loads/$(loadId)).data.driverId == request.auth.uid);
        
        // PODs can be updated/deleted by admins only
        allow update, delete: if isAdmin();
      }
    }
  }
}
```

---

## Firebase Storage Security Rules

Deploy these rules to your Firebase Storage:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // POD photos - stored in pods/{loadId}/{filename}
    match /pods/{loadId}/{fileName} {
      // Authenticated users can read POD photos
      allow read: if request.auth != null;
      
      // Authenticated users can upload POD photos
      allow write: if request.auth != null &&
                      request.resource.size < 10 * 1024 * 1024 && // Max 10MB
                      request.resource.contentType.matches('image/.*');
    }
  }
}
```

---

## Rule Explanations

### Firestore Rules

#### 1. Users Collection (`/users/{userId}`)
- **Read**: Users can read their own document; admins can read all
- **Write**: Only admins can create or update user documents
- **Purpose**: Protect user profile data and ensure role-based access

#### 2. Drivers Collection (`/drivers/{driverId}`)
- **Read**: All authenticated users can view driver information
- **Write**: Only admins can manage driver profiles
- **Purpose**: Allow load assignment dropdown to work while protecting data integrity

#### 3. Loads Collection (`/loads/{loadId}`)
- **Read**: Drivers see only their assigned loads; admins see all
- **Write Create**: Only admins can create new loads
- **Write Update**: Drivers can update their assigned loads; admins can update any load
- **Write Delete**: Only admins can delete loads
- **Purpose**: Implement proper data access and modification controls

#### 4. POD Subcollection (`/loads/{loadId}/pods/{podId}`)
- **Read**: Assigned driver and admins can view PODs
- **Create**: Assigned driver and admins can upload PODs
- **Update/Delete**: Only admins can modify or remove PODs
- **Purpose**: Allow drivers to upload delivery proof while maintaining data integrity

### Storage Rules

#### POD Photos (`/pods/{loadId}/{fileName}`)
- **Read**: All authenticated users can view photos
- **Write**: Authenticated users can upload images up to 10MB
- **File Type**: Only image files allowed
- **Purpose**: Secure storage of proof of delivery photographs

---

## Deploying Rules

### Firestore Rules Deployment

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Rules** tab
4. Copy and paste the Firestore rules above
5. Click **Publish**
6. Wait for confirmation

### Storage Rules Deployment

1. In Firebase Console
2. Navigate to **Storage** → **Rules** tab
3. Copy and paste the Storage rules above
4. Click **Publish**
5. Wait for confirmation

---

## Testing Rules

### Using Rules Playground

1. In Firestore Rules tab, click **Rules Playground**
2. Test various scenarios:
   - Admin reading all loads
   - Driver reading only their loads
   - Driver trying to read another driver's load (should fail)
   - Unauthenticated user trying to access data (should fail)

### Test Scenarios

#### ✅ Should Allow
- Admin user reading `/loads` collection
- Driver with uid `abc123` reading `/loads` where `driverId == 'abc123'`
- Authenticated user uploading image to `/pods/{loadId}/{filename}`
- Driver updating status on their assigned load

#### ❌ Should Deny
- Unauthenticated user reading any collection
- Driver reading another driver's load
- Driver creating a new load
- Driver deleting a load
- Uploading non-image files to storage
- Uploading files larger than 10MB

---

## Important Security Notes

1. **Authentication Required**: All rules require authentication. Users must be logged in.

2. **Role-Based Access**: The system distinguishes between admin and driver roles based on the `role` field in `/users/{uid}` documents.

3. **Driver Assignment**: The `driverId` field in load documents should match the Firebase Auth UID of the assigned driver.

4. **First Admin User**: You must manually create the first admin user through the Firebase Console (see FIREBASE_SETUP.md).

5. **Production Considerations**:
   - Review and test all rules before production deployment
   - Monitor Firebase usage and set up billing alerts
   - Regularly audit security rules
   - Keep backup of Firestore data

6. **File Size Limits**: Storage rules limit POD photos to 10MB. Adjust if needed.

7. **Testing**: Always test rules in a development environment before deploying to production.

---

## Troubleshooting

### "Permission Denied" Errors

**Symptom**: User gets permission denied when accessing Firestore

**Solutions**:
1. Verify user is authenticated (`FirebaseAuth.instance.currentUser != null`)
2. Check user document exists in `/users/{uid}` with correct `role` field
3. Verify the `driverId` in load documents matches the user's UID
4. Test rules in Firebase Console Rules Playground

### POD Upload Fails

**Symptom**: Image upload to Storage fails

**Solutions**:
1. Ensure user is authenticated
2. Check image file size is under 10MB
3. Verify file is an image type
4. Check Storage rules are published correctly

### Cannot Create First Admin

**Solution**: Temporarily modify rules or create admin user and document manually through Firebase Console (detailed steps in FIREBASE_SETUP.md).

---

## Updates and Maintenance

- **Last Updated**: 2026-02-02
- **Version**: 1.0
- **Review Schedule**: Quarterly security audit recommended

For setup instructions, see [FIREBASE_SETUP.md](./FIREBASE_SETUP.md)

