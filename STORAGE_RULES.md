# Firebase Storage Security Rules

Complete Firebase Storage security rules for the GUD Express Trucking Management application.

## Quick Deploy

Copy the entire rules block below and paste it into your Storage Rules editor in the Firebase Console.

---

## Complete Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // ==========================================
    // Helper Functions
    // ==========================================
    
    // Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Check if uploaded file is an image
    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }
    
    // Check if file size is within limit (10MB)
    function isValidSize() {
      return request.resource.size < 10 * 1024 * 1024;
    }
    
    // ==========================================
    // Storage Path Rules
    // ==========================================
    
    // POD (Proof of Delivery) images
    // Path structure: /pods/{loadId}/{fileName}
    match /pods/{loadId}/{fileName} {
      // Anyone authenticated can read POD images
      allow read: if isAuthenticated();
      
      // Authenticated users can upload POD images
      // Must be an image file under 10MB
      allow write: if isAuthenticated() && 
                      isImage() && 
                      isValidSize();
      
      // Allow deletion only by authenticated users
      // (typically handled by admins through app logic)
      allow delete: if isAuthenticated();
    }
    
    // Catch-all: deny access to all other paths
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## Rule Breakdown

### Helper Functions

#### `isAuthenticated()`
**Purpose**: Verify user has valid Firebase Authentication token

**Returns**: 
- `true` if user is logged in
- `false` if user is not authenticated

**Usage**: Required for all storage operations

---

#### `isImage()`
**Purpose**: Verify uploaded file is an image

**Returns**:
- `true` if file MIME type starts with "image/"
- `false` for other file types

**Allowed Types**:
- ✅ image/jpeg
- ✅ image/png
- ✅ image/gif
- ✅ image/webp
- ✅ image/heic
- ❌ application/pdf
- ❌ video/*
- ❌ application/*

---

#### `isValidSize()`
**Purpose**: Verify file size is within acceptable limits

**Returns**:
- `true` if file is less than 10MB
- `false` if file exceeds 10MB

**Limit**: 10 MB (10,485,760 bytes)

**Rationale**: 
- Prevents abuse and excessive storage costs
- Reasonable size for high-quality POD photos
- Mobile cameras typically produce 2-5MB images

---

## Path-Specific Rules

### `/pods/{loadId}/{fileName}`

**Purpose**: Store Proof of Delivery (POD) photographs

**Path Structure**:
```
/pods/
  ├── LOAD-001/
  │   ├── POD_LOAD-001_1709380800000.jpg
  │   └── POD_LOAD-001_1709381200000.jpg
  ├── LOAD-002/
  │   └── POD_LOAD-002_1709382600000.jpg
  └── LOAD-003/
      └── POD_LOAD-003_1709383800000.jpg
```

**File Naming Convention**:
- Format: `POD_{loadId}_{timestamp}.jpg`
- Example: `POD_LOAD-001_1709380800000.jpg`
- Timestamp ensures unique filenames

**Read Access**:
- ✅ All authenticated users can read POD images
- ❌ Unauthenticated users cannot access images
- **Rationale**: Admins and drivers need to view PODs

**Write Access**:
- ✅ Authenticated users can upload new POD images
- ✅ Must be a valid image file
- ✅ Must be under 10MB
- ❌ Files exceeding size limit rejected
- ❌ Non-image files rejected
- **Rationale**: Drivers upload PODs after delivery

**Delete Access**:
- ✅ Authenticated users can delete PODs
- **Note**: App logic should restrict this to admins only
- **Rationale**: Allow cleanup of incorrect uploads

---

### Catch-All Rule (`/{allPaths=**}`)

**Purpose**: Explicitly deny access to any unlisted storage paths

**Effect**:
- ❌ Blocks access to unexpected paths
- ❌ Prevents directory traversal attempts
- ❌ Blocks access to future folders without explicit rules

**Security**: Defense in depth - deny by default

---

## Security Features

### 1. Authentication Required
- All operations require valid Firebase Auth token
- No anonymous access allowed
- Prevents unauthorized data access

### 2. File Type Validation
- Only image files accepted for PODs
- Prevents malicious file uploads
- Ensures consistent data format

### 3. File Size Limits
- Maximum 10MB per file
- Prevents storage abuse
- Controls bandwidth usage

### 4. Path Restrictions
- Only `/pods/{loadId}/` path accessible
- No root-level file access
- Organized storage structure

### 5. Explicit Deny
- Unlisted paths blocked by default
- Prevents accidental exposure
- Requires explicit rules for new features

---

## Testing Your Rules

### Using Firebase Console Storage Rules Playground

Unfortunately, Storage doesn't have a built-in playground like Firestore. Test using the emulator or actual uploads.

### Manual Testing Steps

#### Test 1: Upload Valid POD
```dart
// Should succeed
StorageService().uploadPodImage(
  loadId: 'LOAD-001',
  file: validImageFile, // 5MB JPEG
);
```

#### Test 2: Upload Oversized File
```dart
// Should fail
StorageService().uploadPodImage(
  loadId: 'LOAD-001',
  file: largeImageFile, // 15MB JPEG
);
// Error: File size exceeds limit
```

#### Test 3: Upload Non-Image File
```dart
// Should fail
StorageService().uploadPodImage(
  loadId: 'LOAD-001',
  file: pdfFile, // PDF document
);
// Error: Invalid file type
```

#### Test 4: Unauthenticated Access
```dart
// Should fail
await FirebaseAuth.instance.signOut();
StorageService().uploadPodImage(
  loadId: 'LOAD-001',
  file: validImageFile,
);
// Error: Permission denied
```

---

## Deployment Instructions

### Step 1: Open Firebase Console
1. Navigate to [console.firebase.google.com](https://console.firebase.google.com)
2. Select your GUD Express project

### Step 2: Access Storage Rules
1. Click "Storage" in the left sidebar
2. Click the "Rules" tab at the top

### Step 3: Update Rules
1. You'll see the current rules in the editor
2. Select all text (Ctrl+A or Cmd+A)
3. Delete existing rules
4. Copy the complete rules from this document
5. Paste into the editor

### Step 4: Validate Rules
1. Check for syntax errors (red underlines)
2. Review the rules one more time
3. Ensure proper formatting

### Step 5: Publish
1. Click the "Publish" button
2. Confirm the action if prompted
3. Wait for "Rules published successfully" message

### Step 6: Verify
1. Test file upload through your app
2. Try uploading different file types
3. Test with and without authentication
4. Verify proper error messages

---

## Common Issues and Solutions

### Issue: "Permission Denied" on Upload

**Possible Causes**:
1. User not authenticated
2. File is not an image
3. File exceeds 10MB
4. Wrong storage path

**Solutions**:
```dart
// Verify authentication
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  print('User not authenticated');
  return;
}

// Check file size
if (file.lengthSync() > 10 * 1024 * 1024) {
  print('File too large');
  return;
}

// Verify file type
if (!file.path.endsWith('.jpg') && !file.path.endsWith('.png')) {
  print('Invalid file type');
  return;
}
```

---

### Issue: Cannot Download POD Images

**Possible Causes**:
1. User not authenticated
2. Incorrect file path
3. File doesn't exist

**Solutions**:
```dart
// Get download URL
try {
  final ref = FirebaseStorage.instance.ref().child('pods/LOAD-001/image.jpg');
  final url = await ref.getDownloadURL();
  print('URL: $url');
} catch (e) {
  print('Error: $e');
  // Check authentication and path
}
```

---

### Issue: Rules Not Taking Effect

**Possible Causes**:
1. Rules not published
2. Caching in app/browser
3. Syntax errors in rules

**Solutions**:
1. Re-publish rules in Firebase Console
2. Clear app cache and restart
3. Check for red syntax errors in rules editor
4. Test in incognito/private browser window

---

### Issue: Storage Costs High

**Possible Causes**:
1. Too many large files
2. Files not being deleted
3. Duplicate uploads

**Solutions**:
1. Reduce file size limit if 10MB is too generous
2. Implement cleanup for failed loads
3. Add app logic to prevent duplicate uploads
4. Monitor Storage usage in Firebase Console

---

## Best Practices

### 1. File Optimization
Before upload:
```dart
// Compress images in app before upload
final compressedFile = await compressImage(
  file,
  maxWidth: 1920,
  maxHeight: 1080,
  quality: 85,
);
```

### 2. Unique Filenames
Always use unique filenames:
```dart
final fileName = 'POD_${loadId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
```

### 3. Error Handling
Handle storage errors gracefully:
```dart
try {
  await storageService.uploadPodImage(...);
} on FirebaseException catch (e) {
  if (e.code == 'unauthorized') {
    // Handle authentication error
  } else if (e.code == 'object-not-found') {
    // Handle missing file error
  }
}
```

### 4. Progress Tracking
Show upload progress:
```dart
final uploadTask = ref.putFile(file);
uploadTask.snapshotEvents.listen((snapshot) {
  final progress = snapshot.bytesTransferred / snapshot.totalBytes;
  print('Upload: ${(progress * 100).toStringAsFixed(2)}%');
});
```

### 5. Metadata
Add useful metadata:
```dart
await ref.putFile(
  file,
  SettableMetadata(
    contentType: 'image/jpeg',
    customMetadata: {
      'loadId': loadId,
      'uploadedBy': userId,
      'uploadDate': DateTime.now().toIso8601String(),
    },
  ),
);
```

### 6. Cleanup on Delete
Delete storage files when load is deleted:
```dart
// In FirestoreService.deleteLoad()
final pods = await getPods(loadId);
for (final pod in pods) {
  await StorageService().deletePOD(pod.imageUrl);
}
```

---

## File Size Guidelines

### Recommended Limits by Use Case

| Use Case | Max Size | Reasoning |
|----------|----------|-----------|
| POD Photos | 10 MB | High-quality photos from modern phones |
| Compressed PODs | 5 MB | After app-side compression |
| Thumbnails | 500 KB | For list views and previews |

### Adjusting File Size Limit

To change the 10MB limit:
```javascript
// Change this line in the rules
function isValidSize() {
  return request.resource.size < 5 * 1024 * 1024; // 5MB
}
```

---

## Monitoring and Maintenance

### Check Storage Usage
1. Firebase Console → Storage
2. Review "Usage" tab
3. Monitor trends over time

### Set Up Alerts
1. Firebase Console → Project Settings
2. Set up billing alerts
3. Get notified of unusual usage

### Regular Cleanup
Consider implementing:
- Delete PODs for loads older than X months
- Remove duplicate uploads
- Archive old data to cheaper storage

---

## Advanced Configurations

### Allow Different File Types per Path

```javascript
match /pods/{loadId}/{fileName} {
  allow write: if isAuthenticated() && 
                  (isImage() || isPDF()) && 
                  isValidSize();
}

function isPDF() {
  return request.resource.contentType == 'application/pdf';
}
```

### Per-User Upload Limits

```javascript
// Limit users to 100MB total
match /pods/{loadId}/{fileName} {
  allow write: if isAuthenticated() && 
                  isImage() && 
                  isValidSize() &&
                  // Check user's total storage usage
                  getUserStorageUsage() < 100 * 1024 * 1024;
}
```

### Time-Based Access

```javascript
// Only allow uploads during business hours
match /pods/{loadId}/{fileName} {
  allow write: if isAuthenticated() && 
                  isImage() && 
                  isValidSize() &&
                  request.time.hours() >= 6 && // 6 AM
                  request.time.hours() < 22;   // 10 PM
}
```

---

## Support Resources

- [Firebase Storage Security Rules Docs](https://firebase.google.com/docs/storage/security)
- [Storage Pricing](https://firebase.google.com/pricing)
- [Best Practices](https://firebase.google.com/docs/storage/security/best-practices)

---

## Changelog

### Version 1.0 (2026-02-02)
- Initial rules for POD image uploads
- 10MB file size limit
- Image-only file type restriction
- Authentication required for all operations

---

**Last Updated**: 2026-02-02  
**Version**: 1.0  
**Compatibility**: Firebase Storage, GUD Express v1.0+
