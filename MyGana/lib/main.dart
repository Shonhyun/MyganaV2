import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nihongo_japanese_app/screens/splash_screen.dart';
import 'package:nihongo_japanese_app/services/auth_service.dart';
import 'package:nihongo_japanese_app/services/firebase_user_sync_service.dart';
import 'package:nihongo_japanese_app/theme/app_theme.dart';
import 'package:nihongo_japanese_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/admin/admin_route_guard.dart';
import 'screens/auth_screen.dart';
import 'screens/lessons_screen.dart';

// Singleton for Firebase initialization
class FirebaseInitializer {
  static bool _isInitializing = false;
  static bool _initialized = false;
  static FirebaseApp? _app;

  static Future<FirebaseApp> initialize() async {
    if (_initialized && _app != null) {
      print('Firebase already initialized: ${_app!.name}');
      return _app!;
    }

    if (_isInitializing) {
      print('Firebase initialization in progress, waiting...');
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _app!;
    }

    // Check for existing apps (possibly initialized by plugins)
    if (Firebase.apps.isNotEmpty) {
      _app = Firebase.apps.first;
      _initialized = true;
      print('Reusing existing Firebase app: ${_app!.name}');
      return _app!;
    }

    _isInitializing = true;
    print('Initializing Firebase...');
    try {
      _app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _initialized = true;
      print('Firebase initialized successfully with app: ${_app!.name}');
      return _app!;
    } catch (e, stackTrace) {
      print('Firebase initialization error: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Propagate error for proper handling
    } finally {
      _isInitializing = false;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and handle errors
  try {
    await FirebaseInitializer.initialize();

    // Initialize Firebase sync service
    final firebaseSync = FirebaseUserSyncService();
    firebaseSync.initialize();

    // Sync user progress if user is authenticated
    final authService = AuthService();
    await authService.syncUserProgressOnAppStart();

    // Restore user data from Firebase if user is authenticated
    if (authService.currentUser != null) {
      await firebaseSync.restoreUserDataFromFirebase();
      // Force sync current points to ensure they're up to date
      await firebaseSync.forceSyncCurrentPoints();
    }
  } catch (e) {
    print('Proceeding without Firebase due to initialization error: $e');
    // Optionally, you could navigate to an error screen here
  }

  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const NihongoApp(),
    ),
  );
}

class NihongoApp extends StatelessWidget {
  const NihongoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    ThemeData activeTheme;
    switch (themeProvider.appThemeMode) {
      case AppThemeMode.blueLight:
        activeTheme = AppTheme.blueLightTheme;
        break;
      case AppThemeMode.sakura:
        activeTheme = AppTheme.sakuraTheme;
        break;
      case AppThemeMode.matcha:
        activeTheme = AppTheme.matchaTheme;
        break;
      case AppThemeMode.sunset:
        activeTheme = AppTheme.sunsetTheme;
        break;
      case AppThemeMode.dark:
        activeTheme = AppTheme.darkTheme;
        break;
      case AppThemeMode.ocean:
        activeTheme = AppTheme.oceanTheme;
        break;
      case AppThemeMode.lavender:
        activeTheme = AppTheme.lavenderTheme;
        break;
      case AppThemeMode.autumn:
        activeTheme = AppTheme.autumnTheme;
        break;
      case AppThemeMode.fuji:
        activeTheme = AppTheme.fujiTheme;
        break;
      case AppThemeMode.light:
        activeTheme = AppTheme.lightTheme;
        break;
      case AppThemeMode.system:
        activeTheme = AppTheme.lightTheme;
        break;
    }

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _getStatusBarIconBrightness(themeProvider.appThemeMode),
        systemNavigationBarColor: _getNavigationBarColor(themeProvider.appThemeMode),
        systemNavigationBarIconBrightness: _getNavBarIconBrightness(themeProvider.appThemeMode),
      ),
    );

    return MaterialApp(
      title: 'Nihongo App',
      theme: activeTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/lessons': (context) => const LessonsScreen(),
        '/auth': (context) => const AuthScreen(),
        '/admin': (context) => const AdminRouteGuard(
              child: AdminMainScreen(),
            ),
      },
    );
  }

  Brightness _getStatusBarIconBrightness(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return Brightness.light;
      default:
        return Brightness.dark;
    }
  }

  Color _getNavigationBarColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return AppTheme.backgroundColor;
      case AppThemeMode.dark:
        return AppTheme.darkBackgroundColor;
      case AppThemeMode.blueLight:
        return AppTheme.blueLightTheme.scaffoldBackgroundColor;
      case AppThemeMode.sakura:
        return AppTheme.sakuraTheme.scaffoldBackgroundColor;
      case AppThemeMode.matcha:
        return AppTheme.matchaTheme.scaffoldBackgroundColor;
      case AppThemeMode.sunset:
        return AppTheme.sunsetTheme.scaffoldBackgroundColor;
      case AppThemeMode.ocean:
        return AppTheme.oceanTheme.scaffoldBackgroundColor;
      case AppThemeMode.lavender:
        return AppTheme.lavenderTheme.scaffoldBackgroundColor;
      case AppThemeMode.autumn:
        return AppTheme.autumnTheme.scaffoldBackgroundColor;
      case AppThemeMode.fuji:
        return AppTheme.fujiTheme.scaffoldBackgroundColor;
      case AppThemeMode.system:
        return AppTheme.backgroundColor;
    }
  }

  Brightness _getNavBarIconBrightness(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return Brightness.light;
      default:
        return Brightness.dark;
    }
  }
}
