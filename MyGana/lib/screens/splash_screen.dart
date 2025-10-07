import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nihongo_japanese_app/screens/auth_screen.dart';
import 'package:nihongo_japanese_app/screens/main_screen.dart'; // Import MainScreen
import 'package:nihongo_japanese_app/screens/user_onboarding_screen.dart';
import 'package:nihongo_japanese_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _fadeAnimationController.forward();

    Timer(const Duration(milliseconds: 1500), () {
      _checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    if (!mounted) {
      debugPrint('SplashScreen not mounted, aborting auth check');
      return;
    }

    try {
      debugPrint('Checking Firebase initialization status');
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase not initialized, navigating to AuthScreen');
        _navigateTo(const AuthScreen());
        return;
      }

      debugPrint('Checking current user');
      final user = _authService.currentUser;
      if (user == null) {
        debugPrint('No user authenticated, navigating to AuthScreen');
        _navigateTo(const AuthScreen());
        return;
      }

      debugPrint('User found: ${user.uid}, checking admin status');
      final isAdmin = await _authService.isAdmin();
      if (isAdmin) {
        debugPrint('User is admin, navigating to admin screen');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/admin');
        }
        return;
      }

      debugPrint('Checking profile completion status');
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedProfile = prefs.getBool('has_completed_profile') ?? false;
      debugPrint('hasCompletedProfile: $hasCompletedProfile');

      debugPrint('Navigating to ${hasCompletedProfile ? 'MainScreen' : 'UserOnboardingScreen'}');
      _navigateTo(
        hasCompletedProfile ? const MainScreen() : const UserOnboardingScreen(),
      );
    } catch (e, stackTrace) {
      debugPrint('Error checking auth status: $e\nStack trace: $stackTrace');
      if (mounted) {
        _navigateTo(const AuthScreen());
      }
    }
  }

  void _navigateTo(Widget destination) {
    if (!mounted) {
      debugPrint('SplashScreen not mounted, aborting navigation');
      return;
    }
    debugPrint('Navigating to ${destination.runtimeType}');
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'MyGana',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'TheLastShuriken',
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Japanese Learning App',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
