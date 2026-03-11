import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/task_model.dart';
import 'package:el_warsha/features/auth/services/auth_service.dart';
import 'package:el_warsha/services/connectivity_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService;

  List<TaskModel> _tasks = [];
  bool _isLoaded = false;
  StreamSubscription? _firestoreSub;
  StreamSubscription? _connectivitySub;

  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  bool get isLoaded => _isLoaded;

  TaskProvider(this._authService) {
    _init();
  }

  // ── Initialization ──────────────────────────────────────────────────────

  void _init() {
    // 1. Load from Hive cache instantly
    _loadFromCache();

    // 2. Start Firestore real-time sync
    _startFirestoreSync();

    // 3. Listen for connectivity to sync pending ops
    _connectivitySub = ConnectivityService.onlineStatus.listen((isOnline) {
      if (isOnline) _syncPendingOps();
    });
  }

  void _loadFromCache() {
    try {
      final box = Hive.box('tasks');
      final cached = box.get('task_list', defaultValue: <dynamic>[]);
      if (cached is List && cached.isNotEmpty) {
        _tasks = cached
            .map((e) => TaskModel.fromMap(
                  Map<String, dynamic>.from(e as Map),
                  e['_id'] ?? '',
                ))
            .toList();
        _isLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading tasks from Hive: $e');
    }
  }

  void _saveToCache() {
    try {
      final box = Hive.box('tasks');
      final data = _tasks.map((t) {
        final map = t.toMap();
        map['_id'] = t.id;
        return map;
      }).toList();
      box.put('task_list', data);
    } catch (e) {
      debugPrint('Error saving tasks to Hive: $e');
    }
  }

  void _startFirestoreSync() {
    final user = _authService.currentUser;
    if (user == null) return;

    _firestoreSub?.cancel();
    _firestoreSub = _db
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) {
        _tasks = snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
            .toList();
        _isLoaded = true;
        _saveToCache();
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Firestore tasks stream error: $e');
        // Keep using cached data on error
      },
    );
  }

  // ── Optimistic CRUD ─────────────────────────────────────────────────────

  Future<String?> addTask(
    String title,
    String description,
    int estimatedMinutes, {
    String category = 'other',
  }) async {
    final user = _authService.currentUser;
    if (user == null) return 'يجب تسجيل الدخول أولاً';

    // Optimistic: create with temp ID and show immediately
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final newTask = TaskModel(
      id: tempId,
      title: title,
      description: description,
      estimatedMinutes: estimatedMinutes,
      category: category,
    );

    _tasks.add(newTask);
    _saveToCache();
    notifyListeners();

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .add(newTask.toMap())
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw 'انتهى الوقت! تأكد من جودة الاتصال',
          );
      // Firestore stream will update _tasks with the real ID automatically
      return null;
    } on FirebaseException catch (e) {
      // Rollback
      _tasks.removeWhere((t) => t.id == tempId);
      _saveToCache();
      notifyListeners();

      if (e.code == 'permission-denied') {
        return 'عذراً! لا يوجد صلاحيات لإضافة المهام.';
      }
      return 'حدث خطأ في قاعدة البيانات: ${e.message}';
    } catch (e) {
      // Rollback
      _tasks.removeWhere((t) => t.id == tempId);
      _saveToCache();
      notifyListeners();
      return 'حدث خطأ غير متوقع: $e';
    }
  }

  Future<void> toggleTaskStatus(TaskModel task) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    final isCompleting = !task.isCompleted;
    final previousTask = _tasks[index];

    // Optimistic: toggle locally first
    _tasks[index] = task.copyWith(
      isCompleted: isCompleting,
      isPointsEarned: (isCompleting && !task.isPointsEarned) ? true : task.isPointsEarned,
    );
    _saveToCache();
    notifyListeners();

    try {
      final batch = _db.batch();
      final taskRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(task.id);
      final userRef = _db.collection('users').doc(user.uid);

      if (isCompleting && !task.isPointsEarned) {
        batch.update(taskRef, {
          'isCompleted': isCompleting,
          'isPointsEarned': true,
        });
        batch.update(userRef, {
          'monthlyPoints': FieldValue.increment(5),
          'totalPoints': FieldValue.increment(5),
          'weeklyFocusPoints': FieldValue.increment(5),
        });
      } else {
        batch.update(taskRef, {'isCompleted': isCompleting});
      }

      await batch.commit();
    } catch (e) {
      // Rollback
      _tasks[index] = previousTask;
      _saveToCache();
      notifyListeners();
      debugPrint('Error toggling task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final removedTask = _tasks[index];

    // Optimistic: remove locally first
    _tasks.removeAt(index);
    _saveToCache();
    notifyListeners();

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      // Rollback
      _tasks.insert(index, removedTask);
      _saveToCache();
      notifyListeners();
      debugPrint('Error deleting task: $e');
    }
  }

  // ── Pending operations sync (for offline adds) ──────────────────────────

  Future<void> _syncPendingOps() async {
    // The Firestore SDK with persistence handles offline ops automatically.
    // This is a placeholder for any custom offline queue logic if needed.
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void dispose() {
    _firestoreSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
