import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nihongo_japanese_app/services/auth_service.dart';
import 'package:nihongo_japanese_app/services/admin_user_management_service.dart';

class SuperAdminUsersScreen extends StatefulWidget {
  const SuperAdminUsersScreen({super.key});

  @override
  State<SuperAdminUsersScreen> createState() => _SuperAdminUsersScreenState();
}

class _SuperAdminUsersScreenState extends State<SuperAdminUsersScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final AuthService _auth = AuthService();
  bool _loading = true;
  List<_UserItem> _users = [];
  final TextEditingController _inviteEmailController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regFirstNameController = TextEditingController();
  final TextEditingController _regLastNameController = TextEditingController();
  String _regGender = 'Prefer not to say';
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await _db.child('users').get();
      final List<_UserItem> items = [];
      if (snap.exists && snap.value is Map) {
        final map = Map<dynamic, dynamic>.from(snap.value as Map);
        map.forEach((key, value) {
          final data = Map<dynamic, dynamic>.from(value);
          items.add(_UserItem(
            uid: key.toString(),
            email: data['email']?.toString() ?? '',
            name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
            role: data['role']?.toString() ?? ((data['isAdmin'] == true) ? 'teacher' : 'student'),
          ));
        });
      }
      items.sort((a, b) => a.role.compareTo(b.role));
      if (mounted) setState(() { _users = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Invite flow removed in favor of direct registration

  Future<void> _registerTeacherAccount() async {
    final formKey = GlobalKey<FormState>();
    _regEmailController.clear();
    _regPasswordController.clear();
    _regFirstNameController.clear();
    _regLastNameController.clear();
    _regGender = 'Prefer not to say';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Register Teacher',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _regEmailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _regPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _regFirstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name (optional)',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _regLastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name (optional)', 
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _regGender,
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Non-binary', child: Text('Non-binary')),
                      DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                    ],
                    onChanged: (v) => _regGender = v ?? 'Prefer not to say',
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: const Icon(Icons.people_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Register', style: TextStyle(fontSize: 16)),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      ),
    );
    if (saved != true) return;
    try {
      await AdminUserManagementService().createTeacherAccount(
        email: _regEmailController.text.trim(),
        password: _regPasswordController.text,
        firstName: _regFirstNameController.text.trim().isEmpty ? null : _regFirstNameController.text.trim(),
        lastName: _regLastNameController.text.trim().isEmpty ? null : _regLastNameController.text.trim(),
        gender: _regGender,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher account created'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateRole(_UserItem user, String newRole) async {
    try {
      await _db.child('users/${user.uid}').update({
        'role': newRole,
        'isAdmin': (newRole == 'teacher' || newRole == 'super_admin'),
        'updatedAt': ServerValue.timestamp,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role updated successfully')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser(_UserItem user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${user.name.isEmpty ? user.email : user.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _db.child('users/${user.uid}').remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final teachers = _users
        .where((u) => (u.role == 'teacher' || u.role == 'super_admin'))
        .where((u) => _query.isEmpty || u.email.toLowerCase().contains(_query) || u.name.toLowerCase().contains(_query))
        .toList();
    final students = _users
        .where((u) => u.role == 'student')
        .where((u) => _query.isEmpty || u.email.toLowerCase().contains(_query) || u.name.toLowerCase().contains(_query))
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // Header with gradient and search
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
              children: [
                const Text('Users', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Manage teachers and students', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search name or email...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Register teacher card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 6))],
              border: Border.all(color: Colors.black.withOpacity(0.04)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Register Teacher', style: TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Create a new teacher account (email & password)'),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _registerTeacherAccount,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Register'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Teachers section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                Icon(Icons.workspaces_outline, size: 18),
                SizedBox(width: 8),
                Text('Teachers', style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: teachers.map((u) => _buildUserTile(u)).toList(),
            ),
          ),
          const SizedBox(height: 18),
          // Students section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                Icon(Icons.school_outlined, size: 18),
                SizedBox(width: 8),
                Text('Students', style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: students.map((u) => _buildUserTile(u)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(_UserItem u, {bool? isSelfOverride}) {
    final isSelf = isSelfOverride ?? (_auth.currentUser?.uid == u.uid);
    final roleColor = u.role == 'super_admin'
        ? Colors.deepPurple
        : u.role == 'teacher'
            ? Colors.blue
            : Colors.green;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.12),
          child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?', style: TextStyle(color: roleColor, fontWeight: FontWeight.w700)),
        ),
        title: Row(
          children: [
            Expanded(child: Text(u.name.isEmpty ? u.email : u.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            _RoleBadge(role: u.role),
          ],
        ),
        subtitle: Text(u.email, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              onSelected: (role) => _updateRole(u, role),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'student', child: Text('Make Student')),
                PopupMenuItem(value: 'teacher', child: Text('Make Teacher')),
                PopupMenuItem(value: 'super_admin', child: Text('Make Super Admin')),
              ],
              child: const Icon(Icons.more_vert),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: isSelf ? null : () => _deleteUser(u),
              tooltip: isSelf ? 'Cannot delete current account' : 'Delete user',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _inviteEmailController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regFirstNameController.dispose();
    _regLastNameController.dispose();
    super.dispose();
  }
}

class _RoleBadge extends StatelessWidget {
  final String role; const _RoleBadge({required this.role});
  @override
  Widget build(BuildContext context) {
    Color color = role == 'super_admin' ? Colors.deepPurple : role == 'teacher' ? Colors.blue : Colors.green;
    String label = role == 'super_admin' ? 'Super Admin' : role == 'teacher' ? 'Teacher' : 'Student';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _UserItem {
  final String uid;
  final String email;
  final String name;
  final String role;
  _UserItem({required this.uid, required this.email, required this.name, required this.role});
}


