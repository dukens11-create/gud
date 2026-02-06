# Contributing to GUD Express

Thank you for your interest in contributing to GUD Express! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Documentation](#documentation)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors.

### Expected Behavior

- Be respectful and professional
- Accept constructive criticism gracefully
- Focus on what is best for the project
- Show empathy towards other contributors

### Unacceptable Behavior

- Harassment or discrimination of any kind
- Trolling, insulting, or derogatory comments
- Publishing others' private information
- Other conduct inappropriate in a professional setting

## Getting Started

### Prerequisites

Before contributing, ensure you have:

1. **Flutter SDK** (3.24.0 or higher)
   ```bash
   flutter --version
   ```

2. **Dart SDK** (3.0.0 or higher)
   ```bash
   dart --version
   ```

3. **Firebase CLI** (for deployment)
   ```bash
   firebase --version
   ```

4. **Git**
   ```bash
   git --version
   ```

### Initial Setup

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/gud.git
   cd gud
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/gud.git
   ```

4. **Install dependencies**
   ```bash
   flutter pub get
   ```

5. **Set up environment**
   ```bash
   cp .env.example .env
   # Fill in your Firebase credentials
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## Development Workflow

### 1. Create a Feature Branch

Always create a new branch for your work:

```bash
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions or changes

Examples:
- `feature/add-load-filtering`
- `fix/pod-upload-error`
- `docs/update-api-docs`

### 2. Keep Your Branch Updated

Regularly sync with the main branch:

```bash
git fetch upstream
git rebase upstream/main
```

### 3. Make Your Changes

- Write clean, readable code
- Follow the coding standards (see below)
- Add tests for new features
- Update documentation as needed

### 4. Test Your Changes

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test

# Run specific tests
flutter test test/services/auth_service_test.dart
```

### 5. Commit Your Changes

Follow commit message guidelines (see below).

### 6. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 7. Create a Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Fill in the PR template
4. Request reviews

## Coding Standards

### Dart Style Guide

Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).

#### File Organization

```dart
// 1. Imports (alphabetical)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 2. Service imports
import '../services/auth_service.dart';

// 3. Model imports
import '../models/driver.dart';

// 4. Widget imports
import '../widgets/custom_button.dart';

// 5. Constants
const double kDefaultPadding = 16.0;

// 6. Main class
class MyWidget extends StatelessWidget {
  // ...
}
```

#### Naming Conventions

```dart
// Classes: PascalCase
class AuthService {}
class DriverHomeScreen {}

// Files: snake_case
// auth_service.dart
// driver_home_screen.dart

// Variables: camelCase
String driverName;
int loadCount;

// Constants: lowerCamelCase with 'k' prefix
const double kButtonHeight = 48.0;
const String kApiBaseUrl = 'https://api.example.com';

// Private members: _prefixed
String _privateField;
void _privateMethod() {}
```

#### Code Formatting

Use `dart format` to auto-format code:

```bash
dart format lib/ test/
```

#### Documentation Comments

Use `///` for public APIs:

```dart
/// Sign in a user with email and password.
/// 
/// Returns [UserCredential] on success, null in offline mode.
/// Throws [FirebaseAuthException] on authentication failure.
/// 
/// Example:
/// ```dart
/// final credential = await authService.signIn('user@example.com', 'password');
/// ```
Future<UserCredential?> signIn(String email, String password) async {
  // Implementation
}
```

Use `//` for implementation comments:

```dart
// Check if user is already authenticated
if (currentUser != null) {
  return;
}
```

### Flutter Best Practices

#### Widget Organization

```dart
class MyScreen extends StatefulWidget {
  // 1. Constructor
  const MyScreen({Key? key, required this.param}) : super(key: key);
  
  // 2. Fields
  final String param;
  
  // 3. State creation
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  // 1. State variables
  late String _data;
  
  // 2. Lifecycle methods
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    // Clean up
    super.dispose();
  }
  
  // 3. Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }
  
  // 4. Helper build methods
  Widget _buildBody() {
    // ...
  }
  
  // 5. Event handlers
  void _handleSubmit() {
    // ...
  }
  
  // 6. Other methods
  Future<void> _loadData() async {
    // ...
  }
}
```

#### Use const Where Possible

```dart
// Good
const Text('Hello');
const SizedBox(height: 16);

// Bad
Text('Hello');
SizedBox(height: 16);
```

#### Extract Reusable Widgets

```dart
// Instead of repeating code
Widget build(BuildContext context) {
  return Column(
    children: [
      Container(
        padding: EdgeInsets.all(16),
        child: Text('Title'),
      ),
      Container(
        padding: EdgeInsets.all(16),
        child: Text('Body'),
      ),
    ],
  );
}

// Extract to reusable widget
class PaddedText extends StatelessWidget {
  const PaddedText(this.text, {Key? key}) : super(key: key);
  final String text;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Text(text),
    );
  }
}
```

#### Avoid Deep Nesting

```dart
// Bad
if (user != null) {
  if (user.isActive) {
    if (user.hasPermission) {
      // Do something
    }
  }
}

// Good
if (user == null) return;
if (!user.isActive) return;
if (!user.hasPermission) return;
// Do something
```

### Service Layer Guidelines

#### Single Responsibility

Each service should have a single, well-defined purpose:

```dart
// Good - Focused on authentication
class AuthService {
  Future<void> signIn() {}
  Future<void> signOut() {}
}

// Bad - Mixing responsibilities
class AuthService {
  Future<void> signIn() {}
  Future<void> uploadImage() {}  // Wrong!
}
```

#### Error Handling

Always handle errors appropriately:

```dart
Future<UserCredential?> signIn(String email, String password) async {
  try {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } on FirebaseAuthException catch (e) {
    // Log error
    await _crashlytics.recordError(e, StackTrace.current);
    // Re-throw for caller to handle
    rethrow;
  } catch (e) {
    // Handle unexpected errors
    throw Exception('Unexpected error during sign in: $e');
  }
}
```

#### Use Dependency Injection

```dart
// Good - Testable
class LoadService {
  LoadService(this.firestore);
  final FirebaseFirestore firestore;
}

// Bad - Hard-coded dependency
class LoadService {
  final firestore = FirebaseFirestore.instance;
}
```

## Testing Guidelines

### Test Coverage

Aim for at least 80% code coverage for:
- Service classes
- Business logic
- Utility functions

UI tests are optional but recommended for critical flows.

### Unit Tests

Place unit tests in `test/` directory, mirroring the `lib/` structure:

```
lib/
  services/
    auth_service.dart
test/
  services/
    auth_service_test.dart
```

Example unit test:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockFirebaseAuth mockAuth;
    
    setUp(() {
      mockAuth = MockFirebaseAuth();
      authService = AuthService(auth: mockAuth);
    });
    
    test('signIn returns credential on success', () async {
      // Arrange
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockCredential);
      
      // Act
      final result = await authService.signIn('test@test.com', 'password');
      
      // Assert
      expect(result, isNotNull);
    });
    
    test('signIn throws on invalid credentials', () async {
      // Arrange
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      
      // Act & Assert
      expect(
        () => authService.signIn('test@test.com', 'wrong'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });
}
```

### Integration Tests

Place integration tests in `integration_test/`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('driver can complete load flow', (tester) async {
    // Start app
    app.main();
    await tester.pumpAndSettle();
    
    // Sign in
    await tester.enterText(find.byKey(Key('email')), 'driver@test.com');
    await tester.enterText(find.byKey(Key('password')), 'password');
    await tester.tap(find.byKey(Key('signin')));
    await tester.pumpAndSettle();
    
    // Accept load
    await tester.tap(find.byKey(Key('load-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('accept-load')));
    await tester.pumpAndSettle();
    
    // Verify navigation
    expect(find.text('Load Details'), findsOneWidget);
  });
}
```

### Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/services/auth_service_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integration tests
flutter test integration_test
```

## Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Type

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or tooling changes

#### Scope

The scope should be the area of the codebase affected:
- `auth`: Authentication
- `loads`: Load management
- `drivers`: Driver management
- `notifications`: Notification system
- `ui`: User interface
- etc.

#### Examples

```
feat(loads): add filtering by status

Added dropdown to filter loads by their status (assigned, in_transit, delivered).
Includes unit tests for filter logic.

Closes #123
```

```
fix(auth): handle sign-in error correctly

Fixed crash when sign-in fails due to network error.
Now shows proper error message to user.

Fixes #456
```

```
docs(api): update FirestoreService documentation

Added missing method descriptions and examples for POD operations.
```

### Commit Best Practices

1. **Keep commits atomic** - One logical change per commit
2. **Write descriptive messages** - Explain what and why, not how
3. **Reference issues** - Use "Closes #123" or "Fixes #456"
4. **Keep commits small** - Easier to review and revert if needed

## Pull Request Process

### Before Submitting

1. **Update your branch**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run tests**
   ```bash
   flutter test
   ```

3. **Format code**
   ```bash
   dart format lib/ test/
   ```

4. **Check for warnings**
   ```bash
   flutter analyze
   ```

### PR Template

When creating a PR, include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings

## Screenshots (if applicable)
Add screenshots for UI changes

## Related Issues
Closes #123
```

### Review Process

1. **Automated checks** - CI runs tests and linting
2. **Code review** - At least one approval required
3. **Address feedback** - Make requested changes
4. **Approval** - PR approved by reviewer(s)
5. **Merge** - Maintainer merges PR

### After Merge

1. **Delete branch**
   ```bash
   git branch -d feature/your-feature
   git push origin --delete feature/your-feature
   ```

2. **Update local main**
   ```bash
   git checkout main
   git pull upstream main
   ```

## Documentation

### When to Update Documentation

Update documentation when you:
- Add a new feature
- Change existing functionality
- Add or modify service methods
- Change configuration or setup process

### Documentation Locations

- **README.md** - Project overview and quick start
- **docs/api_documentation.md** - Service API reference
- **docs/ARCHITECTURE.md** - Architecture details
- **docs/CONTRIBUTING.md** - This file
- **docs/ONBOARDING.md** - New developer guide
- **Inline comments** - Complex code explanations

### Documentation Style

- Use clear, concise language
- Include code examples
- Add screenshots for UI features
- Keep documentation up-to-date with code

## Getting Help

### Resources

- **Documentation**: Check the `/docs` folder
- **Issues**: Search existing issues on GitHub
- **Discussions**: Use GitHub Discussions for questions

### Contact

- **Email**: dev-team@gudexpress.com
- **Slack**: #gud-dev channel
- **GitHub**: @gudexpress/core-team

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project README

Thank you for contributing to GUD Express! 🚚
