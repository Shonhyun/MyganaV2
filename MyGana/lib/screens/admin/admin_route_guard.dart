import 'package:flutter/material.dart';
import 'package:nihongo_japanese_app/screens/auth_screen.dart';
import '../../services/auth_service.dart';

class AdminRouteGuard extends StatelessWidget {
  final Widget child;

  const AdminRouteGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const AuthScreen();
        }

        return FutureBuilder<bool>(
          future: AuthService().isTeacher(),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final hasTeacherAccess = adminSnapshot.data ?? false;
            if (!hasTeacherAccess) {
              return const Scaffold(
                body: Center(
                  child: Text('Access Denied: Teacher access required'),
                ),
              );
            }

            return child;
          },
        );
      },
    );
  }
} 