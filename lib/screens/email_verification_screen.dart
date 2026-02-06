import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';

/// Email Verification Screen
/// 
/// Shown to users who have not yet verified their email address.
/// Users must verify their email before accessing critical features.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  bool _isResendingEmail = false;
  bool _isCheckingVerification = false;
  Timer? _checkTimer;
  DateTime? _lastResendTime;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Start auto-checking verification status every 3 seconds
    _checkTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerified(),
    );
    
    // Log screen view
    AnalyticsService.instance.logScreenView(
      screenName: 'email_verification',
    );
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Check if email has been verified
  Future<void> _checkEmailVerified() async {
    if (_isCheckingVerification) return;

    setState(() {
      _isCheckingVerification = true;
    });

    try {
      // Reload user data
      await _authService.reloadUser();
      
      final user = _authService.currentUser;
      if (user != null && user.emailVerified) {
        // Email is verified, navigation will be handled by AuthWrapper
        if (mounted) {
          await AnalyticsService.instance.logEvent('email_verified');
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking email verification: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  /// Resend verification email
  Future<void> _resendVerificationEmail() async {
    // Check cooldown
    if (_resendCooldown > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait $_resendCooldown seconds before resending'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isResendingEmail = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        
        if (mounted) {
          await AnalyticsService.instance.logEvent('verification_email_resent');
          
          // Start cooldown (60 seconds)
          _lastResendTime = DateTime.now();
          _resendCooldown = 60;
          _cooldownTimer = Timer.periodic(
            const Duration(seconds: 1),
            (timer) {
              if (mounted) {
                setState(() {
                  _resendCooldown--;
                  if (_resendCooldown <= 0) {
                    timer.cancel();
                  }
                });
              } else {
                timer.cancel();
              }
            },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent! Please check your inbox.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await AnalyticsService.instance.logEvent('verification_email_failed');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResendingEmail = false;
        });
      }
    }
  }

  /// Sign out user
  Future<void> _signOut() async {
    await _authService.signOut();
    await AnalyticsService.instance.logEvent('signout_from_verification');
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 60,
                  color: Colors.blue.shade700,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Message
              Text(
                'We sent a verification email to:',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Email address
              Text(
                email,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Next Steps:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStep('1', 'Check your email inbox'),
                    _buildStep('2', 'Click the verification link'),
                    _buildStep('3', 'Return to this app'),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Resend button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isResendingEmail
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _resendCooldown > 0
                        ? 'Resend in $_resendCooldown seconds'
                        : 'Resend Verification Email',
                  ),
                  onPressed: _resendCooldown > 0 || _isResendingEmail
                      ? null
                      : _resendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Check verification button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: _isCheckingVerification
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('I\'ve Verified My Email'),
                  onPressed: _isCheckingVerification
                      ? null
                      : _checkEmailVerified,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Auto-checking indicator
              if (_isCheckingVerification)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Checking verification status...'),
                  ],
                )
              else
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.autorenew, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Auto-checking every 3 seconds',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
