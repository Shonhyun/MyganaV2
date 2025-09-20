import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nihongo_japanese_app/services/class_management_service.dart';

// Safe mappers and parsers for dynamic Firebase data
Map<String, dynamic>? _safeMap(dynamic value) {
  if (value is Map) {
    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      final Map<String, dynamic> m = {};
      (value as Map).forEach((k, v) => m[k.toString()] = v);
      return m;
    }
  }
  return null;
}

num _numValue(dynamic v, [num fallback = 0]) {
  if (v is num) return v;
  final s = v?.toString();
  if (s == null) return fallback;
  final d = double.tryParse(s);
  if (d != null) return d;
  final i = int.tryParse(s);
  return i ?? fallback;
}

int _intValue(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v?.toString();
  if (s == null) return fallback;
  return int.tryParse(s) ?? double.tryParse(s)?.toInt() ?? fallback;
}

//

class AdminClassStudentsScreen extends StatelessWidget {
  final String classId;
  final String title;

  const AdminClassStudentsScreen({super.key, required this.classId, required this.title});

  @override
  Widget build(BuildContext context) {
    final service = ClassManagementService();
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          // Modern header with gradient and copyable class code
          StreamBuilder<ClassInfo?>(
            stream: service.watchClass(classId),
            builder: (context, classSnap) {
              final info = classSnap.data;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.primary.withOpacity(0.15),
                      color.primaryContainer.withOpacity(0.10),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.class_, color: color.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info?.nameSection ?? title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text('Year: ${info?.yearRange ?? '-'}',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            final code = info?.classCode ?? '';
                            if (code.isEmpty) return;
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Class code copied')),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: color.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: color.primary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.qr_code_2, size: 18),
                                const SizedBox(width: 6),
                                Text(info?.classCode ?? '...',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          // Overview metrics as modern cards
          StreamBuilder<List<StudentProgressSummary>>(
            stream: service.watchClassMembersWithStats(classId),
            builder: (context, membersSnap) {
              final students = (membersSnap.data ?? []).map((s) {
                final stats = _safeMap(s.userStatistics) ?? {};
                return StudentProgressSummary(
                  userId: s.userId,
                  displayName: s.displayName,
                  email: s.email,
                  userStatistics: stats,
                );
              }).toList();
              final totalStudents = students.length;
              final totalPoints = students.fold<int>(0, (sum, s) => sum + _intValue(s.userStatistics['totalPoints']));
              final avgPoints = totalStudents > 0 ? (totalPoints / totalStudents).round() : 0;

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: _StatGrid(
                  children: [
                    _StatCard(icon: Icons.group, label: 'Students', value: '$totalStudents', color: color.primary),
                    _StatCard(icon: Icons.stars_rounded, label: 'Avg Points', value: '$avgPoints', color: color.secondary),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<StudentProgressSummary>>(
              stream: service.watchClassMembersWithStats(classId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final students = snapshot.data ?? [];
                if (students.isEmpty) {
                  return const Center(child: Text('No students enrolled yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index];
                    return _StudentCard(student: s);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// _OverviewChip removed (replaced by _StatCard)

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: textTheme.bodySmall?.copyWith(color: Colors.black.withOpacity(0.6))),
                Text(value, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

void _showStudentProgressDialog(BuildContext context, StudentProgressSummary s) {
  final stats = _safeMap(s.userStatistics) ?? {};
  final totalPoints = _intValue(stats['totalPoints']);
  final streak = _safeMap(stats['streakAnalytics']);
  final daily = _safeMap(stats['dailyProgressStats']);
  final overallStreakPct = _numValue(streak?['overallPercentage']);
  final dailyPct = _numValue(daily?['dailyProgressPercentage']);

  final hiragana = _numValue(stats['hiraganaMastery']) * 100;
  final katakana = _numValue(stats['katakanaMastery']) * 100;

  final quiz = _safeMap(stats['quizStatistics']);
  final story = _safeMap(stats['storyStatistics']);

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final color = Theme.of(ctx).colorScheme;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.primary.withOpacity(0.12),
                    child: Text(
                      s.displayName.isNotEmpty ? s.displayName[0].toUpperCase() : '?',
                      style: TextStyle(color: color.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(s.email, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(text: 'Progress Overview'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _StatCard(icon: Icons.trending_up, label: 'Streak Success %', value: '${overallStreakPct.toStringAsFixed(1)}%', color: color.primary)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(icon: Icons.timer_outlined, label: 'Daily Goal', value: '${dailyPct.toStringAsFixed(0)}%', color: color.secondary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _StatCard(icon: Icons.workspace_premium, label: 'Total Points', value: '$totalPoints', color: color.tertiary)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(icon: Icons.emoji_events_outlined, label: 'Longest Streak', value: '${streak?['longestStreak'] ?? 0}', color: color.primary)),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const _SectionTitle(text: 'Character Mastery'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _ProgressTile(label: 'Hiragana', percent: (hiragana / 100).clamp(0.0, 1.0), color: Colors.green)),
                          const SizedBox(width: 10),
                          Expanded(child: _ProgressTile(label: 'Katakana', percent: (katakana / 100).clamp(0.0, 1.0), color: Colors.blue)),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const _SectionTitle(text: 'Quiz Performance'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _StatCard(icon: Icons.quiz_outlined, label: 'Total Quizzes', value: '${quiz?['totalQuizzes'] ?? 0}', color: color.primary)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(icon: Icons.show_chart, label: 'Avg. Score', value: '${((quiz?['averageScore'] ?? 0.0) as num).toStringAsFixed(1)}%', color: color.secondary)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(icon: Icons.celebration_outlined, label: 'Perfect', value: '${quiz?['perfectScores'] ?? 0}', color: color.tertiary)),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const _SectionTitle(text: 'Story Mode Statistics'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _StatCard(icon: Icons.star_border, label: 'Total Points', value: '${story?['totalPoints'] ?? 0}', color: color.primary)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(icon: Icons.play_arrow_outlined, label: 'Sessions', value: '${story?['sessionCount'] ?? 0}', color: color.secondary)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(icon: Icons.trending_up, label: 'Avg. Score', value: '${((story?['averageScore'] ?? 0.0) as num).toStringAsFixed(1)}', color: color.tertiary)),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  final String label;
  final double percent; // 0..1
  final Color color;
  const _ProgressTile({required this.label, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${(percent * 100).clamp(0, 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: percent.clamp(0.0, 1.0),
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final List<Widget> children;
  const _StatGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 360;
    final spacing = isSmall ? 8.0 : 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (w) => SizedBox(
                  width: (constraints.maxWidth - spacing) / 2,
                  child: w,
                ),
              )
              .toList(),
        );
      },
    );
  }
}


class _StudentCard extends StatelessWidget {
  final StudentProgressSummary student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
  final stats = _safeMap(student.userStatistics) ?? {};
  final totalPoints = _intValue(stats['totalPoints']).toString();
  final quizStats = _safeMap(stats['quizStatistics']);
  final storyStats = _safeMap(stats['storyStatistics']);
  final overall = (_numValue(stats['overallMastery']) * 100).clamp(0, 100).toDouble();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showStudentProgressDialog(context, student),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: color.primary.withOpacity(0.1),
                      child: Text(
                        student.displayName.isNotEmpty ? student.displayName[0].toUpperCase() : '?',
                        style: TextStyle(color: color.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(student.email, style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium, color: color.secondary, size: 16),
                          const SizedBox(width: 4),
                          Text(totalPoints, style: TextStyle(color: color.secondary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Overall Mastery'),
                    Text('${overall.toStringAsFixed(0)}%'),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: (overall / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(color.primary),
                  ),
                ),
                if (quizStats != null || storyStats != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (quizStats != null)
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.quiz_outlined,
                            label: 'Quizzes',
                            value:
                                '${quizStats['totalQuizzes'] ?? 0} • ${(quizStats['averageScore'] ?? 0.0).toStringAsFixed(1)}%'
                          ),
                        ),
                      if (storyStats != null) const SizedBox(width: 8),
                      if (storyStats != null)
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.menu_book_outlined,
                            label: 'Story',
                            value:
                                '${storyStats['sessionCount'] ?? 0} • ${(storyStats['averageScore'] ?? 0.0).toStringAsFixed(1)}'
                          ),
                        ),
                    ],
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}


