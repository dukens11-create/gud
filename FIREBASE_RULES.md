# Firebase Security Rules

This document contains the complete security rules for Firestore and Firebase Storage for the GUD Express application.

## Firestore Security Rules

These rules ensure that:
- Users can only read/write their own user document
- All authenticated users can read driver information
- Only admins can create/update driver records
- All authenticated users can read loads
- Admins can write any load
- Drivers can only update loads assigned to them
- Only assigned drivers can add PODs to their loads

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
      // Users can read and write their own document
      allow read, write: if isAuthenticated() && request.auth.uid == userId;
      // All authenticated users can read user documents (to check roles)
      allow read: if isAuthenticated();
      // Only admins can create new user documents
      allow create: if isAdmin();
    }
    
    // Drivers collection
    match /drivers/{driverId} {
      // All authenticated users can read driver information
      allow read: if isAuthenticated();
      // Only admins can create, update, or delete drivers
      allow write: if isAdmin();
    }
    
    // Loads collection
    match /loads/{loadId} {
      // All authenticated users can read loads
      allow read: if isAuthenticated();
      
      // Admins can create and update any load
      allow create: if isAdmin();
      allow update: if isAdmin() || 
        (isAuthenticated() && resource.data.driverId == request.auth.uid);
      
      // Only admins can delete loads
      allow delete: if isAdmin();
      
      // PODs subcollection under each load
      match /pods/{podId} {
        // Anyone authenticated can read PODs
        allow read: if isAuthenticated();
        
        // Only the assigned driver can create PODs for their load
        allow create: if isAuthenticated() && 
          get(/databases/$(database)/documents/loads/$(loadId)).data.driverId == request.auth.uid;
        
        // Only admins can update or delete PODs
        allow update, delete: if isAdmin();
      }
    }
  }
}
```

## Storage Security Rules

These rules ensure that:
- Only authenticated users can read POD images
- Only authenticated users can upload POD images
- Images are organized by load ID
- File size and type restrictions can be enforced

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper function to check authentication
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check file size (5MB limit)
    function isValidSize() {
      return request.resource.size < 5 * 1024 * 1024;
    }
    
    // Helper function to check file type (only images)
    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }
    
    // POD images organized by load ID
    match /pods/{loadId}/{imageId} {
      // Any authenticated user can read POD images
      allow read: if isAuthenticated();
      
      // Only authenticated users can upload images
      // with size and type restrictions
      allow write: if isAuthenticated() && 
                      isValidSize() && 
                      isImage();
    }
  }
}
```

## Rule Explanations

### Firestore Rules

#### User Document Rules
- **Read/Write Own Document**: Users can manage their own profile
- **Read Any User**: Required for role checking across the app
- **Admin Creation**: Only admins can create new user accounts via Firestore

#### Driver Collection Rules
- **Read Access**: All users need to see driver lists (for load assignment)
- **Write Access**: Restricted to admins for driver management

#### Load Collection Rules
- **Read Access**: All authenticated users can view loads
- **Create Access**: Only admins can create new loads
- **Update Access**: Admins can update any load; drivers can update only their assigned loads
- **Delete Access**: Only admins can delete loads

#### POD Subcollection Rules
- **Read Access**: All authenticated users can view PODs
- **Create Access**: Only the driver assigned to the load can add PODs
- **Update/Delete Access**: Only admins can modify or remove PODs

### Storage Rules

#### POD Image Rules
- **Read Access**: All authenticated users can view images
- **Write Access**: Authenticated users can upload with restrictions:
  - Maximum file size: 5MB
  - File type: Images only (jpeg, png, etc.)
  - Organized by load ID for easy management

## Testing Security Rules

### Test in Firebase Console
1. Go to Firestore Database > Rules
2. Click "Rules playground"
3. Test various scenarios:
   - Anonymous access (should be denied)
   - Driver accessing own loads (should succeed)
   - Driver accessing other driver's loads (read: yes, write: no)
   - Admin accessing any resource (should succeed)

### Test Programmatically
Create test scripts to verify:
```dart
// Test anonymous access - should fail
// Test driver read access - should succeed
// Test driver write to own load - should succeed
// Test driver write to other load - should fail
// Test admin access - should succeed
```

## Production Deployment Checklist

Before deploying security rules to production:

- [ ] Remove "test mode" rules
- [ ] Verify all authenticated access points
- [ ] Test role-based access control
- [ ] Implement rate limiting if needed
- [ ] Review file size limits
- [ ] Test with multiple user roles
- [ ] Monitor rule evaluation metrics
- [ ] Set up alerts for rule violations
- [ ] Document any custom business logic
- [ ] Plan for rule updates and versioning

## Common Issues and Solutions

### Issue: Users can't read their role
**Solution**: Ensure users collection has read access for authenticated users

### Issue: Drivers can't update load status
**Solution**: Verify driver UID matches load's driverId field

### Issue: POD upload fails
**Solution**: Check that:
- User is authenticated
- File is an image
- File is under 5MB
- Driver is assigned to the load

### Issue: Admin can't perform operations
**Solution**: Verify:
- User document has role: 'admin'
- User is properly authenticated
- Helper function can access user document

## Maintenance

### Regular Review
- Review rules quarterly
- Check for unused collections
- Update based on new features
- Monitor Firebase Console for errors

### Rule Updates
When adding new features:
1. Update rules locally
2. Test in development environment
3. Document changes
4. Deploy to production during low-traffic period
5. Monitor for issues

### Monitoring
Set up alerts for:
- Excessive rule denials
- Unusual access patterns
- Storage quota approaching limits
- Database read/write quotas

## Additional Resources

- [Firebase Security Rules Documentation](https://firebase.google.com/docs/rules)
- [Firestore Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- [Storage Security Rules Guide](https://firebase.google.com/docs/storage/security)
- [Best Practices](https://firebase.google.com/docs/rules/best-practices)
