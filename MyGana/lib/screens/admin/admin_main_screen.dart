import 'package:flutter/material.dart';
import 'package:nihongo_japanese_app/services/auth_service.dart';
import 'package:nihongo_japanese_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

import 'admin_levels_screen.dart';
import 'admin_quiz_management_screen.dart';
import 'admin_class_list_screen.dart';

class AdminMainScreen extends StatelessWidget {
  const AdminMainScreen({super.key});

  // Get theme icon for display
  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return Icons.phone_android;
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.sakura:
        return Icons.local_florist;
      case AppThemeMode.matcha:
        return Icons.eco;
      case AppThemeMode.sunset:
        return Icons.wb_sunny;
      case AppThemeMode.ocean:
        return Icons.water;
      case AppThemeMode.lavender:
        return Icons.spa;
      case AppThemeMode.autumn:
        return Icons.park;
      case AppThemeMode.fuji:
        return Icons.landscape;
      case AppThemeMode.blueLight:
        return Icons.blur_on;
    }
  }

  // Add logout function
  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    // If user confirmed logout
    if (shouldLogout == true) {
      try {
        await AuthService().signOut();
        // Navigate to auth screen and remove all previous routes
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Add theme switcher button
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return PopupMenuButton<AppThemeMode>(
                icon: const Icon(Icons.palette),
                tooltip: 'Change Theme',
                onSelected: (AppThemeMode theme) {
                  themeProvider.setAppTheme(theme);
                },
                itemBuilder: (BuildContext context) {
                  return AppThemeMode.values.map((AppThemeMode theme) {
                    return PopupMenuItem<AppThemeMode>(
                      value: theme,
                      child: Row(
                        children: [
                          Icon(
                            _getThemeIcon(theme),
                            color: themeProvider.appThemeMode == theme
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            themeProvider.getThemeName(theme),
                            style: TextStyle(
                              color: themeProvider.appThemeMode == theme
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: themeProvider.appThemeMode == theme
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
              );
            },
          ),
          // Add logout button to AppBar
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 1200),
        margin: EdgeInsets.symmetric(
          horizontal: isDesktop
              ? 32
              : isTablet
                  ? 24
                  : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Management Card
            Container(
              margin: EdgeInsets.only(
                  bottom: isDesktop
                      ? 32
                      : isTablet
                          ? 24
                          : 16),
              child: Hero(
                tag: 'admin_class_management_card',
                child: Material(
                  child: Card(
                    elevation: 6,
                    shadowColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminClassListScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.all(isDesktop
                            ? 28
                            : isTablet
                                ? 24
                                : 20),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isDesktop
                                  ? 20
                                  : isTablet
                                      ? 16
                                      : 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.class_,
                                color: Theme.of(context).colorScheme.tertiary,
                                size: isDesktop
                                    ? 40
                                    : isTablet
                                        ? 36
                                        : 32,
                              ),
                            ),
                            SizedBox(
                                width: isDesktop
                                    ? 24
                                    : isTablet
                                        ? 20
                                        : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Class Management',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isDesktop
                                              ? 28
                                              : isTablet
                                                  ? 24
                                                  : 20,
                                          color: Theme.of(context).colorScheme.tertiary,
                                        ),
                                  ),
                                  SizedBox(
                                      height: isDesktop
                                          ? 12
                                          : isTablet
                                              ? 10
                                              : 8),
                                  Text(
                                    'Create classes and monitor students',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color
                                          ?.withOpacity(0.7),
                                      fontSize: isDesktop
                                          ? 16
                                          : isTablet
                                              ? 14
                                              : 12,
                                    ),
                                  ),
                                  SizedBox(
                                      height: isDesktop
                                          ? 16
                                          : isTablet
                                              ? 12
                                              : 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Theme.of(context).colorScheme.tertiary,
                                        size: isDesktop
                                            ? 24
                                            : isTablet
                                                ? 20
                                                : 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Tap to manage',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.tertiary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isDesktop
                                              ? 16
                                              : isTablet
                                                  ? 14
                                                  : 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Theme.of(context).colorScheme.tertiary,
                              size: isDesktop
                                  ? 28
                                  : isTablet
                                      ? 24
                                      : 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                top: isDesktop
                    ? 32
                    : isTablet
                        ? 24
                        : 16,
                bottom: isDesktop
                    ? 40
                    : isTablet
                        ? 32
                        : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Admin Panel',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktop
                              ? 32
                              : isTablet
                                  ? 28
                                  : 24,
                        ),
                  ),
                  SizedBox(
                      height: isDesktop
                          ? 12
                          : isTablet
                              ? 10
                              : 8),
                  Text(
                    'Manage your Japanese learning content',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                          fontSize: isDesktop
                              ? 18
                              : isTablet
                                  ? 16
                                  : 14,
                        ),
                  ),
                ],
              ),
            ),

            // Lesson Management Card
            Container(
              margin: EdgeInsets.only(
                  bottom: isDesktop
                      ? 32
                      : isTablet
                          ? 24
                          : 16),
              child: Hero(
                tag: 'admin_lesson_management_card',
                child: Material(
                  child: Card(
                    elevation: 6,
                    shadowColor: Colors.blue.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminLevelsScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.all(isDesktop
                            ? 28
                            : isTablet
                                ? 24
                                : 20),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isDesktop
                                  ? 20
                                  : isTablet
                                      ? 16
                                      : 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.school,
                                color: Theme.of(context).colorScheme.primary,
                                size: isDesktop
                                    ? 40
                                    : isTablet
                                        ? 36
                                        : 32,
                              ),
                            ),
                            SizedBox(
                                width: isDesktop
                                    ? 24
                                    : isTablet
                                        ? 20
                                        : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lesson Management',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isDesktop
                                              ? 28
                                              : isTablet
                                                  ? 24
                                                  : 20,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                  ),
                                  SizedBox(
                                      height: isDesktop
                                          ? 12
                                          : isTablet
                                              ? 10
                                              : 8),
                                  Text(
                                    'Manage levels, categories, lessons, and content',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color
                                          ?.withOpacity(0.7),
                                      fontSize: isDesktop
                                          ? 16
                                          : isTablet
                                              ? 14
                                              : 12,
                                    ),
                                  ),
                                  SizedBox(
                                      height: isDesktop
                                          ? 16
                                          : isTablet
                                              ? 12
                                              : 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: isDesktop
                                            ? 24
                                            : isTablet
                                                ? 20
                                                : 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Tap to manage',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isDesktop
                                              ? 16
                                              : isTablet
                                                  ? 14
                                                  : 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Theme.of(context).colorScheme.primary,
                              size: isDesktop
                                  ? 28
                                  : isTablet
                                      ? 24
                                      : 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Quiz Management Card
            Container(
              margin: EdgeInsets.only(
                  bottom: isDesktop
                      ? 32
                      : isTablet
                          ? 24
                          : 16),
              child: Hero(
                tag: 'admin_quiz_management_card',
                child: Material(
                  child: Card(
                    elevation: 6,
                    shadowColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminQuizManagementScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.all(isDesktop
                            ? 28
                            : isTablet
                                ? 24
                                : 20),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isDesktop
                                  ? 20
                                  : isTablet
                                      ? 16
                                      : 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.quiz,
                                color: Theme.of(context).colorScheme.secondary,
                                size: isDesktop
                                    ? 40
                                    : isTablet
                                        ? 36
                                        : 32,
                              ),
                            ),
                            SizedBox(
                                width: isDesktop
                                    ? 24
                                    : isTablet
                                        ? 20
                                        : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quiz Management',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isDesktop
                                              ? 28
                                              : isTablet
                                                  ? 24
                                                  : 20,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                  ),
                                  SizedBox(
                                      height: isDesktop
                                          ? 12
                                          : isTablet
                                              ? 10
                                              : 8),
                                  Text(
                                    'Create and manage quizzes for students',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color
                                          ?.withOpacity(0.7),
                                      fontSize: isDesktop
                                          ? 16
                                          : isTablet
                                              ? 14
                                              : 12,
                                    ),
                                  ),
                                  SizedBox(
                                      height: isDesktop
                                          ? 16
                                          : isTablet
                                              ? 12
                                              : 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Theme.of(context).colorScheme.secondary,
                                        size: isDesktop
                                            ? 24
                                            : isTablet
                                                ? 20
                                                : 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Tap to manage',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.secondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isDesktop
                                              ? 14
                                              : isTablet
                                                  ? 12
                                                  : 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Theme.of(context).colorScheme.secondary,
                              size: isDesktop
                                  ? 28
                                  : isTablet
                                      ? 24
                                      : 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Logout Button
            const Spacer(),
            Container(
              margin: EdgeInsets.only(
                  bottom: isDesktop
                      ? 32
                      : isTablet
                          ? 24
                          : 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: Icon(
                    Icons.logout,
                    size: isDesktop
                        ? 24
                        : isTablet
                            ? 22
                            : 20,
                  ),
                  label: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: isDesktop
                          ? 18
                          : isTablet
                              ? 16
                              : 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop
                          ? 20
                          : isTablet
                              ? 18
                              : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}