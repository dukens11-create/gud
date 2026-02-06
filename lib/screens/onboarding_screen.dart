import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

/// App Onboarding Screen
/// 
/// Welcome and introduction flow for new users:
/// - App feature highlights with animations
/// - Permission requests
/// - Role-specific tutorials
/// - Quick start guide
/// - Swipeable pages with progress indicators
/// 
/// Shown only on first app launch
class OnboardingScreen extends StatefulWidget {
  final String userRole; // 'admin' or 'driver'

  const OnboardingScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<OnboardingPage> get _pages {
    if (widget.userRole == 'admin') {
      return _adminPages;
    } else {
      return _driverPages;
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  // Admin onboarding pages
  final List<OnboardingPage> _adminPages = [
    OnboardingPage(
      title: 'Welcome to GUD Express',
      description: 'Manage your trucking operations with ease. '
          'Create loads, assign drivers, and track deliveries in real-time.',
      icon: Icons.local_shipping,
      color: Colors.blue,
      lottieAsset: null, // Can add: 'assets/animations/truck.json'
    ),
    OnboardingPage(
      title: 'Live Driver Tracking',
      description: 'See all your drivers on a live map. '
          'Monitor locations, routes, and delivery progress in real-time.',
      icon: Icons.map,
      color: Colors.green,
      lottieAsset: null,
    ),
    OnboardingPage(
      title: 'Smart Notifications',
      description: 'Get instant alerts for load updates, driver arrivals, '
          'and proof-of-delivery submissions.',
      icon: Icons.notifications,
      color: Colors.orange,
      lottieAsset: null,
    ),
    OnboardingPage(
      title: 'Manage Your Fleet',
      description: 'Add drivers, assign loads, review PODs, and track '
          'earnings all from one dashboard.',
      icon: Icons.dashboard,
      color: Colors.purple,
      lottieAsset: null,
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
      lottieAsset: null,
    ),
    OnboardingPage(
      title: 'Load Management',
      description: 'View assigned loads, update status, and navigate '
          'to pickup and delivery locations.',
      icon: Icons.assignment,
      color: Colors.green,
      lottieAsset: null,
    ),
    OnboardingPage(
      title: 'GPS Tracking',
      description: 'Share your location automatically so dispatch knows '
          'where you are and when you\'ll arrive.',
      icon: Icons.my_location,
      color: Colors.orange,
      lottieAsset: null,
    ),
    OnboardingPage(
      title: 'Proof of Delivery',
      description: 'Capture photos, add notes, and submit PODs instantly '
          'when deliveries are complete.',
      icon: Icons.camera_alt,
      color: Colors.red,
      lottieAsset: null,
    ),
    OnboardingPage(
      title: 'Track Your Earnings',
      description: 'Monitor your completed loads, earnings, and performance '
          'metrics in real-time.',
      icon: Icons.attach_money,
      color: Colors.teal,
      lottieAsset: null,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // Animate transition
    _fadeController.reset();
    _fadeController.forward();
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('onboarding_completed_at', DateTime.now().toIso8601String());
    await prefs.setString('onboarding_role', widget.userRole);

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
            // Skip button (only show if not on last page)
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon or Lottie animation
            if (page.lottieAsset != null)
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(
                  page.lottieAsset!,
                  fit: BoxFit.contain,
                ),
              )
            else
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
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
                  );
                },
              ),
            const SizedBox(height: 48),

            // Title with slide animation
            TweenAnimationBuilder<Offset>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: const Offset(0, 0.3), end: Offset.zero),
              builder: (context, offset, child) {
                return Transform.translate(
                  offset: Offset(0, offset.dy * 20),
                  child: Opacity(
                    opacity: 1 - offset.dy.abs(),
                    child: Text(
                      page.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Description with delayed animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Text(
                    page.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        ),
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
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
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
  final String? lottieAsset;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.lottieAsset,
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
  await prefs.remove('onboarding_completed_at');
  await prefs.remove('onboarding_role');
}

/// Get onboarding completion info
Future<Map<String, dynamic>?> getOnboardingInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final isComplete = prefs.getBool('onboarding_complete') ?? false;
  
  if (!isComplete) return null;
  
  return {
    'completed': isComplete,
    'completedAt': prefs.getString('onboarding_completed_at'),
    'role': prefs.getString('onboarding_role'),
  };
}
