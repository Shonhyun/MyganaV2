import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SuperAdminContentOverviewScreen extends StatelessWidget {
  const SuperAdminContentOverviewScreen({super.key});

  Future<Map<String, int>> _loadCounts() async {
    final db = FirebaseDatabase.instance.ref();
    int lessons = 0;
    int quizzes = 0;
    int classes = 0;
    try {
      final l = await db.child('lessons').get();
      if (l.exists && l.value is Map) lessons = (l.value as Map).length;
    } catch (_) {}
    try {
      final q = await db.child('admin_quizzes').get();
      if (q.exists && q.value is Map) quizzes = (q.value as Map).length - ((q.child('_placeholder').exists) ? 1 : 0);
    } catch (_) {}
    try {
      final c = await db.child('classes').get();
      if (c.exists && c.value is Map) classes = (c.value as Map).length;
    } catch (_) {}
    return {
      'lessons': lessons,
      'quizzes': quizzes,
      'classes': classes,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _loadCounts(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final counts = snapshot.data ?? {'lessons': 0, 'quizzes': 0, 'classes': 0};
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                        Theme.of(context).primaryColor.withOpacity(0.5),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8)
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.dashboard_rounded, color: Colors.white.withOpacity(0.9), size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Content',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Global overview and drill-down',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w500
                        )
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _StatCard(
                        title: 'Lessons',
                        value: counts['lessons']!,
                        color: Colors.indigo,
                        icon: Icons.menu_book,
                        loading: isLoading,
                        onTap: () => Navigator.pushNamed(context, '/super_admin/content/lessons'),
                      ),
                      const SizedBox(height: 12),
                      _StatCard(
                        title: 'Quizzes',
                        value: counts['quizzes']!,
                        color: Colors.teal,
                        icon: Icons.quiz,
                        loading: isLoading,
                        onTap: () => Navigator.pushNamed(context, '/super_admin/content/quizzes'),
                      ),
                      const SizedBox(height: 12),
                      _StatCard(
                        title: 'Classes',
                        value: counts['classes']!,
                        color: Colors.orange,
                        icon: Icons.class_,
                        loading: isLoading,
                        onTap: () => Navigator.pushNamed(context, '/super_admin/content/classes'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 6)),
                    ],
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tap a card to view items. Use the menu on each row to Preview, Edit, or Delete.',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;
  const _StatCard({required this.title, required this.value, required this.color, required this.icon, required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.08), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 4),
              loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('$value', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
            ]),
          ),
        ],
      ),
      ),
    );
  }
}
