import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import 'package:el_warsha/features/auth/services/auth_service.dart';

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
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<String?> addTask(String title, String description, int estimatedMinutes, {String category = 'other'}) async {
    final user = _authService.currentUser;
    if (user == null) return 'يجب تسجيل الدخول أولاً';

    final newTask = TaskModel(
      id: '',
      title: title,
      description: description,
      estimatedMinutes: estimatedMinutes,
      category: category,
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

    // الأمان لعدم هبوط النقاط تحت الصفر (حسب طلب المستخدم الجديد: إضافة النقاط مرة واحدة وعدم خصمها)
    // الآن نستخدم isPointsEarned لمنع تكرار النقاط عند إلغاء وإعادة التحديد
    if (isCompleting && !task.isPointsEarned) {
      batch.update(taskRef, {
        'isCompleted': isCompleting,
        'isPointsEarned': true, // علامة إن المهمة دي أخدت نقاطها خلاص
      });
      
      batch.update(userRef, {
        'monthlyPoints': FieldValue.increment(5),
        'totalPoints': FieldValue.increment(5),
        // Keep weeklyFocusPoints increment for backward compatibility if used elsewhere, but mainly use the new split points for tasks
        'weeklyFocusPoints': FieldValue.increment(5) 
      });
    } else {
      // إما بنلغي صح (uncomplete) أو المهمة أصلاً متأخد نقاطها قبل كده
      batch.update(taskRef, {'isCompleted': isCompleting});
    }
    
    // ⚠️ لا يتم خصم النقاط أبداً إذا تم إرجاع المهمة (uncomplete)
    // النقاط محفوظة دائماً بمجرد إكمال المهمة لأول مرة وتسجيل isPointsEarned

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
