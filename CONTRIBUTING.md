# Contributing to GUD Express

Thank you for your interest in contributing to GUD Express Trucking Management App! This guide will help you get started.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Code Style Guide](#code-style-guide)
- [Branch Naming Conventions](#branch-naming-conventions)
- [Commit Message Format](#commit-message-format)
- [Pull Request Process](#pull-request-process)
- [Code Review Guidelines](#code-review-guidelines)
- [Testing Requirements](#testing-requirements)
- [Documentation Requirements](#documentation-requirements)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all. Please be respectful and constructive in all interactions.

### Our Standards

**Positive behaviors:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behaviors:**
- Trolling, insulting/derogatory comments, and personal attacks
- Public or private harassment
- Publishing others' private information without permission
- Other conduct which could reasonably be considered inappropriate

## Getting Started

### Prerequisites

1. **Flutter SDK** (3.24.0 or higher)
   ```bash
   flutter --version
   flutter doctor -v
   ```

2. **Git** installed and configured
   ```bash
   git --version
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

3. **IDE** (VS Code or Android Studio)
   - Install Flutter/Dart plugins
   - Install recommended extensions

4. **Firebase Account** (for testing)
   - Create a test Firebase project
   - Configure test environment

### First Time Setup

1. **Fork the repository**
   ```bash
   # Click 'Fork' on GitHub
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

5. **Configure environment**
   ```bash
   # Copy example environment file
   cp .env.example .env.development
   # Edit .env.development with your test Firebase config
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## How to Contribute

### Types of Contributions

We welcome various types of contributions:

1. **Bug Reports**
   - Use the issue tracker
   - Include clear description
   - Provide steps to reproduce
   - Include screenshots if applicable

2. **Feature Requests**
   - Describe the feature clearly
   - Explain the use case
   - Consider implementation approach

3. **Code Contributions**
   - Bug fixes
   - New features
   - Performance improvements
   - Refactoring

4. **Documentation**
   - Improve existing docs
   - Add missing documentation
   - Fix typos or clarify content
   - Add code examples

5. **Tests**
   - Add missing tests
   - Improve test coverage
   - Add integration tests

## Development Setup

### Project Structure

```
gud/
├── lib/
│   ├── models/           # Data models
│   ├── services/         # Business logic and Firebase integration
│   ├── screens/          # UI screens
│   ├── widgets/          # Reusable UI components
│   ├── config/           # Configuration files
│   ├── routes.dart       # Navigation routes
│   └── main.dart         # App entry point
├── test/                 # Unit and widget tests
│   ├── models/
│   ├── services/
│   └── widgets/
├── integration_test/     # Integration tests
├── android/              # Android-specific code
├── ios/                  # iOS-specific code
└── web/                  # Web-specific code
```

### Development Workflow

1. **Sync with upstream**
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Create feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make changes**
   - Write code following style guide
   - Add/update tests
   - Update documentation

4. **Test changes**
   ```bash
   flutter test
   flutter analyze
   flutter format lib test
   ```

5. **Commit changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create Pull Request**
   - Go to GitHub
   - Click "New Pull Request"
   - Fill in PR template

## Code Style Guide

We follow Dart and Flutter best practices and conventions.

### Dart/Flutter Conventions

#### File Naming
```dart
// Use lowercase with underscores
user_profile.dart
load_service.dart
app_button.dart
```

#### Class Naming
```dart
// Use PascalCase for classes
class UserProfile { }
class LoadService { }
class AppButton extends StatelessWidget { }
```

#### Variable Naming
```dart
// Use camelCase for variables and functions
String userName = 'John';
double totalRevenue = 1500.0;

void calculateRevenue() { }
```

#### Constant Naming
```dart
// Use lowerCamelCase for constants
const double maxLoadWeight = 10000.0;
const String apiBaseUrl = 'https://api.example.com';
```

#### Private Members
```dart
// Use underscore prefix for private members
class MyClass {
  String _privateField;
  
  void _privateMethod() { }
}
```

### Code Formatting

```bash
# Format all Dart files
flutter format lib test

# Check formatting without modifying
flutter format --output=none --set-exit-if-changed lib test
```

### Import Organization

```dart
// 1. Dart imports
import 'dart:async';
import 'dart:convert';

// 2. Package imports
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 3. Relative imports
import '../models/load.dart';
import '../services/firestore_service.dart';
```

### Documentation Comments

```dart
/// Represents a load in the trucking system.
///
/// A load contains information about pickup, delivery, and the assigned driver.
/// Each load has a unique [loadNumber] and tracks its [status] through the
/// delivery process.
class LoadModel {
  /// The unique identifier for this load.
  final String id;
  
  /// The human-readable load number (e.g., "LD-001").
  final String loadNumber;
  
  /// Creates a new [LoadModel] with the given parameters.
  ///
  /// The [id], [loadNumber], [driverId], [pickupAddress], [deliveryAddress],
  /// [rate], and [status] are required. All other parameters are optional.
  LoadModel({
    required this.id,
    required this.loadNumber,
    // ...
  });
  
  /// Converts this load to a JSON map for Firestore storage.
  Map<String, dynamic> toMap() {
    // ...
  }
}
```

### Widget Structure

```dart
class MyWidget extends StatelessWidget {
  // 1. Constructor parameters
  const MyWidget({
    Key? key,
    required this.title,
    this.subtitle,
  }) : super(key: key);

  // 2. Fields
  final String title;
  final String? subtitle;

  // 3. Build method
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text(title),
          if (subtitle != null) Text(subtitle!),
        ],
      ),
    );
  }

  // 4. Helper methods (if needed)
  void _handleTap() {
    // ...
  }
}
```

### Null Safety

```dart
// Use null safety properly
String? nullableString;
String nonNullString = 'value';

// Use null-aware operators
final length = nullableString?.length ?? 0;

// Use late for late initialization
late final String lateInitialized;

// Use required for required parameters
void function({required String param}) { }
```

### Async/Await

```dart
// Always use async/await instead of .then()
// Good ✅
Future<void> loadData() async {
  try {
    final data = await fetchData();
    await processData(data);
  } catch (e) {
    handleError(e);
  }
}

// Avoid ❌
void loadData() {
  fetchData().then((data) {
    processData(data).then((_) {
      // nested callbacks
    });
  }).catchError((e) {
    handleError(e);
  });
}
```

### Error Handling

```dart
// Handle errors appropriately
Future<LoadModel?> loadLoad(String id) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('loads')
        .doc(id)
        .get();
    
    if (!doc.exists) {
      return null;
    }
    
    return LoadModel.fromDoc(doc);
  } on FirebaseException catch (e) {
    print('Firebase error: ${e.message}');
    rethrow;
  } catch (e) {
    print('Unexpected error: $e');
    return null;
  }
}
```

## Branch Naming Conventions

Use descriptive branch names that follow this pattern:

### Branch Types

```bash
# New features
feature/add-expense-tracking
feature/implement-geofencing
feature/invoice-pdf-export

# Bug fixes
bugfix/fix-login-error
bugfix/correct-revenue-calculation
bugfix/resolve-image-upload-issue

# Hotfixes (urgent production fixes)
hotfix/critical-crash-on-startup
hotfix/security-vulnerability

# Refactoring
refactor/reorganize-services
refactor/improve-state-management

# Documentation
docs/update-api-documentation
docs/add-contributing-guide

# Tests
test/add-invoice-service-tests
test/improve-coverage

# Chores (maintenance tasks)
chore/update-dependencies
chore/configure-ci-cd
```

### Branch Naming Rules

1. Use lowercase
2. Use hyphens to separate words
3. Be descriptive but concise
4. Include issue number if applicable
   ```bash
   feature/123-add-dark-mode
   bugfix/456-fix-memory-leak
   ```

## Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code refactoring (neither fixes a bug nor adds a feature)
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks (dependencies, build, etc.)
- **ci**: CI/CD changes

### Examples

```bash
# Feature
feat: add invoice PDF export functionality
feat(invoice): implement line item calculations

# Bug fix
fix: resolve crash when loading empty driver list
fix(auth): correct email validation regex

# Documentation
docs: update deployment guide with Firebase setup
docs(api): add Firestore schema documentation

# Refactoring
refactor: extract common validation logic to utility class
refactor(services): simplify error handling

# Tests
test: add unit tests for LoadModel
test(invoice): add integration tests for invoice creation

# With breaking change
feat!: redesign authentication flow

BREAKING CHANGE: The login method now requires biometric authentication.
Users will need to re-authenticate after updating.

# With issue reference
fix: resolve memory leak in background location service

Closes #123
```

### Commit Message Rules

1. Use imperative mood ("add" not "added" or "adds")
2. Don't capitalize first letter
3. No period at the end
4. Keep first line under 72 characters
5. Separate body with blank line
6. Wrap body at 72 characters
7. Reference issues at the end

## Pull Request Process

### Before Creating PR

1. **Ensure all tests pass**
   ```bash
   flutter test
   flutter analyze
   ```

2. **Update documentation**
   - Update relevant .md files
   - Add inline code comments
   - Update CHANGELOG.md

3. **Rebase on latest main**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

4. **Squash commits if needed**
   ```bash
   git rebase -i HEAD~3  # squash last 3 commits
   ```

### Creating the PR

1. **Use PR template**
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update
   
   ## Testing
   - [ ] Unit tests added/updated
   - [ ] Integration tests added/updated
   - [ ] Manual testing completed
   
   ## Checklist
   - [ ] Code follows style guide
   - [ ] Self-review completed
   - [ ] Comments added for complex code
   - [ ] Documentation updated
   - [ ] No new warnings
   - [ ] Tests pass locally
   ```

2. **Write clear PR description**
   - What problem does this solve?
   - How does it solve it?
   - Any breaking changes?
   - Screenshots (for UI changes)

3. **Link related issues**
   ```markdown
   Closes #123
   Related to #456
   ```

### After Creating PR

1. **Respond to feedback**
   - Be open to suggestions
   - Ask questions if unclear
   - Make requested changes promptly

2. **Keep PR updated**
   ```bash
   # If main branch is updated
   git fetch upstream
   git rebase upstream/main
   git push --force-with-lease
   ```

3. **Wait for approval**
   - At least 1 approval required
   - All checks must pass
   - No unresolved conversations

## Code Review Guidelines

### For Authors

**Before requesting review:**
- Self-review your code
- Ensure tests pass
- Check code style
- Update documentation

**During review:**
- Respond to comments promptly
- Be open to feedback
- Ask for clarification
- Explain your decisions

### For Reviewers

**Review checklist:**
- [ ] Code follows style guide
- [ ] Logic is correct
- [ ] Tests are adequate
- [ ] Documentation is updated
- [ ] No security issues
- [ ] No performance issues
- [ ] Error handling is proper

**Review etiquette:**
- Be respectful and constructive
- Explain reasoning for suggestions
- Distinguish between required and optional changes
- Approve when satisfied

**Comment types:**
```markdown
# Required change
🔴 This will cause a crash if userId is null. Add null check.

# Suggestion
💡 Consider using a const constructor here for better performance.

# Nitpick (optional)
🔹 Nitpick: This could be simplified to a one-liner.

# Question
❓ Why did you choose this approach? Have you considered X?

# Praise
✨ Great use of the factory pattern here!
```

## Testing Requirements

### Coverage Requirements

All code contributions must include tests:

- **Models**: >90% coverage
- **Services**: >80% coverage
- **Widgets**: >70% coverage
- **Overall**: >80% coverage

### Test Types Required

1. **Unit Tests** (required for all services and models)
   ```dart
   test('LoadModel.toMap() converts to Map correctly', () {
     // test implementation
   });
   ```

2. **Widget Tests** (required for new/modified widgets)
   ```dart
   testWidgets('AppButton shows loading indicator', (tester) async {
     // test implementation
   });
   ```

3. **Integration Tests** (required for new features)
   ```dart
   testWidgets('Complete invoice creation flow', (tester) async {
     // test implementation
   });
   ```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/models/load_model_test.dart

# Run tests matching pattern
flutter test --name "LoadModel"
```

## Documentation Requirements

### Required Documentation

1. **Code Comments**
   - Document public APIs
   - Explain complex logic
   - Add TODO comments for future work

2. **README Updates**
   - Update if adding features
   - Add usage examples
   - Update dependencies list

3. **API Documentation**
   - Document new services
   - Update API.md for Firestore changes
   - Document data models

4. **User Documentation**
   - Update user guides for features
   - Add screenshots for UI changes
   - Update QUICKSTART.md if needed

### Documentation Style

```dart
/// Brief one-line description.
///
/// Detailed description with multiple lines if needed.
/// Explain parameters, return values, and exceptions.
///
/// Example:
/// ```dart
/// final load = LoadModel.fromMap('id', data);
/// ```
///
/// Throws [FormatException] if data is invalid.
/// Returns null if document doesn't exist.
```

## Questions?

- **General questions**: Open a GitHub Discussion
- **Bug reports**: Create an issue
- **Feature requests**: Create an issue with enhancement label
- **Security issues**: Email security@gudexpress.com

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

**Thank you for contributing to GUD Express!** 🚛

**Last Updated**: Phase 11 Completion
**Version**: 2.0.0
