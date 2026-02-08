# Admin User Setup Guide

This document explains how to manually set up admin users in Firebase Firestore for the GUD Express app.

## Overview

The login system checks the `isAdmin` field in Firestore to determine whether a user should be routed to the Admin Dashboard or User Dashboard after authentication.

## Setting Up Admin Users

### Step 1: Create a User with Firebase Authentication

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** > **Users**
4. Click **Add User**
5. Enter the email and password for the admin user
6. Click **Add User** and note the **User UID**

### Step 2: Create User Document in Firestore

1. In the Firebase Console, navigate to **Firestore Database**
2. Go to the `users` collection (create it if it doesn't exist)
3. Click **Add Document**
4. Set the **Document ID** to the **User UID** from Step 1
5. Add the following fields:
   - `isAdmin` (boolean): `true` for admin users, `false` for regular users
   - `email` (string): The user's email address
   - `name` (string): The user's display name (optional)
   - `createdAt` (timestamp): Current timestamp (optional)

**Example Firestore Document Structure:**

```
Collection: users
Document ID: [User UID from Authentication]
Fields:
  - isAdmin: true (boolean)
  - email: "admin@example.com" (string)
  - name: "Admin User" (string)
  - createdAt: [timestamp] (timestamp)
```

### Step 3: Test the Login

1. Launch the GUD Express app
2. Enter the admin user's email and password
3. Click **Sign In**
4. If `isAdmin` is `true`, you should be routed to the **Admin Dashboard**
5. If `isAdmin` is `false` or missing, you will be routed to the **User Dashboard**

## Security Considerations

### Firestore Security Rules

Make sure to set up proper Firestore security rules to protect the `isAdmin` field:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // Users can read their own document
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Only allow writes that don't modify the isAdmin field unless done by an admin
      allow write: if request.auth != null && 
                     request.auth.uid == userId &&
                     (!('isAdmin' in request.resource.data) || 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true);
    }
  }
}
```

**Important:** The `isAdmin` field should only be set manually by administrators through the Firebase Console or Cloud Functions. Regular users should not be able to modify this field.

## Production Authentication

The app now requires Firebase Authentication to be properly configured. Demo credentials have been removed for production readiness.

To set up authentication:
1. Configure Firebase Authentication in your Firebase project
2. Create user accounts through Firebase Console or your admin tools
3. Set the `isAdmin` field appropriately for admin users in Firestore

## Troubleshooting

### User is not being routed correctly
1. Verify the user document exists in Firestore with the correct UID
2. Check that the `isAdmin` field is set to `true` (boolean, not string)
3. Ensure Firebase is properly initialized in the app

### Cannot query Firestore
1. Check Firebase initialization in `main.dart`
2. Verify internet connectivity
3. Check Firestore security rules allow read access for authenticated users

### Authentication fails
1. Verify the email and password are correct
2. Check that the user exists in Firebase Authentication
3. Review Firebase Authentication settings in the console

## Future Enhancements

For production use, consider implementing:
- Cloud Functions to automatically set `isAdmin` based on business logic
- Admin panel to manage user roles
- Role-based access control with multiple roles (admin, manager, driver, etc.)
- Audit logging for admin privilege changes
