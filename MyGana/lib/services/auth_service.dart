import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:nihongo_japanese_app/services/firebase_user_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseUserSyncService _firebaseSync = FirebaseUserSyncService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> getAuthStateChanges() => authStateChanges;

  // Check if user is authenticated
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sync user progress when app starts (if user is authenticated)
  Future<void> syncUserProgressOnAppStart() async {
    try {
      if (currentUser != null) {
        debugPrint('Syncing user progress on app start for user: ${currentUser!.uid}');
        await _firebaseSync.syncUserProgressToFirebase();
        debugPrint('User progress synced on app start');
      } else {
        debugPrint('No authenticated user found for progress sync');
      }
    } catch (e) {
      debugPrint('Error syncing user progress on app start: $e');
      // Don't throw error, app should continue to work
    }
  }

  // Check if user is admin with better error handling
  Future<bool> isAdmin() async {
    if (currentUser == null) {
      debugPrint('No user signed in for admin check');
      return false;
    }
    try {
      debugPrint('Checking admin status for user: ${currentUser!.uid}');
      final snapshot =
          await FirebaseDatabase.instance.ref().child('users/${currentUser!.uid}/isAdmin').get();

      final isAdmin = snapshot.exists && snapshot.value == true;
      debugPrint(
          'Admin check result: $isAdmin, snapshot exists: ${snapshot.exists}, value: ${snapshot.value}');
      return isAdmin;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  // Enhanced method to ensure user is authenticated for reading
  Future<bool> ensureAuthenticated() async {
    try {
      // Check if already authenticated
      if (currentUser != null) {
        debugPrint('User already authenticated: ${currentUser!.uid}');
        return true;
      }

      // Try anonymous sign in for read access
      debugPrint('No user found, attempting anonymous sign in...');
      final UserCredential userCredential = await _auth.signInAnonymously();

      if (userCredential.user != null) {
        debugPrint('Anonymous sign in successful: ${userCredential.user!.uid}');
        // Wait for authentication to be fully processed
        await Future.delayed(const Duration(milliseconds: 1000));
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error ensuring authentication: $e');
      return false;
    }
  }

  // Sign in anonymously for read access with retry logic
  Future<void> signInAnonymously({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('Attempting anonymous sign in (attempt $attempt/$maxRetries)...');

        final UserCredential userCredential = await _auth.signInAnonymously();

        if (userCredential.user == null) {
          throw Exception('Anonymous sign in failed: No user returned');
        }

        debugPrint('Anonymous sign in successful for user: ${userCredential.user!.uid}');

        // Wait for authentication to be ready
        await Future.delayed(const Duration(milliseconds: 500));
        return;
      } on FirebaseAuthException catch (e) {
        debugPrint(
            'FirebaseAuthException during anonymous sign in (attempt $attempt): ${e.code} - ${e.message}');

        if (attempt == maxRetries) {
          String errorMessage;
          switch (e.code) {
            case 'operation-not-allowed':
              errorMessage = 'Anonymous authentication is not enabled.';
              break;
            case 'network-request-failed':
              errorMessage = 'Network error. Please check your connection.';
              break;
            default:
              errorMessage = 'Anonymous sign in failed: ${e.message}';
          }
          throw Exception(errorMessage);
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: attempt));
      } catch (e) {
        debugPrint('Unexpected anonymous sign in error (attempt $attempt): $e');

        if (attempt == maxRetries) {
          throw Exception('Unexpected error during anonymous sign in: $e');
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: attempt));
      }
    }
  }

  // Login with improved error handling
  Future<void> login(String email, String password, {int retryCount = 2}) async {
    try {
      debugPrint('Attempting login with email: $email (Retry count: $retryCount)');

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user == null) {
        debugPrint('Login failed: No user returned from Firebase');
        throw Exception('Login failed: No user found after authentication');
      }

      debugPrint('Login successful for user: ${userCredential.user!.uid}');

      // Wait a moment for the database to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Clear any previous user's data and restore current user's data from Firebase
      try {
        await _clearPreviousUserData();
        await _firebaseSync.restoreUserDataFromFirebase();
        debugPrint('User data restored from Firebase after login');
      } catch (e) {
        debugPrint('Error restoring user data after login: $e');
        // Don't throw error, login was successful
      }

      // Sync user progress to Firebase after successful login
      try {
        await _firebaseSync.syncUserProgressToFirebase();
        debugPrint('User progress synced to Firebase after login');
      } catch (e) {
        debugPrint('Error syncing user progress after login: $e');
        // Don't throw error, login was successful
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during login: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password. Please try again.';
          break;
        default:
          if (e.message?.contains('reCAPTCHA') ?? false) {
            errorMessage = 'reCAPTCHA verification failed. Please try again.';
          } else {
            errorMessage = 'Login failed: ${e.message}';
          }
      }
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      debugPrint('Unexpected login error: $e\nStack trace: $stackTrace');

      // Handle specific type casting errors - ignore them if user is authenticated
      if (e.toString().contains('PigeonUserInfo') ||
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        debugPrint('Type casting error detected, checking if user is actually authenticated');

        // Wait a bit and check if user is actually authenticated
        await Future.delayed(const Duration(milliseconds: 1000));

        if (currentUser != null) {
          debugPrint('User is authenticated despite type error: ${currentUser!.uid}');
          return; // Login was actually successful, ignore the type error
        }
      }

      // Retry for network errors
      if (e.toString().contains('Connection reset by peer') && retryCount > 0) {
        debugPrint('Retrying login due to network error...');
        await Future.delayed(const Duration(seconds: 2));
        return login(email, password, retryCount: retryCount - 1);
      }

      throw Exception('Unexpected error during login: $e');
    }
  }

  // Register with improved error handling
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    String? profileImagePath,
    bool isAdmin = false,
  }) async {
    try {
      debugPrint('Registering user with email: $email');

      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = userCredential.user;

      if (user == null) {
        debugPrint('Registration failed: No user returned');
        throw Exception('Registration failed: No user created');
      }

      debugPrint('User created: ${user.uid}');

      // Update user profile with retry mechanism
      try {
        await user.updateDisplayName('$firstName $lastName');
        await user.reload();
        debugPrint('User profile updated with name: $firstName $lastName');
      } catch (e) {
        debugPrint('Error updating display name: $e');
        // Continue with registration even if display name update fails
      }

      // Store user data in Realtime Database with explicit admin flag
      final userData = {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'profileImageUrl': profileImagePath,
        'isAdmin': isAdmin,
        'createdAt': ServerValue.timestamp,
      };

      await FirebaseDatabase.instance.ref().child('users/${user.uid}').set(userData);

      debugPrint('User data saved to Realtime Database with admin status: $isAdmin');

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('first_name', firstName);
      await prefs.setString('last_name', lastName);
      await prefs.setString('gender', gender);
      await prefs.setBool('has_completed_profile', true);
      debugPrint('User data saved to SharedPreferences');

      // Sync user progress to Firebase after successful registration
      try {
        await _firebaseSync.syncUserProgressToFirebase();
        debugPrint('User progress synced to Firebase after registration');
      } catch (e) {
        debugPrint('Error syncing user progress after registration: $e');
        // Don't throw error, registration was successful
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during registration: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already in use.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMessage = 'Registration failed: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      debugPrint('Unexpected registration error: $e\nStack trace: $stackTrace');

      // Handle type casting errors during registration - ignore if user was created
      if (e.toString().contains('PigeonUserInfo') ||
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        debugPrint('Type casting error during registration, checking if user was created');

        await Future.delayed(const Duration(milliseconds: 1000));

        if (currentUser != null) {
          debugPrint('User was created despite type error: ${currentUser!.uid}');

          // Try to save user data to database
          try {
            final userData = {
              'email': email,
              'firstName': firstName,
              'lastName': lastName,
              'gender': gender,
              'profileImageUrl': profileImagePath,
              'isAdmin': isAdmin,
              'createdAt': ServerValue.timestamp,
            };

            await FirebaseDatabase.instance.ref().child('users/${currentUser!.uid}').set(userData);

            // Save to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('first_name', firstName);
            await prefs.setString('last_name', lastName);
            await prefs.setString('gender', gender);
            await prefs.setBool('has_completed_profile', true);

            debugPrint('User data saved successfully after type error recovery');

            // Sync user progress to Firebase after successful registration
            try {
              await _firebaseSync.syncUserProgressToFirebase();
              debugPrint('User progress synced to Firebase after registration (error recovery)');
            } catch (e) {
              debugPrint('Error syncing user progress after registration (error recovery): $e');
              // Don't throw error, registration was successful
            }

            return; // Registration was successful, ignore the type error
          } catch (dbError) {
            debugPrint('Error saving user data after type error: $dbError');
            throw Exception('Registration completed but failed to save user data: $dbError');
          }
        }
      }

      throw Exception('Unexpected error during registration: $e');
    }
  }

  // Method to manually set admin status (for testing purposes)
  Future<void> setAdminStatus(bool isAdmin) async {
    if (currentUser == null) {
      throw Exception('No user signed in');
    }
    try {
      await FirebaseDatabase.instance.ref().child('users/${currentUser!.uid}/isAdmin').set(isAdmin);
      debugPrint('Admin status set to: $isAdmin for user: ${currentUser!.uid}');
    } catch (e) {
      debugPrint('Error setting admin status: $e');
      throw Exception('Failed to set admin status: $e');
    }
  }

  // Sign out with improved error handling
  Future<void> signOut() async {
    try {
      debugPrint('Signing out user: ${currentUser?.uid}');

      // Set user as offline in Firebase before signing out
      try {
        await _firebaseSync.setUserOffline();
        debugPrint('User set as offline in Firebase');
      } catch (e) {
        debugPrint('Error setting user offline: $e');
        // Don't throw error, continue with sign out
      }

      await _auth.signOut();
      debugPrint('Sign out successful');

      // DON'T clear SharedPreferences on sign out - keep as backup
      // Data will be restored from Firebase when user logs back in
      debugPrint('SharedPreferences kept as backup (will be restored from Firebase on next login)');
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw Exception('Sign out failed: $e');
    }
  }

  // Clear previous user's data when switching users
  Future<void> _clearPreviousUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Store current user ID to check if it changed
      final currentUserId = currentUser?.uid;
      final lastUserId = prefs.getString('last_user_id');

      // If user ID changed, clear all user-specific data
      if (lastUserId != null && lastUserId != currentUserId) {
        debugPrint('User changed from $lastUserId to $currentUserId - clearing previous user data');

        // Clear all user-specific data
        final allKeys = prefs.getKeys();
        for (final key in allKeys) {
          // Keep only system settings, clear user progress data
          if (!key.startsWith('setting_') &&
              !key.startsWith('last_user_id') &&
              !key.startsWith('app_')) {
            await prefs.remove(key);
          }
        }

        debugPrint('Previous user data cleared');
      }

      // Update last user ID
      if (currentUserId != null) {
        await prefs.setString('last_user_id', currentUserId);
      }
    } catch (e) {
      debugPrint('Error clearing previous user data: $e');
      // Don't throw error, continue with login
    }
  }

  // Update profile image with improved error handling
  Future<void> updateProfileImage(String imagePath) async {
    try {
      if (currentUser == null) {
        debugPrint('No user signed in for profile image update');
        throw Exception('No user signed in');
      }

      debugPrint('Uploading profile image for user: ${currentUser!.uid}');

      final storageRef = FirebaseStorage.instance.ref().child('profile_images/${currentUser!.uid}');

      await storageRef.putFile(File(imagePath));
      final profileImageUrl = await storageRef.getDownloadURL();

      await FirebaseDatabase.instance
          .ref()
          .child('users/${currentUser!.uid}/profileImageUrl')
          .set(profileImageUrl);

      debugPrint('Profile image updated: $profileImageUrl');
    } catch (e) {
      debugPrint('Profile image update error: $e');
      throw Exception('Failed to update profile image: $e');
    }
  }

  // Get user data from Firebase
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) {
        debugPrint('No user signed in for getUserData');
        return null;
      }

      final snapshot =
          await FirebaseDatabase.instance.ref().child('users/${currentUser!.uid}').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return Map<String, dynamic>.from(data);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Update user data in Firebase
  Future<void> updateUserData(Map<String, dynamic> userData) async {
    try {
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      userData['updatedAt'] = ServerValue.timestamp;

      await FirebaseDatabase.instance.ref().child('users/${currentUser!.uid}').update(userData);

      debugPrint('User data updated successfully');
    } catch (e) {
      debugPrint('Error updating user data: $e');
      throw Exception('Failed to update user data: $e');
    }
  }
}
