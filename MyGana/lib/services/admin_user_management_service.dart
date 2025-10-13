import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:nihongo_japanese_app/firebase_options.dart';

class AdminUserManagementService {
  static const String _secondaryAppName = 'super_admin_secondary';

  Future<FirebaseApp> _ensureSecondaryApp() async {
    try {
      final existing = Firebase.apps.where((a) => a.name == _secondaryAppName);
      if (existing.isNotEmpty) return existing.first;
    } catch (_) {}
    final app = await Firebase.initializeApp(
      name: _secondaryAppName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return app;
  }

  Future<void> createTeacherAccount({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? gender,
  }) async {
    final secondary = await _ensureSecondaryApp();
    final auth = FirebaseAuth.instanceFor(app: secondary);
    try {
      debugPrint('Creating teacher account via secondary app for $email');
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) {
        throw Exception('No UID returned for created teacher');
      }
      try {
        await cred.user!.updateDisplayName(
          '${(firstName ?? '').trim()} ${(lastName ?? '').trim()}'.trim(),
        );
      } catch (_) {}

      // Save user profile in primary database
      final db = FirebaseDatabase.instance.ref();
      await db.child('users/$uid').set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender ?? 'Prefer not to say',
        'profileImageUrl': null,
        'isAdmin': true,
        'role': 'teacher',
        'createdAt': ServerValue.timestamp,
      });
      debugPrint('Teacher account $email created with role=teacher');
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'This email is already in use.';
          break;
        case 'invalid-email':
          msg = 'Invalid email address.';
          break;
        case 'weak-password':
          msg = 'Password is too weak.';
          break;
        default:
          msg = 'Failed to create teacher: ${e.message}';
      }
      throw Exception(msg);
    } finally {
      try {
        await auth.signOut();
      } catch (_) {}
    }
  }
}


