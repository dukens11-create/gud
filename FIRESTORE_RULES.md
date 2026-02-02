# Firestore Security Rules

Complete Firestore security rules for the GUD Express Trucking Management application.

## Quick Deploy

Copy the entire rules block below and paste it into your Firestore Rules editor in the Firebase Console.

---

## Complete Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ==========================================
    // Helper Functions
    // ==========================================
    
    // Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Check if user is admin
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Check if user is a driver
    function isDriver() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'driver';
    }
    
    // Check if user owns the resource
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // ==========================================
    // Collection Rules
    // ==========================================
    
    // Users collection - stores user profiles and roles
    match /users/{userId} {
      // Users can read their own profile, admins can read all profiles
      allow read: if isOwner(userId) || isAdmin();
      
      // Only admins can create or update user profiles
      allow create, update: if isAdmin();
      
      // Nobody can delete user profiles (use admin console if needed)
      allow delete: if false;
    }
    
    // Drivers collection - stores driver-specific information
    match /drivers/{driverId} {
      // All authenticated users can read driver information
      // (needed for admin to see driver list, and for assignment dropdowns)
      allow read: if isAuthenticated();
      
      // Only admins can create new drivers
      allow create: if isAdmin();
      
      // Admins can update any driver, drivers can update their own status
      allow update: if isAdmin() || (isDriver() && isOwner(driverId));
      
      // Only admins can delete drivers
      allow delete: if isAdmin();
    }
    
    // Loads collection - stores load/shipment information
    match /loads/{loadId} {
      // Drivers can only see their assigned loads, admins can see all
      allow read: if isAuthenticated() && 
                     (isAdmin() || resource.data.driverId == request.auth.uid);
      
      // Only admins can create new loads
      allow create: if isAdmin();
      
      // Drivers can update status on their assigned loads, admins can update any load
      allow update: if isAuthenticated() && 
                       (isAdmin() || 
                        (resource.data.driverId == request.auth.uid && 
                         request.auth.uid != null));
      
      // Only admins can delete loads
      allow delete: if isAdmin();
      
      // POD (Proof of Delivery) subcollection
      match /pods/{podId} {
        // PODs can be read by the assigned driver and admins
        allow read: if isAuthenticated() && 
                       (isAdmin() || 
                        get(/databases/$(database)/documents/loads/$(loadId)).data.driverId == request.auth.uid);
        
        // PODs can be created by the assigned driver and admins
        allow create: if isAuthenticated() && 
                         (isAdmin() || 
                          get(/databases/$(database)/documents/loads/$(loadId)).data.driverId == request.auth.uid);
        
        // Only admins can update or delete PODs
        allow update, delete: if isAdmin();
      }
    }
  }
}
```

---

## Rule Breakdown

### Helper Functions

#### `isAuthenticated()`
- Checks if user has valid Firebase Authentication token
- Required for all operations

#### `isAdmin()`
- Checks if authenticated user has admin role
- Queries the user's document in `/users/{uid}` collection
- Admin role grants full access to all data

#### `isDriver()`
- Checks if authenticated user has driver role
- Used for driver-specific permissions

#### `isOwner(userId)`
- Checks if authenticated user ID matches the provided userId
- Used for self-access permissions

---

## Collection-Specific Rules

### `/users/{userId}`

**Purpose**: Store user profiles and role information

**Read Access**:
- ✅ Users can read their own profile
- ✅ Admins can read all profiles
- ❌ Users cannot read other users' profiles

**Write Access**:
- ✅ Admins can create new users
- ✅ Admins can update user profiles
- ❌ Users cannot modify their own profiles
- ❌ Nobody can delete profiles (admin console only)

**Fields**:
- `role`: "admin" or "driver"
- `name`: User's full name
- `email`: User's email address
- `phone`: Contact phone number
- `truckNumber`: Truck identification (drivers only)
- `isActive`: Account status
- `createdAt`: Account creation timestamp

---

### `/drivers/{driverId}`

**Purpose**: Store driver-specific information and status

**Read Access**:
- ✅ All authenticated users can read (for dropdowns, lists)
- ❌ Unauthenticated users cannot read

**Write Access**:
- ✅ Admins can create, update, and delete drivers
- ✅ Drivers can update their own status
- ❌ Drivers cannot create or delete driver records

**Fields**:
- `name`: Driver's name
- `phone`: Contact number
- `truckNumber`: Truck identification
- `status`: "available", "on_trip", or "inactive"
- `createdAt`: Driver creation timestamp

---

### `/loads/{loadId}`

**Purpose**: Store load/shipment information

**Read Access**:
- ✅ Admins can read all loads
- ✅ Drivers can read only their assigned loads
- ❌ Drivers cannot see other drivers' loads

**Write Access**:
- ✅ Admins can create, update, and delete loads
- ✅ Drivers can update their assigned loads (status, timestamps)
- ❌ Drivers cannot create or delete loads

**Fields**:
- `loadNumber`: Unique load identifier
- `driverId`: Assigned driver's UID
- `driverName`: Driver's name (denormalized for convenience)
- `pickupAddress`: Pickup location
- `deliveryAddress`: Delivery destination
- `rate`: Payment amount
- `miles`: Distance traveled
- `status`: "assigned", "picked_up", "in_transit", "delivered"
- `notes`: Additional information
- `createdBy`: Admin UID who created the load
- `createdAt`: Load creation timestamp
- `pickedUpAt`: Pickup timestamp
- `tripStartAt`: Trip start timestamp
- `deliveredAt`: Delivery completion timestamp

---

### `/loads/{loadId}/pods/{podId}`

**Purpose**: Store proof of delivery documents

**Read Access**:
- ✅ Assigned driver can read PODs for their load
- ✅ Admins can read all PODs
- ❌ Other drivers cannot see PODs

**Write Access**:
- ✅ Assigned driver can create PODs for their load
- ✅ Admins can create, update, and delete PODs
- ❌ Drivers cannot update or delete PODs after creation

**Fields**:
- `loadId`: Parent load ID
- `imageUrl`: Firebase Storage URL of POD image
- `notes`: Additional delivery notes
- `uploadedBy`: User UID who uploaded
- `uploadedAt`: Upload timestamp

---

## Testing Your Rules

### Using Firebase Console Rules Playground

1. Navigate to Firestore Database → Rules tab
2. Click "Rules Playground" button
3. Test different scenarios

### Test Scenarios

#### ✅ Should Succeed

```javascript
// Admin reading all loads
Simulate: get /loads/{anyLoadId}
Auth: Authenticated as admin
Result: Allow

// Driver reading their own load
Simulate: get /loads/{loadId}
Auth: Authenticated as driver (uid matches load.driverId)
Result: Allow

// Driver creating POD for their load
Simulate: create /loads/{loadId}/pods/{newPodId}
Auth: Authenticated as driver (uid matches load.driverId)
Result: Allow

// Admin creating new load
Simulate: create /loads/{newLoadId}
Auth: Authenticated as admin
Result: Allow
```

#### ❌ Should Fail

```javascript
// Unauthenticated reading loads
Simulate: get /loads/{loadId}
Auth: Not authenticated
Result: Deny

// Driver reading another driver's load
Simulate: get /loads/{loadId}
Auth: Authenticated as driver (uid does NOT match load.driverId)
Result: Deny

// Driver creating a new load
Simulate: create /loads/{newLoadId}
Auth: Authenticated as driver
Result: Deny

// Driver deleting a load
Simulate: delete /loads/{loadId}
Auth: Authenticated as driver
Result: Deny
```

---

## Deployment Instructions

### Step 1: Open Firebase Console
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Select your project

### Step 2: Navigate to Firestore Rules
1. Click on "Firestore Database" in the left sidebar
2. Click on the "Rules" tab at the top

### Step 3: Replace Rules
1. Select all existing rules (Ctrl+A or Cmd+A)
2. Delete existing rules
3. Copy the complete rules from this document
4. Paste into the editor

### Step 4: Publish
1. Click the "Publish" button
2. Wait for confirmation message
3. Rules are now active

### Step 5: Verify
1. Click "Rules Playground" button
2. Test several scenarios as described above
3. Verify expected behavior

---

## Common Issues

### Issue: Permission Denied for Driver

**Cause**: Driver document doesn't exist or driverId doesn't match uid

**Solution**:
1. Verify driver document exists in `/users/{uid}`
2. Check that `role` field is set to "driver"
3. Verify load's `driverId` field matches driver's UID

### Issue: Admin Cannot Access Data

**Cause**: User role not set to "admin"

**Solution**:
1. Check user document in `/users/{uid}`
2. Verify `role` field is set to "admin"
3. Re-authenticate if recently changed

### Issue: Cannot Create First Admin

**Solution**: Manually create through Firebase Console
1. Go to Authentication → Users
2. Create user with email/password
3. Go to Firestore Database → Data
4. Create document in `users` collection
5. Set document ID to the user's UID
6. Add field: `role` = "admin"

---

## Security Best Practices

1. **Never Relax Rules in Production**
   - Always test changes in development first
   - Use strict rules even during development when possible

2. **Regular Audits**
   - Review rules quarterly
   - Check Firebase usage logs for suspicious activity
   - Update rules as features change

3. **Principle of Least Privilege**
   - Grant minimum necessary permissions
   - Don't give drivers admin access
   - Restrict deletion operations

4. **Validate Data on Write**
   - Consider adding field validation
   - Check required fields exist
   - Validate data types and ranges

5. **Monitor Performance**
   - Complex rules can impact performance
   - Test with realistic data volumes
   - Use indexes for queried fields

---

## Support

For issues or questions:
- Review [Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- Check [Firebase Console](https://console.firebase.google.com)
- Review application logs in Firebase Console

---

**Last Updated**: 2026-02-02  
**Version**: 1.0  
**Compatibility**: Firebase Firestore, GUD Express v1.0+
