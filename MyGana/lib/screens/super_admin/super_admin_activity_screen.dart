import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SuperAdminActivityScreen extends StatelessWidget {
  const SuperAdminActivityScreen({super.key});

  Stream<List<_ActivityUser>> _watchLeaderboard() {
    final db = FirebaseDatabase.instance.ref();
    return db.child('leaderboard').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return <_ActivityUser>[];
      final Map<dynamic, dynamic> map = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      final List<_ActivityUser> users = [];
      for (final entry in map.entries) {
        final data = Map<dynamic, dynamic>.from(entry.value);
        users.add(_ActivityUser(
          userId: entry.key.toString(),
          displayName: data['displayName']?.toString() ?? 'User',
          totalXp: (data['totalXp'] is int) ? data['totalXp'] as int : 0,
          lastActive: data['lastActive'] is int ? (data['lastActive'] as int) : 0,
          isOnline: data['isOnline'] == true,
        ));
      }
      users.sort((a, b) => (b.lastActive).compareTo(a.lastActive));
      return users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_ActivityUser>>(
      stream: _watchLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8)),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Activity', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('Live user status and last activity', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (users.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No activity yet.')),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: users.map((u) {
                    final lastActive = DateTime.fromMillisecondsSinceEpoch(u.lastActive, isUtc: false).toLocal();
                    final onlineColor = u.isOnline ? Colors.green : Colors.grey;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
                        border: Border.all(color: Colors.black.withOpacity(0.04)),
                      ),
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: onlineColor.withOpacity(0.12),
                              child: Icon(Icons.person, color: onlineColor),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(color: onlineColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              ),
                            )
                          ],
                        ),
                        title: Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('XP: ${u.totalXp} • Last Active: $lastActive'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActivityUser {
  final String userId;
  final String displayName;
  final int totalXp;
  final int lastActive;
  final bool isOnline;
  _ActivityUser({required this.userId, required this.displayName, required this.totalXp, required this.lastActive, required this.isOnline});
}


