import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

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
          'createdAt': DateTime.now(),
          'friends': [],
          'friendRequests': [],
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
  Future<void> addFocusSession(String uid, {int minutesAdded = 25}) async {
    await _db.collection('users').doc(uid).update({
      'weeklyFocusPoints': FieldValue.increment(minutesAdded),
      'totalFocusMinutes': FieldValue.increment(minutesAdded),
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
}
