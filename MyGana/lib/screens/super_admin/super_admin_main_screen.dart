import 'package:flutter/material.dart';
import 'package:nihongo_japanese_app/services/auth_service.dart';

import 'super_admin_users_screen.dart';
import 'super_admin_content_overview_screen.dart';
import 'super_admin_activity_screen.dart';

class SuperAdminMainScreen extends StatefulWidget {
  const SuperAdminMainScreen({super.key});

  @override
  State<SuperAdminMainScreen> createState() => _SuperAdminMainScreenState();
}

class _SuperAdminMainScreenState extends State<SuperAdminMainScreen> {
  int _currentIndex = 0;

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await AuthService().signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const SuperAdminUsersScreen(),
      const SuperAdminContentOverviewScreen(),
      const SuperAdminActivityScreen(),
      _SuperAdminSettingsView(onLogout: () => _logout(context)),
    ];

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey(_currentIndex),
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 1200),
            child: pages[_currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_outlined), activeIcon: Icon(Icons.dashboard_customize), label: 'Content'),
          BottomNavigationBarItem(icon: Icon(Icons.monitor_heart_outlined), activeIcon: Icon(Icons.monitor_heart), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _SuperAdminSettingsView extends StatelessWidget {
  final VoidCallback onLogout;
  const _SuperAdminSettingsView({required this.onLogout});

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
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Super Admin app v1.0.0', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }
}


