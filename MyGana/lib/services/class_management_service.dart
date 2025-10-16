import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class ClassInfo {
  final String classId;
  final String nameSection;
  final String yearRange;
  final String classCode;
  final String adminId;
  final int createdAt;

  ClassInfo({
    required this.classId,
    required this.nameSection,
    required this.yearRange,
    required this.classCode,
    required this.adminId,
    required this.createdAt,
  });

  factory ClassInfo.fromMap(String id, Map<dynamic, dynamic> data) {
    return ClassInfo(
      classId: id,
      nameSection: data['nameSection']?.toString() ?? '',
      yearRange: data['yearRange']?.toString() ?? '',
      classCode: data['classCode']?.toString() ?? '',
      adminId: data['adminId']?.toString() ?? '',
      createdAt: (data['createdAt'] is int) ? data['createdAt'] as int : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameSection': nameSection,
      'yearRange': yearRange,
      'classCode': classCode,
      'adminId': adminId,
      'createdAt': createdAt,
    };
  }
}

class StudentProgressSummary {
  final String userId;
  final String displayName;
  final String email;
  final Map<String, dynamic> userStatistics;

  StudentProgressSummary({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.userStatistics,
  });
}

class ClassManagementService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _generateClassCode() {
    final rng = Random.secure();
    final number = rng.nextInt(90000) + 10000; // 10000-99999
    return 'CLS-$number';
  }

  Future<String> _generateUniqueClassCode() async {
    for (int i = 0; i < 10; i++) {
      final code = _generateClassCode();
      final snapshot = await _db.child('classCodes').child(code).get();
      if (!snapshot.exists) {
        return code;
      }
    }
    throw Exception('Failed to generate unique class code');
  }

  Future<ClassInfo> createClass({
    required String nameSection,
    required String yearRange,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final classCode = await _generateUniqueClassCode();
    final newClassRef = _db.child('classes').push();
    final classId = newClassRef.key!;

    final data = {
      'nameSection': nameSection,
      'yearRange': yearRange,
      'classCode': classCode,
      'adminId': user.uid,
      'createdBy': user.uid,
      'createdAt': ServerValue.timestamp,
    };

    await newClassRef.set(data);
    await _db.child('classCodes').child(classCode).set({'classId': classId});

    return ClassInfo(
      classId: classId,
      nameSection: nameSection,
      yearRange: yearRange,
      classCode: classCode,
      adminId: user.uid,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<String> enrollCurrentUserWithCode(String classCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final codeSnap1 = await _db.child('classCodes').child(classCode).get();
    var codeSnap = codeSnap1;
    if (!codeSnap.exists) {
      final altSnap = await _db.child('classes_by_code').child(classCode).get();
      codeSnap = altSnap;
    }
    if (!codeSnap.exists) throw Exception('Invalid class code');

    final map = Map<String, dynamic>.from(codeSnap.value as Map);
    final classId = map['classId']?.toString();
    if (classId == null || classId.isEmpty) throw Exception('Invalid class code');

    // Add to class members and user mapping
    final updates = <String, dynamic>{};
    updates['classMembers/$classId/${user.uid}'] = {
      'joinedAt': ServerValue.timestamp,
    };
    updates['userClasses/${user.uid}/$classId'] = {
      'joinedAt': ServerValue.timestamp,
    };
    updates['users/${user.uid}/classId'] = classId; // convenience

    await _db.update(updates);
    return classId;
  }

  Stream<List<ClassInfo>> watchAdminClasses() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream<List<ClassInfo>>.empty();
    }
    final query = _db.child('classes').orderByChild('adminId').equalTo(user.uid);
    return query.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return <ClassInfo>[];
      final raw = event.snapshot.value;
      final Map<dynamic, dynamic> map = raw is Map ? Map<dynamic, dynamic>.from(raw) : {};
      return map.entries
          .map((e) => ClassInfo.fromMap(e.key as String, Map<dynamic, dynamic>.from(e.value)))
          .toList();
    });
  }

  Stream<List<StudentProgressSummary>> watchClassMembersWithStats(String classId) {
    return _db.child('classMembers').child(classId).onValue.asyncMap((event) async {
      if (!event.snapshot.exists || event.snapshot.value == null) return <StudentProgressSummary>[];
      final dynamic rawMembers = event.snapshot.value;
      final Map<dynamic, dynamic> members = rawMembers is Map
          ? Map<dynamic, dynamic>.from(rawMembers)
          : <dynamic, dynamic>{};

      final List<StudentProgressSummary> students = [];
      for (final entry in members.entries) {
        final userId = entry.key.toString();
        try {
          final userSnap = await _db.child('users').child(userId).get();
          if (!userSnap.exists) continue;
          final dynamic raw = userSnap.value;
          final Map<String, dynamic> userData = raw is Map
              ? Map<String, dynamic>.from(raw)
              : <String, dynamic>{};
          final displayName = _buildDisplayName(userData);
          final email = userData['email']?.toString() ?? '';

          final Map<String, dynamic> userStatistics = () {
            final dynamic stats = userData['userStatistics'];
            if (stats is Map) {
              try {
                return Map<String, dynamic>.from(stats);
              } catch (_) {
                final Map<String, dynamic> safe = {};
                stats.forEach((k, v) => safe[k.toString()] = v);
                return safe;
              }
            }
            return <String, dynamic>{};
          }();
          students.add(StudentProgressSummary(
            userId: userId,
            displayName: displayName,
            email: email,
            userStatistics: userStatistics,
          ));
        } catch (e) {
          debugPrint('Error loading member $userId: $e');
        }
      }
      return students;
    });
  }

  Stream<ClassInfo?> watchClass(String classId) {
    return _db.child('classes').child(classId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return null;
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      return ClassInfo.fromMap(classId, data);
    });
  }

  String _buildDisplayName(Map<dynamic, dynamic> userData) {
    final firstName = userData['firstName']?.toString() ?? '';
    final lastName = userData['lastName']?.toString() ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) return '$firstName $lastName';
    if (firstName.isNotEmpty) return firstName;
    if (lastName.isNotEmpty) return lastName;
    return 'Student';
  }

  // Delete student account and remove from class
  Future<void> deleteStudentAccount(String classId, String studentId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Verify admin permissions
    final classSnap = await _db.child('classes').child(classId).get();
    if (!classSnap.exists) throw Exception('Class not found');
    
    final classData = Map<String, dynamic>.from(classSnap.value as Map);
    if (classData['adminId'] != user.uid) {
      throw Exception('Not authorized to delete students from this class');
    }

    // First, remove student from class (without touching user data)
    final classUpdates = <String, dynamic>{};
    classUpdates['classMembers/$classId/$studentId'] = null;
    classUpdates['userClasses/$studentId/$classId'] = null;
    
    await _db.update(classUpdates);

    // Then delete user data separately to avoid path conflicts
    final userUpdates = <String, dynamic>{};
    userUpdates['users/$studentId'] = null;
    userUpdates['userProgress/$studentId'] = null;
    userUpdates['characterProgress/$studentId'] = null;
    userUpdates['quizResults/$studentId'] = null;
    userUpdates['storyProgress/$studentId'] = null;

    await _db.update(userUpdates);
  }

  // Get top student in class based on total points
  Future<StudentProgressSummary?> getTopStudent(String classId) async {
    final students = await watchClassMembersWithStats(classId).first;
    if (students.isEmpty) return null;

    StudentProgressSummary? topStudent;
    int maxPoints = -1;

    for (final student in students) {
      final stats = student.userStatistics;
      final totalPoints = (stats['totalPoints'] is int) ? stats['totalPoints'] as int : 
                         (stats['totalPoints'] is double) ? (stats['totalPoints'] as double).toInt() : 0;
      
      if (totalPoints > maxPoints) {
        maxPoints = totalPoints;
        topStudent = student;
      }
    }

    return topStudent;
  }

  // Get top 10 students in class based on total points
  Future<List<StudentProgressSummary>> getTop10Students(String classId) async {
    final students = await watchClassMembersWithStats(classId).first;
    if (students.isEmpty) return [];

    // Sort students by total points (descending)
    students.sort((a, b) {
      final aPoints = (a.userStatistics['totalPoints'] is int) ? a.userStatistics['totalPoints'] as int : 
                     (a.userStatistics['totalPoints'] is double) ? (a.userStatistics['totalPoints'] as double).toInt() : 0;
      final bPoints = (b.userStatistics['totalPoints'] is int) ? b.userStatistics['totalPoints'] as int : 
                     (b.userStatistics['totalPoints'] is double) ? (b.userStatistics['totalPoints'] as double).toInt() : 0;
      return bPoints.compareTo(aPoints);
    });

    // Return top 10 (or all if less than 10)
    return students.take(10).toList();
  }
}


