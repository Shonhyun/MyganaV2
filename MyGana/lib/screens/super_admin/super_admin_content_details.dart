import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SuperAdminLessonDetailsScreen extends StatelessWidget {
  final String lessonId;
  const SuperAdminLessonDetailsScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref().child('lessons/$lessonId');
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Details')),
      body: FutureBuilder<DataSnapshot>(
        future: ref.get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData || !snap.data!.exists) return const Center(child: Text('Not found'));
          final Map<dynamic, dynamic> l = Map<dynamic, dynamic>.from(snap.data!.value as Map);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _DT('Title', l['title']?.toString() ?? ''),
                _DT('Level', l['level']?.toString() ?? ''),
                _DT('Category', l['category']?.toString() ?? ''),
                const SizedBox(height: 8),
                Text(l['description']?.toString() ?? ''),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Example Sentences', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                FutureBuilder<DataSnapshot>(
                  future: ref.child('example_sentences').get(),
                  builder: (context, es) {
                    if (es.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!es.hasData || !es.data!.exists) return const Text('No example sentences');
                    final Map<dynamic, dynamic> m = Map<dynamic, dynamic>.from(es.data!.value as Map);
                    final list = m.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();
                    return Column(
                      children: list.map((s) => ListTile(
                        leading: const Icon(Icons.circle, size: 10),
                        title: Text(s['sentence']?.toString() ?? ''),
                        subtitle: Text(s['translation']?.toString() ?? ''),
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SuperAdminQuizDetailsScreen extends StatelessWidget {
  final String quizId;
  const SuperAdminQuizDetailsScreen({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref().child('admin_quizzes/$quizId');
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Details')),
      body: FutureBuilder<DataSnapshot>(
        future: ref.get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData || !snap.data!.exists) return const Center(child: Text('Not found'));
          final Map<dynamic, dynamic> q = Map<dynamic, dynamic>.from(snap.data!.value as Map);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _DT('Title', q['title']?.toString() ?? ''),
                _DT('Active', q['isActive'] == true ? 'Yes' : 'No'),
                const SizedBox(height: 8),
                Text(q['description']?.toString() ?? ''),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Questions', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                FutureBuilder<DataSnapshot>(
                  future: ref.child('questions').get(),
                  builder: (context, es) {
                    if (es.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!es.hasData || ! es.data!.exists) return const Text('No questions');
                    final val = es.data!.value;
                    final List<Map<String, dynamic>> list;
                    if (val is List) {
                      list = val.where((e) => e != null).map((e) => Map<String, dynamic>.from(e as Map)).toList();
                    } else {
                      final Map<dynamic, dynamic> m = Map<dynamic, dynamic>.from(val as Map);
                      list = m.values.map((e) => Map<String, dynamic>.from(e)).toList();
                    }
                    return Column(
                      children: list.asMap().entries.map((e) => ListTile(
                        leading: CircleAvatar(child: Text('${e.key + 1}')),
                        title: Text(e.value['questionText']?.toString() ?? ''),
                        subtitle: Text('Type: ${e.value['type'] ?? 'N/A'}'),
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SuperAdminClassDetailsScreen extends StatelessWidget {
  final String classId;
  const SuperAdminClassDetailsScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseDatabase.instance.ref();
    return Scaffold(
      appBar: AppBar(title: const Text('Class Details')),
      body: FutureBuilder<DataSnapshot>(
        future: db.child('classes/$classId').get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData || !snap.data!.exists) return const Center(child: Text('Not found'));
          final Map<dynamic, dynamic> c = Map<dynamic, dynamic>.from(snap.data!.value as Map);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _DT('Name Section', c['nameSection']?.toString() ?? ''),
                _DT('Year Range', c['yearRange']?.toString() ?? ''),
                _DT('Class Code', c['classCode']?.toString() ?? ''),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Members', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                FutureBuilder<DataSnapshot>(
                  future: db.child('classMembers/$classId').get(),
                  builder: (context, ms) {
                    if (ms.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!ms.hasData || !ms.data!.exists) return const Text('No members');
                    final Map<dynamic, dynamic> m = Map<dynamic, dynamic>.from(ms.data!.value as Map);
                    final entries = m.entries.toList();
                    return Column(
                      children: entries.map((e) => FutureBuilder<DataSnapshot>(
                        future: db.child('users/${e.key}').get(),
                        builder: (context, us) {
                          if (!us.hasData || !us.data!.exists) return const SizedBox.shrink();
                          final Map<dynamic, dynamic> u = Map<dynamic, dynamic>.from(us.data!.value as Map);
                          final name = ((u['firstName'] ?? '').toString() + ' ' + (u['lastName'] ?? '').toString()).trim();
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(name.isEmpty ? (u['email']?.toString() ?? '') : name),
                            subtitle: Text(u['email']?.toString() ?? ''),
                          );
                        },
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DT extends StatelessWidget {
  final String k;
  final String v;
  const _DT(this.k, this.v);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(k, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}


