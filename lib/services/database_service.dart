import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/category_data.dart';
import '../models/habit_model.dart';
import '../models/schedule_model.dart';
import '../models/study_room_model.dart';
import '../models/admin_task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── جلب بيانات المستخدم (stream) ──────────────────────────────────────
  Stream<UserModel?> getUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  // ── إنشاء مستند المستخدم عند التسجيل ──────────────────────────────────
  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    final docRef = _db.collection('users').doc(uid);
    try {
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        await docRef.set({
          'uid': uid,
          'name': name,
          'email': email,
          'photoUrl': photoUrl ?? '',
          'inviteCode':
              uid.length >= 6 ? uid.substring(0, 6).toUpperCase() : uid.toUpperCase(),
          'weeklyFocusPoints': 0,
          'totalFocusMinutes': 0,
          'weeklyFocusMinutes': 0,
          'monthlyPoints': 0,
          'focusSessions': [],
          'createdAt': Timestamp.now(),
          'friends': [],
          'friendRequests': [],
          'allTimeBadges': [],
          'bestRank': 0,
          'isAdmin': false,
          'isPremium': false,
          'hasSeenOnboarding': false,
        });
      }
    } catch (e) {
      debugPrint('Error creating user document: $e');
    }
  }

  // ── تحديث بيانات الملف الشخصي (الاسم والصورة) ─────────────────────────
  Future<String?> updateUserProfile({
    required String uid,
    required String name,
    required String photoUrl,
  }) async {
    if (name.trim().isEmpty) return 'الاسم لا يمكن أن يكون فارغاً';

    try {
      await _db.collection('users').doc(uid).update({
        'name': name.trim(),
        'photoUrl': photoUrl.trim(),
      });
      return null; // success
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return 'حدث خطأ أثناء تحديث البيانات.';
    }
  }

  // ── تحديث حالة مشاهدة الشاشة الترحيبية ────────────────────────────
  Future<void> markOnboardingDone(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'hasSeenOnboarding': true,
      });
    } catch (e) {
      debugPrint('Error marking onboarding done: $e');
    }
  }

  // ── عدد المهام المكتملة (stream) ──────────────────────────────────────
  Stream<int> getCompletedTasksCount(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ── إضافة جلسة بومودورو (نقطة + دقيقة) ──────────────────────────────
  Future<void> saveFocusSession(String uid, int duration, String type) async {
    final sessionData = {
      'date': Timestamp.now(),
      'duration': duration,
      'type': type,
    };

    final isFocus = type == 'focus';

    await _db.collection('users').doc(uid).update({
      if (isFocus) 'totalFocusMinutes': FieldValue.increment(duration),
      if (isFocus) 'weeklyFocusMinutes': FieldValue.increment(duration),
      if (isFocus) 'weeklyFocusPoints': FieldValue.increment(duration),
      if (isFocus) 'monthlyPoints': FieldValue.increment(duration),
      if (isFocus) 'totalPoints': FieldValue.increment(duration),
      'focusSessions': FieldValue.arrayUnion([sessionData]),
    });
  }

  // ── قائمة المتصدرين (أصدقاء + المستخدم) ──────────────────────────────
  Stream<List<UserModel>> getLeaderboard(List<String> uids) {
    if (uids.isEmpty) return Stream.value([]);

    final limitedUids = uids.take(10).toList();

    return _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: limitedUids)
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
      users.sort((a, b) => b.weeklyFocusPoints.compareTo(a.weeklyFocusPoints));
      return users;
    });
  }

  Future<bool> isInviteCodeAvailable(String code) async {
    final result = await _db
      .collection('users')
      .where('inviteCode', isEqualTo: code)
      .limit(1)
      .get();
    return result.docs.isEmpty;
  }

  Future<void> updateInviteCode(String userId, String newCode) async {
    await _db
      .collection('users')
      .doc(userId)
      .update({'inviteCode': newCode});
  }

  // ── البحث عن مستخدم بكود الدعوة ───────────────────────────────────────
  Future<UserModel?> searchByInviteCode(String inviteCode) async {
    final trimmed = inviteCode.trim().toUpperCase();
    if (trimmed.isEmpty) return null;

    try {
      final query = await _db
          .collection('users')
          .where('inviteCode', isEqualTo: trimmed)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      final doc = query.docs.first;
      return UserModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      debugPrint('searchByInviteCode error: $e');
      return null;
    }
  }

  // ── جلب كل المستخدمين المشتركين (stream) ──────────────────────────────
  Stream<List<UserModel>> getAllPremiumUsers() {
    return _db
        .collection('users')
        .where('isPremium', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ── تفعيل وإلغاء الاشتراك المميز ──────────────────────────────────────
  Future<void> activatePremium(String uid) async {
    try {
      final endDate = DateTime.now().add(const Duration(days: 30));
      await _db.collection('users').doc(uid).update({
        'isPremium': true,
        'premiumEndDate': Timestamp.fromDate(endDate),
      });
    } catch (e) {
      debugPrint('Error activating premium: $e');
    }
  }

  Future<void> activatePremiumWithDate(String userId, DateTime expiryDate) async {
    try {
      await _db.collection('users').doc(userId).update({
        'isPremium': true,
        'subscriptionStatus': 'active',
        'premiumSince': FieldValue.serverTimestamp(),
        'premiumEndDate': Timestamp.fromDate(expiryDate), // user requested premiumExpiry, but Model uses premiumEndDate
      });
    } catch (e) {
      debugPrint('Error activating premium with date: $e');
    }
  }


  Future<void> deactivatePremium(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'isPremium': false,
        'premiumEndDate': null,
      });
    } catch (e) {
      debugPrint('Error deactivating premium: $e');
    }
  }

  // ── إرسال طلب صداقة ──────────────────────────────────────────────
  Future<String?> sendFriendRequest(String currentUid, String friendUid) async {
    if (currentUid == friendUid) return 'لا يمكنك إرسال طلب لنفسك!';

    try {
      final doc = await _db.collection('users').doc(friendUid).get();
      if (!doc.exists) return 'المستخدم غير موجود.';
      
      final Map<String, dynamic>? data = doc.data();
      final List existingFriends = data?['friends'] ?? [];
      final List existingRequests = data?['friendRequests'] ?? [];

      if (existingFriends.contains(currentUid)) return 'هذا الشخص صديقك بالفعل.';
      if (existingRequests.contains(currentUid)) return 'لقد قمت بإرسال طلب سابقاً.';

      await _db.collection('users').doc(friendUid).update({
        'friendRequests': FieldValue.arrayUnion([currentUid]),
      });

      // إرسال إشعار داخل التطبيق
      final senderDoc = await _db.collection('users').doc(currentUid).get();
      final senderName = senderDoc.data()?['name'] ?? 'مستخدم';
      
      await _db
        .collection('notifications')
        .doc(friendUid)
        .collection('items')
        .add({
          'type': 'friend_request',
          'fromName': senderName,
          'fromId': currentUid,
          'title': '👥 طلب صداقة جديد',
          'body': '$senderName يريد إضافتك كصديق',
          'isRead': false,
          'createdAt': Timestamp.now(),
        });

      return null; // null = success
    } catch (e) {
      return 'حدث خطأ: $e';
    }
  }

  // ── قبول طلب الصداقة ──────────────────────────────────────────────
  Future<void> acceptFriendRequest(String currentUid, String senderUid) async {
    try {
      final batch = _db.batch();
      
      final currentUserRef = _db.collection('users').doc(currentUid);
      final senderUserRef = _db.collection('users').doc(senderUid);

      // إضافة لبعض في قائمة الأصدقاء، وحذف الطلب من الحالي
      batch.update(currentUserRef, {
        'friends': FieldValue.arrayUnion([senderUid]),
        'friendRequests': FieldValue.arrayRemove([senderUid]),
      });

      batch.update(senderUserRef, {
        'friends': FieldValue.arrayUnion([currentUid]),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error accepting request: $e');
    }
  }

  // ── رفض طلب الصداقة ──────────────────────────────────────────────
  Future<void> declineFriendRequest(String currentUid, String senderUid) async {
    try {
      await _db.collection('users').doc(currentUid).update({
        'friendRequests': FieldValue.arrayRemove([senderUid]),
      });
    } catch (e) {
      debugPrint('Error declining request: $e');
    }
  }

  // ── جلب قائمة الطلبات المعلقة ──────────────────────────────────────
  Stream<List<UserModel>> getPendingRequests(String uid) {
    return _db.collection('users').doc(uid).snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists || snapshot.data() == null) return [];
      
      final List<dynamic> requestsIds = snapshot.data()?['friendRequests'] ?? [];
      if (requestsIds.isEmpty) return [];

      final List<UserModel> pendingUsers = [];
      // جلب بيانات كل شخص أرسل طلب
      for (final reqUid in requestsIds) {
        final userDoc = await _db.collection('users').doc(reqUid).get();
        if (userDoc.exists && userDoc.data() != null) {
          pendingUsers.add(UserModel.fromMap(userDoc.data()!, userDoc.id));
        }
      }
      return pendingUsers;
    });
  }

  // ── الفئات المخصصة (Custom Categories) ────────────────────────────────
  Future<void> saveCustomCategory(String uid, TaskCategory category) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(category.id)
          .set(category.toMap());
    } catch (e) {
      debugPrint('Error saving custom category: $e');
      throw e;
    }
  }

  Stream<List<TaskCategory>> getCustomCategories(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('categories')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskCategory.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> deleteCustomCategory(String uid, String categoryId) async {
    try {
      final batch = _db.batch();
      
      final categoryRef = _db
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(categoryId);
      batch.delete(categoryRef);

      final tasksSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .where('category', isEqualTo: categoryId)
          .get();

      for (var doc in tasksSnapshot.docs) {
        batch.update(doc.reference, {'category': 'other'});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting custom category: $e');
      throw e;
    }
  }

  // ── إزالة صديق ────────────────────────────────────────────────────────
  Future<void> removeFriend(String currentUid, String friendUid) async {
    try {
      final batch = _db.batch();
      
      final currentUserRef = _db.collection('users').doc(currentUid);
      final friendUserRef = _db.collection('users').doc(friendUid);

      batch.update(currentUserRef, {
        'friends': FieldValue.arrayRemove([friendUid]),
      });

      batch.update(friendUserRef, {
        'friends': FieldValue.arrayRemove([currentUid]),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error removing friend: $e');
      throw e;
    }
  }

  // ── Leaderboard System ───────────────────────────────────────────
  Stream<List<UserModel>> getTopUsersByField(String field, {int limit = 10}) {
    return _db
        .collection('users')
        .orderBy(field, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .where((u) => field == 'monthlyPoints' ? u.monthlyPoints > 0 : u.totalPoints > 0)
            .toList());
  }

  // Cloud Function Replacement (Mock for client-side testing)
  Future<void> archiveMonth(String monthKey) async {
    try {
      // 1. Get Top 10 users by monthlyPoints (must have > 0)
      final usersSnapshot = await _db
          .collection('users')
          .where('monthlyPoints', isGreaterThan: 0)
          .orderBy('monthlyPoints', descending: true)
          .limit(10)
          .get();

      if (usersSnapshot.docs.isEmpty) return;

      final List<Map<String, dynamic>> topUsers = [];
      int rank = 1;

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final userId = doc.id;
        final monthlyPoints = data['monthlyPoints'] ?? 0;
        final currentBestRank = data['bestRank'] ?? 0;

        List<String> userBadges = List<String>.from(data['allTimeBadges'] ?? []);
        
        // Assign Badges
        final String badgeKey = _getBadgeKeyForRank(rank, monthKey);
        final List<String> currentMonthBadges = [];
        if (badgeKey.isNotEmpty) {
           userBadges.add(badgeKey);
           currentMonthBadges.add(badgeKey);
        }
        
        if (rank <= 10) {
           final top10Badge = 'top10_$monthKey';
           if (badgeKey != top10Badge) {
              userBadges.add(top10Badge);
              currentMonthBadges.add(top10Badge);
           }
        }

        topUsers.add({
          'userId': userId,
          'displayName': data['name'] ?? 'Unknown',
          'avatarUrl': data['photoUrl'] ?? '',
          'totalPoints': monthlyPoints,
          'rank': rank,
          'badges': currentMonthBadges,
        });

        // Update user's best rank and permanent badges
        int newBestRank = currentBestRank == 0 ? rank : (rank < currentBestRank ? rank : currentBestRank);
        await _db.collection('users').doc(userId).update({
          'allTimeBadges': userBadges,
          'bestRank': newBestRank,
        });

        rank++;
      }

      // 2. Save to monthlyLeaderboard
      await _db.collection('monthlyLeaderboard').doc(monthKey).set({
        'month': monthKey,
        'topUsers': topUsers,
        'lastUpdated': Timestamp.now(),
      });

      // 3. Reset ALL users monthlyPoints to 0
      final allUsers = await _db.collection('users').where('monthlyPoints', isGreaterThan: 0).get();
      final batch = _db.batch();
      for (var userDoc in allUsers.docs) {
        batch.update(userDoc.reference, {'monthlyPoints': 0});
      }
      await batch.commit();

    } catch (e) {
      debugPrint('Error archiving month: $e');
    }
  }

  String _getBadgeKeyForRank(int rank, String monthKey) {
    if (rank == 1) return 'gold_$monthKey';
    if (rank == 2) return 'silver_$monthKey';
    if (rank == 3) return 'bronze_$monthKey';
    return '';
  }

  // ── Habits System ────────────────────────────────────────────────────────
  
  Stream<List<HabitModel>> getUserHabits(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('habits')
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => HabitModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addHabit(String userId, HabitModel habit) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habit.id)
          .set(habit.toMap());
    } catch (e) {
      debugPrint('Error adding habit: $e');
      throw e;
    }
  }

  Future<void> deleteHabit(String userId, String habitId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting habit: $e');
      throw e;
    }
  }

  Future<void> checkInHabit(
    String userId, 
    String habitId, 
    String status, // 'clean', 'slip', 'skip'
    String? note,
  ) async {
    try {
      final habitRef = _db.collection('users').doc(userId).collection('habits').doc(habitId);
      final habitDoc = await habitRef.get();
      if (!habitDoc.exists) return;

      final habitData = habitDoc.data()!;
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      
      final logRef = habitRef.collection('logs').doc(todayStr);
      final logDoc = await logRef.get();
      if (logDoc.exists) {
        // Already checked in today. Overwriting logic if needed can be added, but returning for safety
        return; 
      }

      int newCurrentStreak = habitData['currentStreak'] ?? 0;
      int newLongestStreak = habitData['longestStreak'] ?? 0;
      int newTotalCleanDays = habitData['totalCleanDays'] ?? 0;
      int pointsEarned = 0;

      if (status == 'clean') {
        newCurrentStreak++;
        newTotalCleanDays++;
        pointsEarned = 10;
        if (newCurrentStreak > newLongestStreak) {
          newLongestStreak = newCurrentStreak;
        }
      } else if (status == 'slip') {
        newCurrentStreak = 0;
        pointsEarned = 0;
      }

      // Check for Habit milestones (Optionally could be extracted to cloud functions)
      List<String> newBadges = [];
      if (status == 'clean') {
        if (newCurrentStreak == 7) newBadges.add('week_clean_streak');
        if (newCurrentStreak == 30) newBadges.add('month_clean_streak');
        if (newCurrentStreak == 90) newBadges.add('ninety_days_clean_streak');
        // Bonus points for milestones
        if (newCurrentStreak == 7) pointsEarned += 50;
        if (newCurrentStreak == 30) pointsEarned += 200;
        if (newCurrentStreak == 90) pointsEarned += 500;
      }

      final logModel = HabitLogModel(
        date: todayStr,
        status: status,
        note: note,
        pointsEarned: pointsEarned,
      );

      final batch = _db.batch();
      
      // 1. Save Log
      batch.set(logRef, logModel.toMap());
      
      // 2. Update Habit Stats
      batch.update(habitRef, {
        'currentStreak': newCurrentStreak,
        'longestStreak': newLongestStreak,
        'totalCleanDays': newTotalCleanDays,
        'lastCheckIn': Timestamp.now(),
      });
      
      // 3. Update User points and permanent badges
      final userRef = _db.collection('users').doc(userId);
      Map<String, dynamic> userUpdates = {};
      
      if (pointsEarned > 0) {
        userUpdates['monthlyPoints'] = FieldValue.increment(pointsEarned);
        userUpdates['totalPoints'] = FieldValue.increment(pointsEarned);
      }
      if (newBadges.isNotEmpty) {
        userUpdates['allTimeBadges'] = FieldValue.arrayUnion(newBadges);
      }
      
      if (userUpdates.isNotEmpty) {
        batch.update(userRef, userUpdates);
      }

      await batch.commit();

    } catch (e) {
      debugPrint('Error checking in habit: $e');
      throw e;
    }
  }

  Future<List<HabitLogModel>> getHabitLogs(String userId, String habitId, String monthPrefix) async {
    // monthPrefix like '2026-02'
    final logsSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc(habitId)
        .collection('logs')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$monthPrefix-01')
        .where(FieldPath.documentId, isLessThanOrEqualTo: '$monthPrefix-31')
        .get();

    return logsSnapshot.docs.map((doc) => HabitLogModel.fromMap(doc.data())).toList();
  }

  // ── Premium Weekly Schedule System ───────────────────────────────────────

  Future<void> createWeeklySchedule(WeeklyScheduleModel schedule) async {
    try {
      final batch = _db.batch();

      // Deactivate currently active schedules
      final activeDocs = await _db.collection('weeklySchedule').where('isActive', isEqualTo: true).get();
      for (var doc in activeDocs.docs) {
         batch.update(doc.reference, {'isActive': false});
      }
      await batch.commit();

      // Add new schedule
      final Map<String, dynamic> data = schedule.toMap();
      data['id'] = schedule.id; // Also make sure id is inside the document
      await _db.collection('weeklySchedule').add(data);
    } catch (e) {
      debugPrint('Error creating schedule: $e');
      throw e;
    }
  }

  Stream<WeeklyScheduleModel?> getActiveSchedule() {
    return _db
        .collection('weeklySchedule')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return WeeklyScheduleModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    });
  }

  Stream<ScheduleProgressModel?> getUserProgress(String userId, String weekId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('scheduleProgress')
        .doc(weekId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return ScheduleProgressModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  Future<void> lockPreviousDay(String userId, String weekId) async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      final days = [
        'الاثنين', 'الثلاثاء', 'الاربعاء',
        'الخميس', 'الجمعة', 'السبت', 'الاحد'
      ];
      final yesterdayName = days[yesterday.weekday - 1];
      
      final progressRef = _db
        .collection('users')
        .doc(userId)
        .collection('scheduleProgress')
        .doc(weekId);
      
      final doc = await progressRef.get();
      if (!doc.exists) return;
      
      final data = doc.data()!;
      final daysData = Map<String, dynamic>.from(data['days'] ?? {});
      
      if (daysData.containsKey(yesterdayName)) {
        daysData[yesterdayName]['isLocked'] = true;
        daysData[yesterdayName]['lockedAt'] = FieldValue.serverTimestamp();
      } else {
        daysData[yesterdayName] = {
           'isLocked': true,
           'lockedAt': FieldValue.serverTimestamp(),
        };
      }
      
      await progressRef.update({'days': daysData});
    } catch (e) {
      debugPrint('Error locking previous day: $e');
    }
  }

  Future<void> updateDayProgress(
    String userId, 
    String weekId, 
    String dayString, 
    String habitName, 
    dynamic value, 
    int totalHabits,
  ) async {
    try {
       final progressRef = _db.collection('users').doc(userId).collection('scheduleProgress').doc(weekId);
       
       return await _db.runTransaction((transaction) async {
          final snapshot = await transaction.get(progressRef);
          
          Map<String, dynamic> currentDays = {};
          if (snapshot.exists) {
            currentDays = Map<String, dynamic>.from(snapshot.data()!['days'] ?? {});
          }

          // Ensure map for day exists
          if (!currentDays.containsKey(dayString)) {
             currentDays[dayString] = <String, dynamic>{};
          }

          // Update the specific habit
          currentDays[dayString][habitName] = value;

          // Calculate Completion Rate roughly (Total checked booleans + entered numbers > 0)
          int completedHabits = 0;
          currentDays.forEach((day, habitsMap) {
             (habitsMap as Map<String, dynamic>).forEach((hName, hVal) {
                if (hVal is bool && hVal == true) completedHabits++;
                if (hVal is num && hVal > 0) completedHabits++;
             });
          });

          // Possible Total Habits (total days passed * total habits per day) -> Approximate logic for current week. 
          // For simplicity, defining completion rate entirely out of 7 days * totalHabits
          int possibleMax = 7 * totalHabits;
          double newRate = possibleMax > 0 ? (completedHabits / possibleMax) : 0.0;
          
          int addedPoints = 0;
          // E.g., if a user completes a habit, instantly add point, or only apply points locally.
          // For now, let's add 1 point for every completion action.
          if ((value is bool && value) || (value is num && value > 0)) addedPoints = 1;

          final newProgress = ScheduleProgressModel(
            weekId: weekId,
            userId: userId,
            days: currentDays,
            completionRate: newRate,
            totalPoints: (snapshot.exists ? (snapshot.data()!['totalPoints'] ?? 0) : 0) + addedPoints,
            lastUpdated: Timestamp.now(),
          );

          transaction.set(progressRef, newProgress.toMap(), SetOptions(merge: true));
          
          // Increment global points
          if (addedPoints > 0) {
             transaction.update(_db.collection('users').doc(userId), {
                'monthlyPoints': FieldValue.increment(addedPoints),
                'totalPoints': FieldValue.increment(addedPoints)
             });
          }
       });

    } catch (e) {
      debugPrint('Error updating day progress: $e');
      throw e;
    }
  }

  Future<List<Map>> getPremiumUsersProgress(String weekId) async {
    // أولاً جيب كل المشتركين
    final premiumUsers = await _db
      .collection('users')
      .where('isPremium', isEqualTo: true)
      .get();
    
    List<Map> result = [];
    
    // لكل مشترك جيب الـ progress بتاعه
    for (var doc in premiumUsers.docs) {
      final userId = doc.id;
      final userName = doc.data()['name'] ?? '';
      final photoUrl = doc.data()['photoUrl'] ?? '';
      final email = doc.data()['email'] ?? '';
      final inviteCode = doc.data()['inviteCode'] ?? '';
      final premiumEndDate = doc.data()['premiumEndDate'];
      
      final progressDoc = await _db
        .collection('users')
        .doc(userId)
        .collection('scheduleProgress')
        .doc(weekId)
        .get();
      
      double completionRate = 0;
      if (progressDoc.exists) {
        completionRate = progressDoc.data()?['completionRate'] ?? 0.0;
      }
      
      result.add({
        'userId': userId,
        'name': userName,
        'photoUrl': photoUrl,
        'email': email,
        'inviteCode': inviteCode,
        'premiumEndDate': premiumEndDate,
        'isPremium': true, // Because we filtered by isPremium: true
        'completionRate': completionRate,
        'progress': progressDoc.data()?['days'] ?? {},
      });
    }
    
    // رتبهم بالنسبة تنازلياً
    result.sort((a, b) => 
      (b['completionRate'] as double)
      .compareTo(a['completionRate'] as double));
    
    return result;
  }

  Future<List<Map<String, dynamic>>> getWeeklyLeaderboard(String weekId) async {
     try {
       final premiumProgress = await getPremiumUsersProgress(weekId);
       
       // getPremiumUsersProgress returns sorted results, so just cast to the exact type
       List<Map<String, dynamic>> rankings = premiumProgress.map((e) => Map<String, dynamic>.from(e)).toList();
       
       // Return Top 10
       return rankings.take(10).toList();
       
      } catch (e) {
        debugPrint('Error fetching weekly leaderboard: $e');
        return [];
     }
  }

  Future<List<Map>> getUserWeeksArchive(String userId) async {
    final progressDocs = await _db
      .collection('users')
      .doc(userId)
      .collection('scheduleProgress')
      .orderBy('lastUpdated', descending: true)
      .get();
    
    List<Map> archive = [];
    
    for (var doc in progressDocs.docs) {
      final data = doc.data();
      
      final scheduleDoc = await _db
        .collection('weeklySchedule')
        .doc(doc.id)
        .get();
      
      if (scheduleDoc.exists) {
        archive.add({
          'weekId': doc.id,
          'month': scheduleDoc.data()?['month'],
          'weekNumber': scheduleDoc.data()?['weekNumber'],
          'completionRate': data['completionRate'] != null ? data['completionRate'] * 100 : 0.0,
          'days': data['days'] ?? {},
          'createdAt': data['lastUpdated'],
        });
      }
    }
    
    return archive;
  }

  // ── الإشعارات (Notifications) ──────────────────────────────────────
  Stream<List<Map<String, dynamic>>> getUserNotifications(String uid) {
    return _db
      .collection('notifications')
      .doc(uid)
      .collection('items')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList());
  }

  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    try {
      await _db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(notificationId)
        .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  Future<void> sendNotificationToAll(String title, String body, String targetGroup) async {
    try {
      Query<Map<String, dynamic>> query = _db.collection('users');
      
      if (targetGroup == 'المشتركين فقط') {
        query = query.where('isPremium', isEqualTo: true);
      } else if (targetGroup == 'غير المشتركين') {
        query = query.where('isPremium', isEqualTo: false);
      }

      final snapshot = await query.get();
      
      // We will loop and add to each user's notifications collection
      final batch = _db.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        final userId = doc.id;
        final notifRef = _db.collection('notifications').doc(userId).collection('items').doc();
        batch.set(notifRef, {
          'type': 'broadcast',
          'title': title,
          'body': body,
          'isRead': false,
          'createdAt': Timestamp.now(),
        });
        
        count++;
        // Commit in chunks of 500 if the app scales (Firestore limit)
        if (count % 450 == 0) {
           await batch.commit();
        }
      }
      
      if (count % 450 != 0) {
        await batch.commit();
      }
      
    } catch (e) {
      debugPrint('Error sending broadcast: $e');
    }
  }

  // ── Study Room Methods ──────────────────────────────────────────

  Future<String> createStudyRoom(String userId, String userName) async {
    final random = Random();
    final String roomCode = (1000 + random.nextInt(9000)).toString(); // 4 digits
    
    final member = StudyRoomMemberModel(
      userId: userId,
      name: userName,
      joinedAt: Timestamp.now(),
      isReady: true, // host is ready by default
    );

    final roomData = {
      'hostId': userId,
      'hostName': userName,
      'roomCode': roomCode,
      'status': 'waiting',
      'sessionType': 'focus',
      'timerDuration': 1500, // 25 mins
      'timerStartedAt': null,
      'members': [member.toMap()],
      'maxMembers': 2,
      'createdAt': Timestamp.now(),
    };

    final docRef = _db.collection('studyRooms').doc();
    await docRef.set(roomData);
    
    return roomCode;
  }

  Future<bool> joinStudyRoom(String roomCode, String userId, String userName) async {
    try {
      final query = await _db.collection('studyRooms').where('roomCode', isEqualTo: roomCode).limit(1).get();
      if (query.docs.isEmpty) return false;
      
      final doc = query.docs.first;
      final room = StudyRoomModel.fromMap(doc.data(), doc.id);
      
      if (room.members.length >= room.maxMembers) return false;
      if (room.members.any((m) => m.userId == userId)) return true;

      final newMember = StudyRoomMemberModel(
        userId: userId,
        name: userName,
        joinedAt: Timestamp.now(),
        isReady: false,
      );

      await doc.reference.update({
        'members': FieldValue.arrayUnion([newMember.toMap()])
      });
      return true;
    } catch (e) {
      debugPrint('Error joining room: $e');
      return false;
    }
  }

  Stream<StudyRoomModel?> getStudyRoom(String roomCode) {
    return _db.collection('studyRooms').where('roomCode', isEqualTo: roomCode).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return StudyRoomModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }

  Future<void> startTimer(String roomCode, int durationSeconds, String type) async {
    final query = await _db.collection('studyRooms').where('roomCode', isEqualTo: roomCode).limit(1).get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        'status': 'studying',
        'timerStartedAt': Timestamp.now(),
      });
    }
  }

  Future<void> updateRoomSettings(String roomCode, int durationSeconds, String type) async {
    final query = await _db.collection('studyRooms').where('roomCode', isEqualTo: roomCode).limit(1).get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        'timerDuration': durationSeconds,
        'sessionType': type,
      });
    }
  }

  Future<void> endSession(String roomCode) async {
    final query = await _db.collection('studyRooms').where('roomCode', isEqualTo: roomCode).limit(1).get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        'status': 'ended',
      });
      
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          final check = await query.docs.first.reference.get();
          if (check.exists) {
            await query.docs.first.reference.delete();
          }
        } catch (_) {}
      });
    }
  }

  Future<void> resetSession(String roomCode) async {
    final query = await _db.collection('studyRooms').where('roomCode', isEqualTo: roomCode).limit(1).get();
    if (query.docs.isNotEmpty) {
      final docRef = query.docs.first.reference;
      final room = StudyRoomModel.fromMap(query.docs.first.data(), query.docs.first.id);
      
      // Reset ready status of all non-host members
      List<Map<String, dynamic>> updatedMembers = room.members.map((m) {
        return StudyRoomMemberModel(
          userId: m.userId,
          name: m.name,
          joinedAt: m.joinedAt,
          isReady: m.userId == room.hostId, // Host is always ready
        ).toMap();
      }).toList();

      await docRef.update({
        'status': 'waiting',
        'timerStartedAt': null,
        'members': updatedMembers,
      });
    }
  }

  Future<void> leaveRoom(String roomCode, String userId) async {
    final query = await _db.collection('studyRooms').where('roomCode', isEqualTo: roomCode).limit(1).get();
    if (query.docs.isEmpty) return;
    
    final docRefs = query.docs.first;
    final room = StudyRoomModel.fromMap(docRefs.data(), docRefs.id);
    
    final updatedMembers = room.members.where((m) => m.userId != userId).toList();
    
    if (updatedMembers.isEmpty || room.hostId == userId) {
      await docRefs.reference.delete();
    } else {
      await docRefs.reference.update({
        'members': updatedMembers.map((m) => m.toMap()).toList()
      });
    }
  }

  Future<void> toggleMemberReadyStatus(String roomCode, String userId) async {
    final query = await _db.collection('studyRooms').where('roomCode', isEqualTo: roomCode).limit(1).get();
    if (query.docs.isEmpty) return;
    
    final docRef = query.docs.first.reference;
    final room = StudyRoomModel.fromMap(query.docs.first.data(), query.docs.first.id);
    
    List<Map<String, dynamic>> updatedMembers = room.members.map((m) {
      if (m.userId == userId) {
        return StudyRoomMemberModel(
          userId: m.userId,
          name: m.name,
          joinedAt: m.joinedAt,
          isReady: !m.isReady,
        ).toMap();
      }
      return m.toMap();
    }).toList();

    await docRef.update({'members': updatedMembers});
  }

  // ── Admin Tasks Feature ───────────────────────────────────────────

  /// Adds a new Admin Task to Firestore
  Future<void> addAdminTask({
    required String title,
    String? description,
    required dynamic assignedTo, // 'all' or List<userId>
    required String currentUserId,
    DateTime? dueDate,
    int points = 10,
  }) async {
    try {
      await _db.collection('adminTasks').add({
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
        'points': points,
        'isActive': true,
      });
    } catch (e) {
      debugPrint('Error adding admin task: $e');
    }
  }

  /// Streams active Admin Tasks applicable to the given user
  Stream<List<AdminTask>> getAdminTasksForUser(String userId) {
    return _db
        .collection('adminTasks')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AdminTask.fromMap(d.data(), d.id)).where((task) {
              return task.assignedTo == 'all' ||
                  (task.assignedTo is List &&
                      (task.assignedTo as List).contains(userId));
            }).toList());
  }

  /// Streams the IDs of all Admin Tasks completed by the user
  Stream<List<String>> getCompletedAdminTasks(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('completedAdminTasks')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toList());
  }

  /// Marks an Admin Task as completed and awards points to the user
  Future<void> completeAdminTask(String userId, AdminTask task) async {
    try {
      final batch = _db.batch();

      // Record completion
      final completionRef = _db
          .collection('users')
          .doc(userId)
          .collection('completedAdminTasks')
          .doc(task.id);
      batch.set(completionRef, {'completedAt': FieldValue.serverTimestamp()});

      // Award points
      final userRef = _db.collection('users').doc(userId);
      batch.update(userRef, {
        'monthlyPoints': FieldValue.increment(task.points),
        'totalPoints': FieldValue.increment(task.points),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error completing admin task: $e');
    }
  }
}
