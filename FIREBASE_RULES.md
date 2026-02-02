# Firebase Security Rules

This document outlines the Firebase Security Rules for the GUD Express application for Firestore Database and Firebase Storage.

## Firestore Security Rules

These rules ensure that:
- Users can only access data they're authorized to see
- Drivers can only modify their assigned loads
- Admins have full access to all data

### Complete Firestore Rules

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
    
    // Helper function to check if user is a driver
    function isDriver() {
      return request.auth != null &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'driver';
    }
    
    // Users collection
    match /users/{userId} {
      // Users can read their own document, admins can read all
      allow read: if isAuthenticated() && (request.auth.uid == userId || isAdmin());
      // Only admins can create user documents during registration
      // Users can update their own profile
      allow create: if isAdmin();
      allow update: if isAuthenticated() && (request.auth.uid == userId || isAdmin());
      allow delete: if isAdmin();
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
      
      // Drivers can update status, trip times, and miles on their loads
      // Admins can update everything
      allow update: if isAuthenticated() && 
                       (isAdmin() || 
                        (resource.data.driverId == request.auth.uid && 
                         request.resource.data.diff(resource.data).affectedKeys()
                           .hasOnly(['status', 'tripStartAt', 'tripEndAt', 'miles', 'deliveredAt'])));
      
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

These rules control access to files stored in Firebase Storage, including POD images and profile photos.

### Complete Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to validate image file
    function isValidImage() {
      return request.resource.size < 10 * 1024 * 1024 && // Max 10MB
             request.resource.contentType.matches('image/.*');
    }
    
    // POD photos directory
    match /pods/{loadId}/{podImage} {
      // Authenticated users can read POD photos
      allow read: if isAuthenticated();
      
      // Authenticated users can upload POD photos with size and type restrictions
      allow create: if isAuthenticated() && isValidImage();
      
      // Authenticated users can update POD photos
      allow update: if isAuthenticated() && isValidImage();
      
      // Authenticated users can delete POD photos
      allow delete: if isAuthenticated();
    }
    
    // Profile photos directory
    match /profiles/{userId}/{profileImage} {
      // Anyone can read profile photos (for public display)
      allow read: if true;
      
      // Users can only upload/update their own profile photos
      allow create, update: if isAuthenticated() && 
                               request.auth.uid == userId && 
                               isValidImage();
      
      // Users can only delete their own profile photos
      allow delete: if isAuthenticated() && request.auth.uid == userId;
    }
  }
}
```

## Rule Explanation

### Firestore Rules

1. **Users Collection**
   - Users can read their own user document
   - Admins can read all user documents
   - Only admins can create user documents (during driver registration)
   - Users can update their own profiles
   - Only admins can delete user documents

2. **Drivers Collection**
   - All authenticated users can read driver profiles (for load assignment)
   - Only admins can create, update, or delete driver profiles

3. **Loads Collection**
   - Drivers can only read loads assigned to them
   - Admins can read all loads
   - Only admins can create new loads
   - Drivers can update specific fields (status, tripStartAt, tripEndAt, miles, deliveredAt) on their assigned loads
   - Admins can update all fields
   - Only admins can delete loads

4. **POD Subcollection**
   - PODs can be read by the assigned driver and admins
   - PODs can be created by the assigned driver and admins
   - Only admins can update or delete PODs

### Storage Rules

1. **POD Photos Directory (`/pods/{loadId}/{podImage}`)**
   - All authenticated users can read POD photos
   - All authenticated users can create POD photos
   - Maximum file size is 10MB
   - Only image file types are allowed
   - Authenticated users can update/delete POD photos

2. **Profile Photos Directory (`/profiles/{userId}/{profileImage}`)**
   - Anyone can read profile photos (for public display)
   - Users can only upload their own profile photos
   - Maximum file size is 10MB
   - Only image file types are allowed
   - Users can only delete their own profile photos

## Important Security Notes

1. **User Role Verification**: The rules check user roles by reading from the `users` collection. Ensure this collection is properly populated during user creation.

2. **Driver ID Mapping**: The `driverId` field in load documents must match the Firebase Auth UID of the driver.

3. **Initial Admin Setup**: For the first admin user, you may need to:
   - Temporarily relax the rules, OR
   - Manually create the admin user document in the Firebase Console with `role: 'admin'`

4. **Testing**: Always test rules in the Firebase Console's Rules Playground before deploying to production.

## Deploying Rules

### Firestore Rules

1. Open your Firebase Console
2. Navigate to **Firestore Database** → **Rules**
3. Copy and paste the Firestore rules from above
4. Click **Publish**

### Storage Rules

1. Open your Firebase Console
2. Navigate to **Storage** → **Rules**
3. Copy and paste the Storage rules from above
4. Click **Publish**

## Testing Rules

After deploying, test the rules with different user types:

1. **As Admin**:
   - Can create, read, update, and delete all data
   - Can access all loads and PODs
   - Can manage drivers

2. **As Driver**:
   - Can only read own loads
   - Can update status and timestamps on own loads
   - Can upload PODs for own loads
   - Cannot access other drivers' data

3. **Unauthenticated**:
   - Cannot access any data
   - Must sign in to use the app

## Common Issues

1. **"Missing or insufficient permissions" error**:
   - Ensure the user has a document in the `users` collection with a `role` field
   - Check that the `driverId` in loads matches the Firebase Auth UID
   - Verify rules are published correctly

2. **Cannot create first admin**:
   - Manually create the user document in Firebase Console
   - Set `role: 'admin'` in the document
   - Then use the app to sign in

3. **Image upload fails**:
   - Check file size is under 10MB
   - Ensure file type is an image (JPEG, PNG, etc.)
   - Verify user is authenticated
