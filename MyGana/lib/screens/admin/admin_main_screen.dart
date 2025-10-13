import 'package:flutter/material.dart';
import 'package:nihongo_japanese_app/services/auth_service.dart';
import 'package:nihongo_japanese_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

import 'admin_levels_screen.dart';
import 'admin_quiz_management_screen.dart';
import 'admin_class_list_screen.dart';
import 'admin_leaderboard_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;


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

    final pages = <Widget>[
      const AdminLevelsScreen(),
      const AdminQuizManagementScreen(),
      const AdminClassListScreen(),
      const AdminLeaderboardScreen(),
      _AdminSettingsView(onLogout: () => _logout(context)),
    ];

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
          child: Container(
            key: ValueKey(_currentIndex),
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 1200),
            margin: EdgeInsets.symmetric(
              horizontal: isDesktop
                  ? 32
                  : isTablet
                      ? 24
                      : 0,
            ),
            child: pages[_currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: Container
        (
                decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedIconTheme: const IconThemeData(size: 24),
            unselectedIconTheme: const IconThemeData(size: 22),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.school_outlined),
                activeIcon: Icon(Icons.school),
                label: 'Lessons',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.quiz_outlined),
                activeIcon: Icon(Icons.quiz),
                label: 'Quizzes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined),
                activeIcon: Icon(Icons.group),
                label: 'Classes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined),
                activeIcon: Icon(Icons.emoji_events),
                label: 'Leaderboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSettingsView extends StatelessWidget {
  final VoidCallback onLogout;
  const _AdminSettingsView({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dark Mode',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (v) {
                          themeProvider.setAppTheme(v ? AppThemeMode.dark : AppThemeMode.light);
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 32),
        Opacity(
          opacity: 0.6,
          child: Text(
            'Admin app v1.0.0',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}        