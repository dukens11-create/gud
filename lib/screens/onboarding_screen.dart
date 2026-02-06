import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App Onboarding Screen
/// 
/// Welcome and introduction flow for new users:
/// - App feature highlights
/// - Permission requests
/// - Role-specific tutorials
/// - Quick start guide
/// 
/// Shown only on first app launch
/// 
/// TODO: Add animated illustrations
/// TODO: Implement swipeable pages
/// TODO: Add skip button
/// TODO: Create role-specific onboarding
class OnboardingScreen extends StatefulWidget {
  final String userRole; // 'admin' or 'driver'

  const OnboardingScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingPage> get _pages {
    if (widget.userRole == 'admin') {
      return _adminPages;
    } else {
      return _driverPages;
    }
  }

  // Admin onboarding pages
  final List<OnboardingPage> _adminPages = [
    OnboardingPage(
      title: 'Welcome to GUD Express',
      description: 'Manage your trucking operations with ease. '
          'Create loads, assign drivers, and track deliveries in real-time.',
      icon: Icons.local_shipping,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Live Driver Tracking',
      description: 'See all your drivers on a live map. '
          'Monitor locations, routes, and delivery progress in real-time.',
      icon: Icons.map,
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'Smart Notifications',
      description: 'Get instant alerts for load updates, driver arrivals, '
          'and proof-of-delivery submissions.',
      icon: Icons.notifications,
      color: Colors.orange,
    ),
    OnboardingPage(
      title: 'Manage Your Fleet',
      description: 'Add drivers, assign loads, review PODs, and track '
          'earnings all from one dashboard.',
      icon: Icons.dashboard,
      color: Colors.purple,
    ),
  ];

  // Driver onboarding pages
  final List<OnboardingPage> _driverPages = [
    OnboardingPage(
      title: 'Welcome Driver!',
      description: 'Your all-in-one app for managing deliveries, '
          'tracking earnings, and staying connected.',
      icon: Icons.local_shipping,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Load Management',
      description: 'View assigned loads, update status, and navigate '
          'to pickup and delivery locations.',
      icon: Icons.assignment,
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'GPS Tracking',
      description: 'Share your location automatically so dispatch knows '
          'where you are and when you\'ll arrive.',
      icon: Icons.my_location,
      color: Colors.orange,
    ),
    OnboardingPage(
      title: 'Proof of Delivery',
      description: 'Capture photos, add notes, and submit PODs instantly '
          'when deliveries are complete.',
      icon: Icons.camera_alt,
      color: Colors.red,
    ),
    OnboardingPage(
      title: 'Track Your Earnings',
      description: 'Monitor your completed loads, earnings, and performance '
          'metrics in real-time.',
      icon: Icons.attach_money,
      color: Colors.teal,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;

    // Navigate to main app
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: const Text('Skip'),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicator
            _buildPageIndicator(),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _pages.length,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == index
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
            ),
          ),
        ),
      ),
    );
  }
}

/// Onboarding page data model
class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Helper function to check if onboarding should be shown
Future<bool> shouldShowOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool('onboarding_complete') ?? false);
}

/// Helper function to reset onboarding (for testing)
Future<void> resetOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('onboarding_complete');
}

// TODO: Add animated illustrations
// Use Lottie or Rive for smooth animations
// Example:
// Lottie.asset('assets/animations/truck_animation.json')

// TODO: Implement swipeable pages
// Add gesture detection for more intuitive navigation
// Show "Swipe to continue" hint

// TODO: Add permission requests
// Request location permission during onboarding
// Request notification permission
// Explain why each permission is needed

// TODO: Create interactive tutorials
// Highlight key UI elements
// Show tooltips and hints
// Add "Try it yourself" interactive steps

// TODO: Add video tutorials
// Embed short video clips
// Show real usage examples
// Link to detailed help documentation

// TODO: Implement progress saving
// Allow users to pause and resume onboarding
// Save current page index
// Remember skipped sections

// TODO: Add localization
// Support multiple languages
// Translate all onboarding content
// Respect device language settings
