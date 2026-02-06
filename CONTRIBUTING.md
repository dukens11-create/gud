# Contributing to GUD Express

**Version:** 2.0.0  
**Last Updated:** 2026-02-06

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)
- [Pull Request Process](#pull-request-process)
- [Development Setup](#development-setup)
- [Code Style Guidelines](#code-style-guidelines)
- [Commit Message Conventions](#commit-message-conventions)
- [Branch Naming Conventions](#branch-naming-conventions)
- [Review Process](#review-process)
- [Community](#community)

---

## Code of Conduct

### Our Pledge

We as members, contributors, and leaders pledge to make participation in our community a harassment-free experience for everyone, regardless of age, body size, visible or invisible disability, ethnicity, sex characteristics, gender identity and expression, level of experience, education, socio-economic status, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

**Positive behavior includes:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behavior includes:**
- The use of sexualized language or imagery
- Trolling, insulting/derogatory comments, and personal or political attacks
- Public or private harassment
- Publishing others' private information without explicit permission
- Other conduct which could reasonably be considered inappropriate

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported to the project team. All complaints will be reviewed and investigated promptly and fairly.

---

## How Can I Contribute?

### Ways to Contribute

1. **Report Bugs** - Found a bug? Let us know!
2. **Suggest Features** - Have an idea? Share it!
3. **Fix Issues** - Pick an issue and submit a PR
4. **Improve Documentation** - Help make our docs better
5. **Write Tests** - Increase test coverage
6. **Code Review** - Review pull requests from others
7. **Share Knowledge** - Help others in discussions

### First-Time Contributors

Look for issues tagged with:
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `documentation` - Documentation improvements

---

## Reporting Bugs

### Before Submitting a Bug Report

- **Check existing issues** - Someone may have already reported it
- **Check documentation** - The behavior might be intentional
- **Try latest version** - The bug might already be fixed
- **Test in isolation** - Ensure it's not caused by your environment

### How to Submit a Bug Report

Create an issue with the following information:

**Title:** Clear, descriptive title (e.g., "App crashes when uploading POD photo on Android 13")

**Template:**
```markdown
## Bug Description
A clear and concise description of what the bug is.

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

## Expected Behavior
A clear description of what you expected to happen.

## Actual Behavior
What actually happened.

## Screenshots
If applicable, add screenshots to help explain your problem.

## Environment
- **Device:** [e.g., iPhone 14, Pixel 7]
- **OS:** [e.g., iOS 17.0, Android 13]
- **App Version:** [e.g., 2.0.0]
- **Flutter Version:** [e.g., 3.24.0]

## Additional Context
Any other context about the problem.

## Logs
```
Paste relevant logs here
```

## Possible Solution
Optional: Suggest a fix or reason for the bug.
```

### Bug Priority Levels

- **Critical** - App crashes, data loss, security issues
- **High** - Major functionality broken
- **Medium** - Feature not working as expected
- **Low** - Minor issues, cosmetic problems

---

## Suggesting Features

### Before Suggesting a Feature

- **Check roadmap** - It might already be planned
- **Search existing issues** - Someone may have suggested it
- **Consider alternatives** - Is there another way to achieve this?

### How to Submit a Feature Request

Create an issue with the following information:

**Title:** Clear feature description (e.g., "Add dark mode support")

**Template:**
```markdown
## Feature Description
A clear and concise description of the feature.

## Problem Statement
What problem does this feature solve?
Example: "As a driver, I want to use the app at night without eye strain..."

## Proposed Solution
Describe how you envision the feature working.

## Alternatives Considered
What other approaches did you consider?

## Benefits
- Who would benefit from this feature?
- How does it improve the app?
- What value does it provide?

## Technical Considerations
- Complexity: Low / Medium / High
- Potential challenges
- Required dependencies

## Mockups/Examples
If applicable, add mockups or examples from other apps.

## Priority
- Critical / High / Medium / Low
- Why this priority?
```

---

## Pull Request Process

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/YOUR_USERNAME/gud.git
cd gud

# Add upstream remote
git remote add upstream https://github.com/dukens11-create/gud.git
```

### 2. Create a Branch

```bash
# Update your fork
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name
```

### 3. Make Changes

- Follow [Code Style Guidelines](#code-style-guidelines)
- Write/update tests for your changes
- Update documentation if needed
- Test your changes thoroughly

### 4. Commit Changes

```bash
# Stage changes
git add .

# Commit with conventional commit message
git commit -m "feat: add dark mode support"
```

See [Commit Message Conventions](#commit-message-conventions) for details.

### 5. Push and Create PR

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create pull request on GitHub
# Use the PR template
```

### 6. PR Requirements

Before submitting:

- [ ] Code follows style guidelines
- [ ] Tests pass: `flutter test`
- [ ] New code has tests
- [ ] Documentation updated
- [ ] No merge conflicts
- [ ] Commit messages follow conventions
- [ ] PR description is complete

### Pull Request Template

```markdown
## Description
Brief description of changes made.

## Related Issue
Fixes #(issue number)

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)
- [ ] Performance improvement
- [ ] Test additions/improvements

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
Describe how you tested your changes:
- [ ] Unit tests pass
- [ ] Widget tests pass
- [ ] Integration tests pass
- [ ] Manual testing on iOS
- [ ] Manual testing on Android
- [ ] Manual testing on Web

## Screenshots (if applicable)
Add screenshots showing before/after.

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## Additional Notes
Any additional information that reviewers should know.
```

---

## Development Setup

### 1. Prerequisites

```bash
# Install Flutter
# See: https://flutter.dev/docs/get-started/install

# Verify installation
flutter doctor

# Install dependencies
flutter pub get
```

### 2. Firebase Setup

Follow [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for complete Firebase configuration.

### 3. Run in Development

```bash
# Run on connected device
flutter run

# Run on specific device
flutter run -d chrome
flutter run -d <device_id>

# Run with hot reload
# Press 'r' to hot reload
# Press 'R' to hot restart
```

### 4. Run Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/services/auth_service_test.dart
```

---

## Code Style Guidelines

### Dart Style Guide

Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.

### Key Principles

1. **Use `dart format`**
   ```bash
   dart format lib/ test/
   ```

2. **Lint with `flutter analyze`**
   ```bash
   flutter analyze
   ```

3. **Follow Flutter conventions**
   - Use `camelCase` for variables and functions
   - Use `PascalCase` for classes
   - Use `snake_case` for file names

### Code Organization

```dart
// 1. Imports (sorted)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:gud_app/models/load.dart';
import 'package:gud_app/services/auth_service.dart';

// 2. Constants
const String kAppName = 'GUD Express';

// 3. Class definition
class MyWidget extends StatefulWidget {
  // 4. Public fields
  final String title;
  
  // 5. Constructor
  const MyWidget({
    Key? key,
    required this.title,
  }) : super(key: key);
  
  // 6. Overrides
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

// 7. Private implementation
class _MyWidgetState extends State<MyWidget> {
  // 8. Private fields
  late String _data;
  
  // 9. Lifecycle methods
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  // 10. Build method
  @override
  Widget build(BuildContext context) {
    return Container();
  }
  
  // 11. Private helper methods
  Future<void> _loadData() async {
    // Implementation
  }
}
```

### Naming Conventions

**Variables:**
```dart
// Good
final String userName = 'John';
final List<Load> activeLoads = [];

// Bad
final String UserName = 'John';  // Wrong case
final List<Load> loads_active = [];  // Wrong separator
```

**Classes:**
```dart
// Good
class LoadService {}
class AdminHomeScreen extends StatelessWidget {}

// Bad
class loadService {}  // Wrong case
class admin_home_screen extends StatelessWidget {}  // Wrong separator
```

**Files:**
```dart
// Good
lib/services/auth_service.dart
lib/screens/admin/load_list_screen.dart

// Bad
lib/services/AuthService.dart  // Wrong case
lib/screens/admin/LoadListScreen.dart  // Wrong case
```

### Documentation

**Public APIs:**
```dart
/// Authenticates a user with email and password.
///
/// Returns a [User] object on success, or throws [AuthException] on failure.
///
/// Example:
/// ```dart
/// final user = await authService.login('user@example.com', 'password');
/// ```
Future<User> login(String email, String password) async {
  // Implementation
}
```

**Complex Logic:**
```dart
// Calculate driver earnings based on completed loads
// Formula: sum of all delivered load rates minus expenses
final earnings = loads
  .where((load) => load.status == 'delivered')
  .fold<double>(0, (sum, load) => sum + load.rate);
```

### Error Handling

```dart
// Good - Specific exceptions
try {
  final result = await service.fetchData();
  return result;
} on NetworkException catch (e) {
  logger.error('Network error: $e');
  rethrow;
} on AuthException catch (e) {
  logger.error('Auth error: $e');
  rethrow;
} catch (e, stackTrace) {
  logger.error('Unexpected error: $e', stackTrace);
  throw AppException('Failed to fetch data');
}

// Bad - Catching everything
try {
  final result = await service.fetchData();
  return result;
} catch (e) {
  print(e);  // Don't use print in production
  return null;  // Silently failing
}
```

### Testing

```dart
// Good - Descriptive test names
test('login with valid credentials returns user');
test('login with invalid email throws AuthException');

// Bad - Unclear test names
test('test login');
test('login works');
```

---

## Commit Message Conventions

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, semicolons, etc.)
- **refactor**: Code refactoring (no functional changes)
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **build**: Build system or dependency changes
- **ci**: CI/CD configuration changes
- **chore**: Other changes (e.g., updating .gitignore)

### Scope (Optional)

Indicates the area of change:
- **auth**: Authentication
- **loads**: Load management
- **drivers**: Driver management
- **ui**: User interface
- **api**: API integration
- **docs**: Documentation

### Examples

**Simple commit:**
```bash
git commit -m "feat(auth): add Google Sign-In support"
```

**Commit with body:**
```bash
git commit -m "fix(loads): prevent duplicate load creation

Fixed race condition where rapid clicks on create button would create
duplicate loads. Added debouncing and disabled state to prevent this."
```

**Breaking change:**
```bash
git commit -m "feat(api): migrate to Firestore v2 API

BREAKING CHANGE: Firestore queries now use v2 API syntax.
All existing queries need to be updated to use new where() syntax."
```

**Multiple changes:**
```bash
git commit -m "refactor(services): improve error handling

- Added custom exception classes
- Improved error messages for users
- Added retry logic for network errors
- Updated tests for new error handling"
```

---

## Branch Naming Conventions

### Format

```
<type>/<short-description>
```

### Types

- **feature/** - New features
- **bugfix/** - Bug fixes
- **hotfix/** - Urgent production fixes
- **refactor/** - Code refactoring
- **docs/** - Documentation updates
- **test/** - Test additions/improvements

### Examples

```bash
# Good
feature/add-dark-mode
bugfix/fix-login-crash
hotfix/critical-security-patch
refactor/simplify-auth-flow
docs/update-deployment-guide
test/add-load-service-tests

# Bad
new-feature  # No type prefix
fix_bug  # Wrong separator
Feature/Add-Dark-Mode  # Wrong case
```

### Branch Lifecycle

```bash
# Create branch
git checkout -b feature/my-feature

# Work on feature
git add .
git commit -m "feat: implement feature"

# Keep branch updated
git checkout main
git pull upstream main
git checkout feature/my-feature
git rebase main

# Push to fork
git push origin feature/my-feature

# After PR is merged
git checkout main
git pull upstream main
git branch -d feature/my-feature
git push origin --delete feature/my-feature
```

---

## Review Process

### For Contributors

1. **Submit PR** - Create pull request with complete description
2. **Address Feedback** - Respond to review comments promptly
3. **Update PR** - Push additional commits to address feedback
4. **Request Re-review** - After addressing all comments
5. **Merge** - Maintainer merges after approval

### For Reviewers

#### Review Checklist

**Code Quality:**
- [ ] Code follows style guidelines
- [ ] Logic is clear and well-structured
- [ ] No unnecessary complexity
- [ ] Error handling is appropriate
- [ ] No security vulnerabilities

**Testing:**
- [ ] Tests are included
- [ ] Tests are comprehensive
- [ ] Tests pass
- [ ] Edge cases covered

**Documentation:**
- [ ] Code is documented
- [ ] Public APIs have doc comments
- [ ] README/docs updated if needed
- [ ] CHANGELOG updated (if applicable)

**Functionality:**
- [ ] Feature works as described
- [ ] No regressions
- [ ] Performance is acceptable
- [ ] UI/UX is consistent

#### Review Comments

**Be Constructive:**
```markdown
# Good
"Consider using a switch statement here for better readability:
```dart
switch (status) {
  case 'pending': return Colors.orange;
  case 'delivered': return Colors.green;
  default: return Colors.grey;
}
```

# Bad
"This code is bad. Rewrite it."
```

**Be Specific:**
```markdown
# Good
"The error message on line 45 should be more user-friendly. 
Suggest: 'Unable to upload photo. Please check your connection.'"

# Bad
"Error messages need work."
```

**Approve When Ready:**
```markdown
# All feedback addressed
"LGTM! Great work on the test coverage. ✅"

# Minor suggestions
"LGTM with minor suggestions. Feel free to merge after addressing or ignore if you disagree. 👍"
```

### Merge Criteria

PR can be merged when:
- [ ] At least one approval from maintainer
- [ ] All CI checks pass
- [ ] All comments addressed or resolved
- [ ] No merge conflicts
- [ ] Documentation updated
- [ ] Tests added/updated

---

## Community

### Communication Channels

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - General discussions and questions
- **Pull Requests** - Code review and collaboration

### Getting Help

**Before asking:**
1. Check documentation
2. Search existing issues
3. Review QUICKSTART.md and README.md

**When asking:**
- Be specific about the problem
- Include relevant code and error messages
- Mention what you've already tried
- Provide environment details

### Recognition

We appreciate all contributions! Contributors will be:
- Listed in CHANGELOG.md
- Mentioned in release notes
- Recognized in README.md (for significant contributions)

---

## Additional Resources

### Documentation
- [Flutter Contributing Guide](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Git Best Practices](https://git-scm.com/book/en/v2)

### Tools
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
- [Flutter Inspector](https://flutter.dev/docs/development/tools/devtools/inspector)
- [Git Hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)

### Learning
- [Flutter Codelabs](https://flutter.dev/docs/codelabs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Firebase for Flutter](https://firebase.flutter.dev/)

---

## Thank You!

Thank you for contributing to GUD Express! Your efforts help make this project better for everyone. 🚀

---

**Last Updated:** 2026-02-06  
**Maintained By:** GUD Express Development Team  
**Related Documents:**
- [README.md](README.md)
- [TESTING.md](TESTING.md)
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) (if separate)
