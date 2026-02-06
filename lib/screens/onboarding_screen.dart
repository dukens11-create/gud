import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

/// App Onboarding Screen
/// 
/// Welcome and introduction flow for new users:
/// - App feature highlights with smooth animations
/// - Swipeable pages with dot indicators
/// - Skip button in top-right corner
/// - Role-specific tutorials
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

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
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
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    // Start fade-in animation
    _fadeController.forward();
  }

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
  }

  Future<void> _completeOnboarding() async {
    // Fade out animation
    await _fadeController.reverse();
    
    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    // Navigate to login screen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Skip button (top-right corner)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Page view with swipe gestures
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 1.0;
                        if (_pageController.position.haveDimensions) {
                          value = _pageController.page! - index;
                          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                        }
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: value,
                            child: child,
                          ),
                        );
                      },
                      child: _buildPage(_pages[index]),
                    );
                  },
                ),
              ),

              // Dot indicators
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
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        key: ValueKey<int>(_currentPage),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
          // Animated Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: page.color.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: page.color.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                page.icon,
                size: 60,
                color: page.color,
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Animated Title
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 800),
            child: Text(
              page.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Animated Description
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 1000),
            child: Text(
              page.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
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
  return !(prefs.getBool('onboarding_completed') ?? false);
}

/// Helper function to reset onboarding (for testing)
Future<void> resetOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('onboarding_completed');
}

