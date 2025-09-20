import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nihongo_japanese_app/screens/leaderboard_screen.dart';
import 'package:nihongo_japanese_app/services/challenge_progress_service.dart';
import 'package:nihongo_japanese_app/services/daily_points_service.dart';
import 'package:nihongo_japanese_app/services/progress_service.dart';
import 'package:nihongo_japanese_app/services/review_progress_service.dart';
import 'package:nihongo_japanese_app/services/streak_analytics_service.dart';
import 'package:nihongo_japanese_app/widgets/sync_status_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStatsScreen extends StatefulWidget {
  const UserStatsScreen({super.key});

  @override
  State<UserStatsScreen> createState() => _UserStatsScreenState();
}

class _UserStatsScreenState extends State<UserStatsScreen> {
  final ProgressService _progressService = ProgressService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _progressService.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1C2E) : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Your Statistics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          const SyncStatusWidget(showDetails: true),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.leaderboard_rounded,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaderboardScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: _initializeData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _initializeData,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(context, isDarkMode, primaryColor),
                    const SizedBox(height: 24),
                    _buildProgressOverview(context, isDarkMode, primaryColor),
                    const SizedBox(height: 24),
                    _buildCharacterMasterySection(context, isDarkMode, primaryColor),
                    const SizedBox(height: 24),
                    _buildQuizPerformanceSection(context, isDarkMode, primaryColor),
                    const SizedBox(height: 24),
                    _buildStoryStatisticsSection(context, isDarkMode, primaryColor),
                    const SizedBox(height: 24),
                    _buildStreakAnalyticsSection(context, isDarkMode, primaryColor),
                    const SizedBox(height: 24),
                    _buildAchievementsSection(context, isDarkMode, primaryColor),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, bool isDarkMode, Color primaryColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, Color.lerp(primaryColor, Colors.purple, 0.3)!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _getOverallStatistics(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(color: Colors.white);
                      }

                      final stats = snapshot.data ?? {};
                      final level = stats['level'] ?? 1;
                      final totalXp = stats['totalXp'] ?? 0;
                      final nextLevelXp = level * 1000;
                      final currentLevelXp = (level - 1) * 1000;
                      final progressToNextLevel =
                          (totalXp - currentLevelXp) / (nextLevelXp - currentLevelXp);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level $level',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalXp XP',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progressToNextLevel.clamp(0.0, 1.0),
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(nextLevelXp - totalXp)} XP to next level',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverview(BuildContext context, bool isDarkMode, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Overview',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                context,
                isDarkMode,
                'Streak Success %',
                Icons.trending_up,
                Colors.purple,
                () => _getStreakPercentage(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                context,
                isDarkMode,
                'Daily Goal',
                Icons.timer,
                Colors.blue,
                () => _getDailyGoalProgress(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                context,
                isDarkMode,
                'Total Points',
                Icons.stars,
                Colors.indigo,
                () => _getTotalPoints(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                context,
                isDarkMode,
                'Longest Streak',
                Icons.workspace_premium,
                Colors.amber,
                () => _getLongestStreak(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCharacterMasterySection(BuildContext context, bool isDarkMode, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Character Mastery',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMasteryCard(
                context,
                isDarkMode,
                'Hiragana',
                Icons.abc,
                Colors.green,
                () => _getHiraganaMastery(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMasteryCard(
                context,
                isDarkMode,
                'Katakana',
                Icons.abc,
                Colors.blue,
                () => _getKatakanaMastery(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuizPerformanceSection(BuildContext context, bool isDarkMode, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiz Performance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, dynamic>>(
          future: _getQuizStatistics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final quizStats = snapshot.data ?? {};
            final totalQuizzes = quizStats['totalQuizzes'] ?? 0;
            final averageScore = quizStats['averageScore'] ?? 0.0;
            final perfectScores = quizStats['perfectScores'] ?? 0;

            return Row(
              children: [
                Expanded(
                  child: _buildQuizCard(
                    context,
                    isDarkMode,
                    'Total Quizzes',
                    Icons.quiz,
                    Colors.indigo,
                    '$totalQuizzes',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuizCard(
                    context,
                    isDarkMode,
                    'Avg. Score',
                    Icons.trending_up,
                    Colors.teal,
                    '${averageScore.toStringAsFixed(1)}%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuizCard(
                    context,
                    isDarkMode,
                    'Perfect',
                    Icons.celebration,
                    Colors.pink,
                    '$perfectScores',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStoryStatisticsSection(BuildContext context, bool isDarkMode, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Story Mode Statistics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, dynamic>>(
          future: _getStoryStatistics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final storyStats = snapshot.data ?? {};
            final totalPoints = storyStats['totalPoints'] ?? 0;
            final sessionCount = storyStats['sessionCount'] ?? 0;
            final averageScore = storyStats['averageScore'] ?? 0.0;

            return Row(
              children: [
                Expanded(
                  child: _buildQuizCard(
                    context,
                    isDarkMode,
                    'Total Points',
                    Icons.stars,
                    Colors.purple,
                    '$totalPoints',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuizCard(
                    context,
                    isDarkMode,
                    'Sessions',
                    Icons.play_arrow,
                    Colors.orange,
                    '$sessionCount',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuizCard(
                    context,
                    isDarkMode,
                    'Avg Score',
                    Icons.trending_up,
                    Colors.green,
                    '${averageScore.toStringAsFixed(0)}',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStreakAnalyticsSection(BuildContext context, bool isDarkMode, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Streak Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, dynamic>>(
          future: _getStreakAnalytics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final analytics = snapshot.data ?? {};
            final overallPercentage = analytics['overallPercentage'] ?? 0.0;
            final challengePercentage = analytics['challengePercentage'] ?? 0.0;
            final reviewPercentage = analytics['reviewPercentage'] ?? 0.0;
            final performanceLevel = analytics['performanceLevel'] ?? 'Needs Improvement';
            final performanceColor = Color(analytics['performanceColor'] ?? 0xFFF44336);

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2B2D42) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: performanceColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Overall Streak Performance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${overallPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                              color: performanceColor,
                            ),
                          ),
                          Text(
                            performanceLevel,
                            style: TextStyle(
                              color: performanceColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: performanceColor.withOpacity(0.1),
                          border: Border.all(
                            color: performanceColor,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${overallPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: performanceColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStreakBreakdownCard(
                          context,
                          isDarkMode,
                          'Challenges',
                          challengePercentage,
                          Icons.emoji_events,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStreakBreakdownCard(
                          context,
                          isDarkMode,
                          'Reviews',
                          reviewPercentage,
                          Icons.quiz,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStreakBreakdownCard(
    BuildContext context,
    bool isDarkMode,
    String title,
    double percentage,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E2235) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, bool isDarkMode, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Achievements',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _getAchievements(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final achievements = snapshot.data ?? [];

            if (achievements.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2B2D42) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No achievements yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete lessons and quizzes to earn achievements!',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: achievements.map<Widget>((achievement) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2B2D42) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: achievement['color'].withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: achievement['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          achievement['icon'],
                          color: achievement['color'],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              achievement['description'],
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        achievement['date'],
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    bool isDarkMode,
    String label,
    IconData icon,
    Color color,
    Future<String> Function() valueFuture,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2B2D42) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 12),
          FutureBuilder<String>(
            future: valueFuture(),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? '0',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryCard(
    BuildContext context,
    bool isDarkMode,
    String label,
    IconData icon,
    Color color,
    Future<double> Function() masteryFuture,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2B2D42) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 12),
          FutureBuilder<double>(
            future: masteryFuture(),
            builder: (context, snapshot) {
              final mastery = snapshot.data ?? 0.0;
              return Column(
                children: [
                  Text(
                    '${(mastery * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: mastery,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(
    BuildContext context,
    bool isDarkMode,
    String label,
    IconData icon,
    Color color,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2B2D42) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods to get statistics
  Future<Map<String, dynamic>> _getOverallStatistics() async {
    try {
      final userProgress = _progressService.getUserProgress();
      final dashboardProgress = await _progressService.getDashboardProgress();

      return {
        'level': userProgress.level,
        'totalXp': userProgress.totalXp,
        'longestStreak': userProgress.longestStreak,
        'dailyGoalMinutes': dashboardProgress.dailyGoalMinutes,
        'minutesStudiedToday': dashboardProgress.minutesStudiedToday,
        'totalLessonsCompleted': dashboardProgress.totalLessonsCompleted,
        'totalLessons': dashboardProgress.totalLessons,
      };
    } catch (e) {
      // print('Error getting overall statistics: $e');
      return {};
    }
  }

  Future<String> _getLongestStreak() async {
    try {
      final stats = await _getOverallStatistics();
      return '${stats['longestStreak'] ?? 0}';
    } catch (e) {
      return '0';
    }
  }

  Future<String> _getDailyGoalProgress() async {
    try {
      final stats = await _getOverallStatistics();
      final minutesStudied = stats['minutesStudiedToday'] ?? 0;
      final dailyGoal = stats['dailyGoalMinutes'] ?? 15;
      final progress = (minutesStudied / dailyGoal).clamp(0.0, 1.0);
      return '${(progress * 100).toStringAsFixed(0)}%';
    } catch (e) {
      return '0%';
    }
  }

  Future<String> _getTotalPoints() async {
    try {
      // Get all possible score sources
      final results = await Future.wait([
        // Challenge points from ChallengeProgressService
        ChallengeProgressService().getTotalPoints(),
        // Review points from ReviewProgressService
        ReviewProgressService().getTotalReviewPoints(),
        // Story points from SharedPreferences (if any)
        SharedPreferences.getInstance().then((prefs) => prefs.getInt('story_total_points') ?? 0),
        // Quiz points from SharedPreferences (if any)
        SharedPreferences.getInstance().then((prefs) => prefs.getInt('quiz_total_points') ?? 0),
        // Daily points from DailyPointsService (live calculation)
        DailyPointsService().getLastClaimTime().then((lastClaim) async {
          if (lastClaim == null) return 0;
          final multiplier = await DailyPointsService().getStreakBonusMultiplier();
          return (100 * multiplier).round();
        }),
      ]);

      // Sum all the results
      final totalPoints = results.fold<int>(0, (sum, points) => sum + points);

      // Debug: Total points breakdown
      // print('Total points breakdown:');
      // print('Challenge points: ${results[0]}');
      // print('Review points: ${results[1]}');
      // print('Story points: ${results[2]}');
      // print('Quiz points: ${results[3]}');
      // print('Daily points (live): ${results[4]}');
      // print('Total: $totalPoints');

      return '$totalPoints';
    } catch (e) {
      // print('Error getting total points: $e');
      return '0';
    }
  }

  Future<String> _getStreakPercentage() async {
    try {
      final streakService = StreakAnalyticsService();
      final stats = await streakService.getStreakStatistics();
      return stats['overallPercentageFormatted'] ?? '0.0%';
    } catch (e) {
      return '0.0%';
    }
  }

  // Get story mode statistics
  Future<Map<String, dynamic>> _getStoryStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get total story points
      final totalStoryPoints = prefs.getInt('story_total_points') ?? 0;

      // Get story session count
      final allKeys = prefs.getKeys();
      final storySessionKeys = allKeys.where((key) => key.startsWith('story_session_')).toList();
      final sessionCount = storySessionKeys.length;

      // Calculate average score if we have sessions
      double averageScore = 0.0;
      if (sessionCount > 0) {
        averageScore = totalStoryPoints / sessionCount;
      }

      return {
        'totalPoints': totalStoryPoints,
        'sessionCount': sessionCount,
        'averageScore': averageScore,
      };
    } catch (e) {
      // print('Error getting story statistics: $e');
      return {
        'totalPoints': 0,
        'sessionCount': 0,
        'averageScore': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> _getStreakAnalytics() async {
    try {
      final streakService = StreakAnalyticsService();
      final stats = await streakService.getStreakStatistics();

      final overallPercentage = stats['overallPercentage'] ?? 0.0;
      final performanceLevel = streakService.getStreakPerformanceLevel(overallPercentage);
      final performanceColor = streakService.getStreakPerformanceColor(overallPercentage);

      return {
        ...stats,
        'performanceLevel': performanceLevel,
        'performanceColor': performanceColor,
      };
    } catch (e) {
      return {
        'overallPercentage': 0.0,
        'challengePercentage': 0.0,
        'reviewPercentage': 0.0,
        'performanceLevel': 'Needs Improvement',
        'performanceColor': 0xFFF44336,
      };
    }
  }

  Future<double> _getHiraganaMastery() async {
    try {
      return _progressService.getMasteryLevel('hiragana');
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _getKatakanaMastery() async {
    try {
      return _progressService.getMasteryLevel('katakana');
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> _getQuizStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      // Find all quiz result keys (format: quiz_result_${quizId}_${date})
      final quizResultKeys = allKeys.where((key) => key.startsWith('quiz_result_')).toList();

      if (quizResultKeys.isEmpty) {
        return {
          'totalQuizzes': 0,
          'averageScore': 0.0,
          'perfectScores': 0,
        };
      }

      int totalQuizzes = 0;
      double totalScore = 0.0;
      int perfectScores = 0;
      int passedQuizzes = 0;

      for (final key in quizResultKeys) {
        try {
          final resultString = prefs.getString(key);
          if (resultString != null) {
            final result = jsonDecode(resultString);
            final passed = result['passed'] ?? false;
            final percentage = result['percentage'] ?? 0.0;

            if (passed) {
              totalQuizzes++;
              totalScore += percentage;
              passedQuizzes++;

              if (percentage == 100.0) {
                perfectScores++;
              }
            }
          }
        } catch (e) {
          // Skip invalid quiz result entries
          continue;
        }
      }

      final averageScore = totalQuizzes > 0 ? totalScore / totalQuizzes : 0.0;

      return {
        'totalQuizzes': totalQuizzes,
        'averageScore': averageScore,
        'perfectScores': perfectScores,
        'passedQuizzes': passedQuizzes,
      };
    } catch (e) {
      // print('Error getting quiz statistics: $e');
      return {
        'totalQuizzes': 0,
        'averageScore': 0.0,
        'perfectScores': 0,
        'passedQuizzes': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> _getAchievements() async {
    try {
      final userProgress = _progressService.getUserProgress();
      final achievements = <Map<String, dynamic>>[];

      // Level achievements
      if (userProgress.level >= 2) {
        achievements.add({
          'title': 'Level 2 Reached!',
          'description': 'You\'ve reached level 2 - Getting Started!',
          'icon': Icons.star,
          'color': Colors.blue,
          'date': 'Today',
        });
      }

      if (userProgress.level >= 5) {
        achievements.add({
          'title': 'Level 5 Reached!',
          'description': 'You\'ve reached level 5 - Making Progress!',
          'icon': Icons.emoji_events,
          'color': Colors.amber,
          'date': 'Today',
        });
      }

      if (userProgress.level >= 10) {
        achievements.add({
          'title': 'Level 10 Reached!',
          'description': 'You\'ve reached level 10 - Dedicated Learner!',
          'icon': Icons.workspace_premium,
          'color': Colors.purple,
          'date': 'Today',
        });
      }

      if (userProgress.level >= 15) {
        achievements.add({
          'title': 'Level 15 Reached!',
          'description': 'You\'ve reached level 15 - Serious Student!',
          'icon': Icons.school,
          'color': Colors.indigo,
          'date': 'Today',
        });
      }

      if (userProgress.level >= 20) {
        achievements.add({
          'title': 'Level 20 Reached!',
          'description': 'You\'ve reached level 20 - Advanced Learner!',
          'icon': Icons.military_tech,
          'color': Colors.red,
          'date': 'Today',
        });
      }

      if (userProgress.level >= 25) {
        achievements.add({
          'title': 'Level 25 Reached!',
          'description': 'You\'ve reached level 25 - Expert Level!',
          'icon': Icons.emoji_events,
          'color': Colors.orange,
          'date': 'Today',
        });
      }

      if (userProgress.level >= 50) {
        achievements.add({
          'title': 'Level 50 Reached!',
          'description': 'You\'ve reached level 50 - Master Level!',
          'icon': Icons.diamond,
          'color': Colors.cyan,
          'date': 'Today',
        });
      }

      // Streak achievements - using longest streak instead
      if (userProgress.longestStreak >= 7) {
        achievements.add({
          'title': 'Week Warrior',
          'description': '7-day study streak achieved',
          'icon': Icons.local_fire_department,
          'color': Colors.orange,
          'date': 'Today',
        });
      }

      // Mastery achievements
      final hiraganaMastery = _progressService.getMasteryLevel('hiragana');
      if (hiraganaMastery >= 0.8) {
        achievements.add({
          'title': 'Hiragana Master',
          'description': '80% Hiragana mastery',
          'icon': Icons.abc,
          'color': Colors.green,
          'date': 'Today',
        });
      }

      return achievements;
    } catch (e) {
      return [];
    }
  }
}
