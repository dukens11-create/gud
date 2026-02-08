# Developer Onboarding Guide

Welcome to the GUD Express development team! This guide will help you get up to speed quickly.

## Day 1: Setup and Orientation

### Morning: Environment Setup

#### 1. Install Required Tools

**Flutter SDK**
```bash
# Download from https://flutter.dev/docs/get-started/install
flutter doctor
# Ensure all checks pass
```

**VS Code Extensions** (Recommended)
- Flutter
- Dart
- Firebase Explorer
- GitLens

**Android Studio** (for Android development)
- Download from https://developer.android.com/studio
- Install Flutter and Dart plugins

**Xcode** (for iOS development, macOS only)
```bash
xcode-select --install
sudo xcodebuild -license accept
```

#### 2. Clone and Setup Project

```bash
# Clone repository
git clone https://github.com/YOUR_ORG/gud.git
cd gud

# Install dependencies
flutter pub get

# Setup environment
cp .env.example .env
# Fill in Firebase credentials (ask team lead)

# Run the app
flutter run
```

#### 3. Verify Setup

```bash
# Run tests
flutter test

# Check for issues
flutter analyze

# Build for Android
flutter build apk

# Build for iOS (macOS only)
flutter build ios
```

### Afternoon: Code Familiarization

#### Read Documentation

1. **README.md** - Project overview
2. **ARCHITECTURE.md** - System architecture
3. **docs/api_documentation.md** - Service APIs
4. **CONTRIBUTING.md** - Contribution guidelines

#### Explore Codebase

```
gud/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── services/                 # Business logic
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   └── ...
│   ├── screens/                  # UI screens
│   │   ├── admin/
│   │   ├── driver/
│   │   └── auth/
│   ├── models/                   # Data models
│   └── widgets/                  # Reusable widgets
├── test/                         # Unit tests
├── integration_test/             # Integration tests
└── docs/                         # Documentation
```

#### Key Files to Review

1. **lib/main.dart** - App initialization
2. **lib/services/auth_service.dart** - Authentication
3. **lib/services/firestore_service.dart** - Database operations
4. **lib/screens/admin/admin_home.dart** - Admin dashboard
5. **lib/screens/driver/driver_home.dart** - Driver dashboard

## Day 2: Hands-On Practice

### Morning: Run the App

#### 1. Test Login Flow

**Test Credentials:**
- Set up Firebase test accounts for development/testing
- Demo credentials have been removed for production readiness
- Create test accounts through Firebase Console

#### 2. Test Admin Features

- View dashboard
- Create a new load
- Assign load to driver
- View driver locations
- Check statistics

#### 3. Test Driver Features

- View assigned loads
- Start a trip
- Update location
- Upload POD
- View earnings

### Afternoon: Make Your First Change

#### Task: Add a Welcome Message

**Goal:** Add a personalized welcome message to the home screen.

**Steps:**

1. **Create a branch**
   ```bash
   git checkout -b feature/welcome-message
   ```

2. **Modify the screen**
   ```dart
   // lib/screens/driver/driver_home.dart
   
   Widget _buildWelcome() {
     return Card(
       child: Padding(
         padding: EdgeInsets.all(16),
         child: Text(
           'Welcome back, ${widget.driverName}!',
           style: Theme.of(context).textTheme.headline6,
         ),
       ),
     );
   }
   ```

3. **Add to build method**
   ```dart
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       body: Column(
         children: [
           _buildWelcome(), // Add this
           // ... existing widgets
         ],
       ),
     );
   }
   ```

4. **Test the change**
   ```bash
   flutter run
   # Verify the welcome message appears
   ```

5. **Commit and push**
   ```bash
   git add .
   git commit -m "feat(driver): add welcome message to home screen"
   git push origin feature/welcome-message
   ```

6. **Create Pull Request**
   - Go to GitHub
   - Create PR from your branch
   - Request review from mentor

## Day 3-5: Core Concepts

### Firebase Integration

#### Authentication

```dart
// Sign in
final authService = AuthService();
final credential = await authService.signIn(email, password);

// Get current user
final user = authService.currentUser;

// Listen to auth changes
authService.authStateChanges.listen((user) {
  if (user != null) {
    // User signed in
  } else {
    // User signed out
  }
});
```

#### Firestore Database

```dart
final firestoreService = FirestoreService();

// Create a load
final loadId = await firestoreService.createLoad(
  loadNumber: 'LOAD-001',
  driverId: driverId,
  // ... other fields
);

// Stream loads in real-time
StreamBuilder<List<LoadModel>>(
  stream: firestoreService.streamDriverLoads(driverId),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    return LoadsList(loads: snapshot.data!);
  },
);
```

#### Cloud Storage

```dart
final storageService = StorageService();

// Pick image
final file = await storageService.pickImage(
  source: ImageSource.camera,
);

// Upload image
final url = await storageService.uploadPodImage(
  loadId: load.id,
  file: file,
);
```

### State Management

We use Provider for state management:

```dart
// Provide a service
Provider<AuthService>(
  create: (_) => AuthService(),
  child: MyApp(),
)

// Consume in widget
final authService = Provider.of<AuthService>(context);

// Or use Consumer
Consumer<AuthService>(
  builder: (context, authService, child) {
    return Text('User: ${authService.currentUser?.email}');
  },
)
```

### Navigation

```dart
// Navigate to screen
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => LoadDetailScreen(load: load),
  ),
);

// Navigate with result
final result = await Navigator.of(context).push(...);

// Pop back
Navigator.of(context).pop(result);

// Replace screen
Navigator.of(context).pushReplacement(...);
```

### Error Handling

```dart
Future<void> createLoad() async {
  try {
    await firestoreService.createLoad(...);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Load created successfully')),
    );
  } on FirebaseException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.message}')),
    );
  }
}
```

## Week 1: First Real Task

### Task: Implement Load Filtering

**Requirements:**
- Add dropdown to filter loads by status
- Statuses: All, Assigned, In Transit, Delivered
- Update UI to show filtered loads

**Guidance:**

1. **Add filter state**
   ```dart
   String _selectedStatus = 'all';
   ```

2. **Add dropdown**
   ```dart
   DropdownButton<String>(
     value: _selectedStatus,
     items: ['all', 'assigned', 'in_transit', 'delivered']
         .map((status) => DropdownMenuItem(
               value: status,
               child: Text(status.toUpperCase()),
             ))
         .toList(),
     onChanged: (value) {
       setState(() {
         _selectedStatus = value!;
       });
     },
   )
   ```

3. **Filter loads**
   ```dart
   List<LoadModel> _filterLoads(List<LoadModel> loads) {
     if (_selectedStatus == 'all') return loads;
     return loads.where((load) => load.status == _selectedStatus).toList();
   }
   ```

4. **Update StreamBuilder**
   ```dart
   StreamBuilder<List<LoadModel>>(
     stream: firestoreService.streamLoads(),
     builder: (context, snapshot) {
       if (!snapshot.hasData) return Loading();
       final filtered = _filterLoads(snapshot.data!);
       return LoadsList(loads: filtered);
     },
   )
   ```

5. **Test thoroughly**
   - Test each filter option
   - Test with no loads
   - Test switching filters
   - Test on both admin and driver views

6. **Write tests**
   ```dart
   test('filters loads by status', () {
     // Test implementation
   });
   ```

## Common Patterns

### Loading States

```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return Center(child: CircularProgressIndicator());
}

if (snapshot.hasError) {
  return Center(child: Text('Error: ${snapshot.error}'));
}

if (!snapshot.hasData || snapshot.data!.isEmpty) {
  return Center(child: Text('No data available'));
}

// Render data
return ListView(...);
```

### Form Validation

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          return null;
        },
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Process form
          }
        },
        child: Text('Submit'),
      ),
    ],
  ),
)
```

### Async Operations

```dart
Future<void> _loadData() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    final data = await service.fetchData();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _error = e.toString();
      _isLoading = false;
    });
  }
}
```

## Development Tips

### Debugging

**Print Debugging**
```dart
print('User ID: ${user.uid}');
debugPrint('Complex object: ${object.toString()}');
```

**Flutter DevTools**
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

**Logging**
```dart
import 'dart:developer' as developer;

developer.log('Message', name: 'MyApp', error: error);
```

### Hot Reload

- **Hot Reload** (r): Update UI without losing state
- **Hot Restart** (R): Restart app, lose state
- **Full Restart**: Stop and rerun

Use hot reload for UI changes, hot restart for code changes.

### Common Issues

**Issue: Build failures**
```bash
flutter clean
flutter pub get
flutter run
```

**Issue: iOS build fails**
```bash
cd ios
pod install
cd ..
flutter run
```

**Issue: Gradle errors (Android)**
```bash
cd android
./gradlew clean
cd ..
flutter run
```

**Issue: Firebase not initializing**
- Check google-services.json (Android)
- Check GoogleService-Info.plist (iOS)
- Verify Firebase project settings

## Resources

### Documentation
- [Flutter Docs](https://flutter.dev/docs)
- [Dart Docs](https://dart.dev/guides)
- [Firebase Docs](https://firebase.google.com/docs)
- [Project Docs](../README.md)

### Learning
- [Flutter Cookbook](https://flutter.dev/docs/cookbook)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Firebase Codelabs](https://firebase.google.com/codelabs)

### Community
- [Flutter Discord](https://discord.gg/flutter)
- [r/FlutterDev](https://reddit.com/r/FlutterDev)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

### Tools
- [Dart Pad](https://dartpad.dev/) - Online Dart editor
- [Flutter Widget Catalog](https://flutter.dev/docs/development/ui/widgets)
- [Pub.dev](https://pub.dev/) - Package repository

## Team Communication

### Daily Standup
- **When**: 9:00 AM daily
- **Where**: Slack #gud-standup
- **Format**: What did you do? What will you do? Any blockers?

### Code Reviews
- **Response time**: Within 24 hours
- **Approval required**: At least 1 approval
- **Process**: Address feedback, re-request review

### Getting Help
1. Check documentation first
2. Search existing issues
3. Ask in Slack #gud-dev
4. Tag your mentor
5. Schedule a pairing session

## Next Steps

### Week 2-4: Intermediate Tasks
- Implement new features
- Write comprehensive tests
- Optimize performance
- Improve error handling

### Month 2-3: Advanced Topics
- Architecture decisions
- Code review for others
- Mentoring new developers
- Feature planning

### Ongoing
- Stay updated with Flutter releases
- Contribute to documentation
- Participate in code reviews
- Share knowledge with team

## Checklist

### First Week
- [ ] Development environment set up
- [ ] App runs successfully
- [ ] Documentation read
- [ ] First PR merged
- [ ] Team introductions completed

### First Month
- [ ] Completed 5+ tasks
- [ ] Written unit tests
- [ ] Reviewed 3+ PRs
- [ ] Understands architecture
- [ ] Can work independently

### First Quarter
- [ ] Shipped major feature
- [ ] Mentored new developer
- [ ] Contributed to architecture decisions
- [ ] Improved documentation

Welcome aboard! We're excited to have you on the team! 🚀
