import 'dart:convert';

import 'package:nihongo_japanese_app/models/leaderboard_model.dart';
import 'package:nihongo_japanese_app/services/firebase_user_sync_service.dart';
import 'package:nihongo_japanese_app/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardService {
  static const String _leaderboardKey = 'class_leaderboard';
  static const String _currentUserIdKey = 'current_user_id';

  final ProgressService _progressService = ProgressService();
  final FirebaseUserSyncService _firebaseSync = FirebaseUserSyncService();

  // Get current user ID (in a real app, this would come from authentication)
  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_currentUserIdKey);

    if (userId == null) {
      // Generate a unique user ID for this device
      userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_currentUserIdKey, userId);
    }

    return userId;
  }

  // Get leaderboard data
  Future<LeaderboardData> getLeaderboard() async {
    try {
      // Try to get real data from Firebase first
      final firebaseData = await _getFirebaseLeaderboardData();
      if (firebaseData != null) {
        return firebaseData;
      }

      // Fallback to cached data
      final prefs = await SharedPreferences.getInstance();
      final leaderboardJson = prefs.getString(_leaderboardKey);

      if (leaderboardJson != null) {
        final data = LeaderboardData.fromJson(jsonDecode(leaderboardJson));

        // Check if data is recent (within last hour)
        final now = DateTime.now();
        if (now.difference(data.lastUpdated).inHours < 1) {
          return data;
        }
      }

      // Generate fresh leaderboard data (mock data)
      return await _generateLeaderboardData();
    } catch (e) {
      // print('Error getting leaderboard: $e');
      return await _generateLeaderboardData();
    }
  }

  // Get leaderboard data from Firebase
  Future<LeaderboardData?> _getFirebaseLeaderboardData() async {
    try {
      final firebaseData = await _firebaseSync.getLeaderboardData();
      if (firebaseData.isEmpty) return null;

      final currentUserId = await _getCurrentUserId();
      final currentUserProgress = _progressService.getUserProgress();

      // Convert Firebase data to LeaderboardEntry objects
      final entries = <LeaderboardEntry>[];
      for (int i = 0; i < firebaseData.length; i++) {
        final user = firebaseData[i];
        final rank = i + 1;
        final level = user['level'] as int? ?? 1;
        final totalXp = user['totalXp'] as int? ?? 0;
        final userId = user['userId'] as String? ?? '';
        final displayName = user['displayName'] as String? ?? 'Anonymous';
        final currentStreak = user['currentStreak'] as int? ?? 0;
        final lastActiveTimestamp = user['lastActive'] as int?;
        // final isOnline = user['isOnline'] as bool? ?? false; // Not used currently

        DateTime lastActive;
        if (lastActiveTimestamp != null) {
          lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveTimestamp);
        } else {
          lastActive = DateTime.now().subtract(const Duration(hours: 1));
        }

        entries.add(LeaderboardEntry(
          userId: userId,
          username: displayName,
          avatarUrl: user['photoURL'] as String? ?? '',
          level: level,
          totalXp: totalXp,
          rank: rank,
          rankBadge: LeaderboardEntry.calculateRankBadge(level),
          lastActive: lastActive,
          streak: currentStreak,
          recentAchievements: _getCurrentUserAchievements(level),
          isCurrentUser: userId == currentUserId,
        ));
      }

      // Find current user entry
      final currentUserEntry = entries.firstWhere(
        (entry) => entry.isCurrentUser,
        orElse: () => entries.isNotEmpty
            ? entries.first
            : LeaderboardEntry(
                userId: currentUserId,
                username: 'You',
                avatarUrl: '',
                level: currentUserProgress.level,
                totalXp: currentUserProgress.totalXp,
                rank: 1,
                rankBadge: LeaderboardEntry.calculateRankBadge(currentUserProgress.level),
                lastActive: DateTime.now(),
                streak: currentUserProgress.currentStreak,
                recentAchievements: _getCurrentUserAchievements(currentUserProgress.level),
                isCurrentUser: true,
              ),
      );

      final leaderboardData = LeaderboardData(
        entries: entries,
        currentUserEntry: currentUserEntry,
        totalUsers: entries.length,
        lastUpdated: DateTime.now(),
      );

      // Save to local storage for offline access
      await _saveLeaderboardData(leaderboardData);

      return leaderboardData;
    } catch (e) {
      print('Error fetching Firebase leaderboard data: $e');
      return null;
    }
  }

  // Generate mock leaderboard data (in a real app, this would fetch from server)
  Future<LeaderboardData> _generateLeaderboardData() async {
    final currentUserId = await _getCurrentUserId();
    final currentUserProgress = _progressService.getUserProgress();

    // Mock data for demonstration
    final mockUsers = [
      {
        'userId': 'user_1',
        'username': 'SakuraMaster',
        'avatarUrl': '',
        'level': 25,
        'totalXp': 24000,
        'streak': 15,
        'recentAchievements': ['Level 25 Reached!', 'Week Warrior'],
        'lastActive': DateTime.now().subtract(const Duration(minutes: 5)),
      },
      {
        'userId': 'user_2',
        'username': 'HiraganaHero',
        'avatarUrl': '',
        'level': 22,
        'totalXp': 21000,
        'streak': 12,
        'recentAchievements': ['Level 20 Reached!', 'Hiragana Master'],
        'lastActive': DateTime.now().subtract(const Duration(minutes: 15)),
      },
      {
        'userId': 'user_3',
        'username': 'KatakanaKing',
        'avatarUrl': '',
        'level': 18,
        'totalXp': 17000,
        'streak': 8,
        'recentAchievements': ['Level 15 Reached!'],
        'lastActive': DateTime.now().subtract(const Duration(hours: 1)),
      },
      {
        'userId': 'user_4',
        'username': 'KanjiKnight',
        'avatarUrl': '',
        'level': 15,
        'totalXp': 14000,
        'streak': 6,
        'recentAchievements': ['Level 15 Reached!'],
        'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'userId': 'user_5',
        'username': 'StudySensei',
        'avatarUrl': '',
        'level': 12,
        'totalXp': 11000,
        'streak': 4,
        'recentAchievements': ['Level 10 Reached!'],
        'lastActive': DateTime.now().subtract(const Duration(hours: 3)),
      },
      {
        'userId': 'user_6',
        'username': 'NihongoNinja',
        'avatarUrl': '',
        'level': 10,
        'totalXp': 9000,
        'streak': 3,
        'recentAchievements': ['Level 10 Reached!'],
        'lastActive': DateTime.now().subtract(const Duration(hours: 4)),
      },
      {
        'userId': 'user_7',
        'username': 'LanguageLover',
        'avatarUrl': '',
        'level': 8,
        'totalXp': 7000,
        'streak': 2,
        'recentAchievements': ['Level 5 Reached!'],
        'lastActive': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'userId': 'user_8',
        'username': 'JapaneseJedi',
        'avatarUrl': '',
        'level': 6,
        'totalXp': 5000,
        'streak': 1,
        'recentAchievements': ['Level 5 Reached!'],
        'lastActive': DateTime.now().subtract(const Duration(hours: 6)),
      },
      {
        'userId': 'user_9',
        'username': 'AnimeAce',
        'avatarUrl': '',
        'level': 4,
        'totalXp': 3000,
        'streak': 1,
        'recentAchievements': ['Level 2 Reached!'],
        'lastActive': DateTime.now().subtract(const Duration(hours: 7)),
      },
      {
        'userId': 'user_10',
        'username': 'MangaMaster',
        'avatarUrl': '',
        'level': 3,
        'totalXp': 2000,
        'streak': 0,
        'recentAchievements': ['Level 2 Reached!'],
        'lastActive': DateTime.now().subtract(const Duration(hours: 8)),
      },
    ];

    // Add current user to the list
    final currentUserData = {
      'userId': currentUserId,
      'username': 'You',
      'avatarUrl': '',
      'level': currentUserProgress.level,
      'totalXp': currentUserProgress.totalXp,
      'streak': currentUserProgress.currentStreak,
      'recentAchievements': _getCurrentUserAchievements(currentUserProgress.level),
      'lastActive': DateTime.now(),
    };

    // Combine all users
    final allUsers = [...mockUsers, currentUserData];

    // Sort by total XP (descending)
    allUsers.sort((a, b) => (b['totalXp'] as int).compareTo(a['totalXp'] as int));

    // Create leaderboard entries with ranks
    final entries = <LeaderboardEntry>[];
    for (int i = 0; i < allUsers.length; i++) {
      final user = allUsers[i];
      final rank = i + 1;
      final level = user['level'] as int;

      entries.add(LeaderboardEntry(
        userId: user['userId'] as String,
        username: user['username'] as String,
        avatarUrl: user['avatarUrl'] as String,
        level: level,
        totalXp: user['totalXp'] as int,
        rank: rank,
        rankBadge: LeaderboardEntry.calculateRankBadge(level),
        lastActive: user['lastActive'] as DateTime,
        streak: user['streak'] as int,
        recentAchievements: List<String>.from(user['recentAchievements'] as List),
        isCurrentUser: user['userId'] == currentUserId,
      ));
    }

    // Find current user entry
    final currentUserEntry = entries.firstWhere(
      (entry) => entry.isCurrentUser,
      orElse: () => entries.first,
    );

    final leaderboardData = LeaderboardData(
      entries: entries,
      currentUserEntry: currentUserEntry,
      totalUsers: entries.length,
      lastUpdated: DateTime.now(),
    );

    // Save to local storage
    await _saveLeaderboardData(leaderboardData);

    return leaderboardData;
  }

  // Get current user achievements based on level
  List<String> _getCurrentUserAchievements(int level) {
    final achievements = <String>[];

    if (level >= 2) achievements.add('Level 2 Reached!');
    if (level >= 5) achievements.add('Level 5 Reached!');
    if (level >= 10) achievements.add('Level 10 Reached!');
    if (level >= 15) achievements.add('Level 15 Reached!');
    if (level >= 20) achievements.add('Level 20 Reached!');
    if (level >= 25) achievements.add('Level 25 Reached!');
    if (level >= 50) achievements.add('Level 50 Reached!');

    return achievements;
  }

  // Save leaderboard data to local storage
  Future<void> _saveLeaderboardData(LeaderboardData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_leaderboardKey, jsonEncode(data.toJson()));
    } catch (e) {
      // print('Error saving leaderboard data: $e');
    }
  }

  // Refresh leaderboard data
  Future<LeaderboardData> refreshLeaderboard() async {
    return await _generateLeaderboardData();
  }

  // Get user's rank in leaderboard
  Future<int> getUserRank() async {
    final leaderboard = await getLeaderboard();
    return leaderboard.currentUserEntry?.rank ?? 1;
  }

  // Get users around current user's rank
  Future<List<LeaderboardEntry>> getUsersAroundRank(int range) async {
    final leaderboard = await getLeaderboard();
    final currentRank = leaderboard.currentUserEntry?.rank ?? 1;

    final startIndex = (currentRank - range - 1).clamp(0, leaderboard.entries.length - 1);
    final endIndex = (currentRank + range).clamp(0, leaderboard.entries.length);

    return leaderboard.entries.sublist(startIndex, endIndex);
  }

  // Watch real-time leaderboard updates from Firebase
  Stream<LeaderboardData> watchLeaderboard() {
    return _firebaseSync.watchLeaderboard().asyncMap((firebaseData) async {
      if (firebaseData.isEmpty) {
        // Return empty leaderboard if no data
        return LeaderboardData(
          entries: [],
          currentUserEntry: null,
          totalUsers: 0,
          lastUpdated: DateTime.now(),
        );
      }

      // Convert Firebase data to LeaderboardData
      final entries = <LeaderboardEntry>[];
      for (int i = 0; i < firebaseData.length; i++) {
        final user = firebaseData[i];
        final rank = i + 1;
        final level = user['level'] as int? ?? 1;
        final totalXp = user['totalXp'] as int? ?? 0;
        final userId = user['userId'] as String? ?? '';
        final displayName = user['displayName'] as String? ?? 'Anonymous';
        final currentStreak = user['currentStreak'] as int? ?? 0;
        final lastActiveTimestamp = user['lastActive'] as int?;

        DateTime lastActive;
        if (lastActiveTimestamp != null) {
          lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveTimestamp);
        } else {
          lastActive = DateTime.now().subtract(const Duration(hours: 1));
        }

        entries.add(LeaderboardEntry(
          userId: userId,
          username: displayName,
          avatarUrl: user['photoURL'] as String? ?? '',
          level: level,
          totalXp: totalXp,
          rank: rank,
          rankBadge: LeaderboardEntry.calculateRankBadge(level),
          lastActive: lastActive,
          streak: currentStreak,
          recentAchievements: _getCurrentUserAchievements(level),
          isCurrentUser: false, // Will be updated below
        ));
      }

      // Find current user entry
      final currentUserId = await _getCurrentUserId();
      LeaderboardEntry? currentUserEntry;

      for (int i = 0; i < entries.length; i++) {
        if (entries[i].userId == currentUserId) {
          currentUserEntry = entries[i].copyWith(isCurrentUser: true);
          entries[i] = currentUserEntry;
          break;
        }
      }

      return LeaderboardData(
        entries: entries,
        currentUserEntry: currentUserEntry,
        totalUsers: entries.length,
        lastUpdated: DateTime.now(),
      );
    });
  }

  // Force refresh from Firebase
  Future<LeaderboardData> refreshFromFirebase() async {
    final firebaseData = await _getFirebaseLeaderboardData();
    if (firebaseData != null) {
      return firebaseData;
    }
    return await _generateLeaderboardData();
  }
}
