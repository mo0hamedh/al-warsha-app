import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/auth_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService;

  TaskProvider(this._authService);

  Stream<List<TaskModel>> get tasksStream {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<String?> addTask(String title, String description, int estimatedMinutes) async {
    final user = _authService.currentUser;
    if (user == null) return 'يجب تسجيل الدخول أولاً';

    final newTask = TaskModel(
      id: '',
      title: title,
      description: description,
      estimatedMinutes: estimatedMinutes,
    );

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .add(newTask.toMap())
          .timeout(const Duration(seconds: 5), onTimeout: () => throw 'انتهى الوقت (Timeout)! تأكد من صلاحيات قاعدة البيانات (Firestore Rules) أو جودة الاتصال');
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'عذراً! لا يوجد صلاحيات لإضافة المهام (Firebase Rules).';
      }
      return 'حدث خطأ في قاعدة البيانات: ${e.message}';
    } catch (e) {
      return 'حدث خطأ غير متوقع: $e';
    }
  }

  Future<void> toggleTaskStatus(TaskModel task) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final isCompleting = !task.isCompleted;
    final batch = _db.batch();

    final taskRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(task.id);
        
    final userRef = _db.collection('users').doc(user.uid);

    batch.update(taskRef, {'isCompleted': isCompleting});
    
    // إضافة أو خصم النقطة
    batch.update(userRef, {
      'weeklyFocusPoints': FieldValue.increment(isCompleting ? 1 : -1)
    });

    await batch.commit();
  }

  Future<void> deleteTask(String taskId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }
}
