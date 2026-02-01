# Firebase Security Rules

This document outlines the Firebase Security Rules that should be configured for the GUD Express application.

## Firestore Security Rules

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
      // Drivers can read their own profile, admins can read all
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
      
      // Drivers can update specific fields on their loads
      allow update: if isAuthenticated() && 
                       (isAdmin() || 
                        (resource.data.driverId == request.auth.uid && 
                         request.resource.data.diff(resource.data).affectedKeys()
                           .hasOnly(['status', 'tripStartTime', 'tripEndTime'])));
      
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

## Firebase Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // POD photos
    match /pods/{podImage} {
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

## Rule Explanation

### Firestore Rules

1. **Users Collection**
   - Users can read their own user document
   - Admins can read all user documents
   - Only admins can create or update user documents

2. **Drivers Collection**
   - All authenticated users can read driver profiles
   - Only admins can create, update, or delete driver profiles

3. **Loads Collection**
   - Drivers can only read loads assigned to them
   - Admins can read all loads
   - Only admins can create new loads
   - Drivers can update specific fields (status, tripStartTime, tripEndTime) on their assigned loads
   - Only admins can delete loads

4. **POD Subcollection**
   - PODs can be read by the assigned driver and admins
   - PODs can be created by the assigned driver and admins
   - Only admins can update or delete PODs

### Storage Rules

1. **POD Photos**
   - All authenticated users can read POD photos
   - All authenticated users can upload POD photos
   - Maximum file size is 10MB
   - Only image file types are allowed

## Important Notes

- These rules assume that driver documents have a `userId` field that matches the Firebase Auth UID
- The load document's `driverId` field should match the driver document ID, not the Firebase Auth UID
- For the initial setup, you may need to temporarily relax these rules to create the first admin user
- Always test these rules in the Firebase Console's Rules Playground before deploying to production

## Deploying Rules

1. Open your Firebase Console
2. Navigate to Firestore Database → Rules
3. Copy and paste the Firestore rules
4. Click "Publish"
5. Navigate to Storage → Rules
6. Copy and paste the Storage rules
7. Click "Publish"
