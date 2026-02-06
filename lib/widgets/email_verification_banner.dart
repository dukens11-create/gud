import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';

/// Email Verification Banner Widget
/// 
/// Displays a persistent banner at the top of screens for unverified users.
/// Shows a warning message and allows users to resend verification emails.
class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({Key? key}) : super(key: key);

  @override
  State<EmailVerificationBanner> createState() => _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  final AuthService _authService = AuthService();
  bool _isResending = false;
  DateTime? _lastResendTime;

  Future<void> _resendVerificationEmail() async {
    // Check if we've sent recently (within 60 seconds)
    if (_lastResendTime != null) {
      final timeSinceLastSend = DateTime.now().difference(_lastResendTime!);
      if (timeSinceLastSend.inSeconds < 60) {
        final remaining = 60 - timeSinceLastSend.inSeconds;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please wait $remaining seconds before resending'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isResending = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        _lastResendTime = DateTime.now();
        
        if (mounted) {
          await AnalyticsService.instance.logEvent('verification_email_resent_from_banner');
          
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _checkVerification() async {
    try {
      await _authService.reloadUser();
      final user = _authService.currentUser;
      
      if (user != null && user.emailVerified) {
        if (mounted) {
          await AnalyticsService.instance.logEvent('email_verified_from_banner');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Trigger rebuild to hide banner
          setState(() {});
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not yet verified. Please check your inbox.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    // Don't show banner if user is null or email is verified
    if (user == null || user.emailVerified) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.orange.shade100,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade900,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Email Not Verified',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Please verify your email to access all features',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_isResending)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange.shade900,
                  ),
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _checkVerification,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Refresh',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: _resendVerificationEmail,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Resend',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
