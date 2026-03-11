import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/habit_model.dart';
import 'package:el_warsha/features/auth/services/auth_service.dart';
import 'package:el_warsha/services/database_service.dart';
import 'package:el_warsha/services/connectivity_service.dart';

class HabitProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService;

  List<HabitModel> _habits = [];
  bool _isLoaded = false;
  StreamSubscription? _firestoreSub;
  StreamSubscription? _connectivitySub;

  List<HabitModel> get habits => List.unmodifiable(_habits);
  bool get isLoaded => _isLoaded;

  HabitProvider(this._authService) {
    _init();
  }

  // ── Initialization ──────────────────────────────────────────────────────

  void _init() {
    _loadFromCache();
    _startFirestoreSync();

    _connectivitySub = ConnectivityService.onlineStatus.listen((isOnline) {
      if (isOnline) _syncPendingOps();
    });
  }

  void _loadFromCache() {
    try {
      final box = Hive.box('habits');
      final cached = box.get('habit_list', defaultValue: <dynamic>[]);
      if (cached is List && cached.isNotEmpty) {
        _habits = cached.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          // Reconstruct Timestamp from milliseconds stored in Hive
          if (map['startDate'] is int) {
            map['startDate'] = Timestamp.fromMillisecondsSinceEpoch(map['startDate']);
          }
          if (map['lastCheckIn'] is int) {
            map['lastCheckIn'] = Timestamp.fromMillisecondsSinceEpoch(map['lastCheckIn']);
          }
          return HabitModel.fromMap(map, map['_id'] ?? '');
        }).toList();
        _isLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading habits from Hive: $e');
    }
  }

  void _saveToCache() {
    try {
      final box = Hive.box('habits');
      final data = _habits.map((h) {
        final map = h.toMap();
        map['_id'] = h.id;
        // Convert Timestamps to milliseconds for Hive compatibility
        if (map['startDate'] is Timestamp) {
          map['startDate'] = (map['startDate'] as Timestamp).millisecondsSinceEpoch;
        }
        if (map['lastCheckIn'] is Timestamp) {
          map['lastCheckIn'] = (map['lastCheckIn'] as Timestamp).millisecondsSinceEpoch;
        }
        return map;
      }).toList();
      box.put('habit_list', data);
    } catch (e) {
      debugPrint('Error saving habits to Hive: $e');
    }
  }

  void _startFirestoreSync() {
    final user = _authService.currentUser;
    if (user == null) return;

    _firestoreSub?.cancel();
    _firestoreSub = _db
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) {
        _habits = snapshot.docs
            .map((doc) => HabitModel.fromMap(doc.data(), doc.id))
            .toList();
        _isLoaded = true;
        _saveToCache();
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Firestore habits stream error: $e');
      },
    );
  }

  // ── Optimistic CRUD ─────────────────────────────────────────────────────

  Future<void> addHabit(HabitModel habit) async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Optimistic: show immediately
    _habits.add(habit);
    _saveToCache();
    notifyListeners();

    try {
      await _dbService.addHabit(user.uid, habit);
    } catch (e) {
      // Rollback
      _habits.removeWhere((h) => h.id == habit.id);
      _saveToCache();
      notifyListeners();
      debugPrint('Error adding habit: $e');
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final removedHabit = _habits[index];

    // Optimistic: remove immediately
    _habits.removeAt(index);
    _saveToCache();
    notifyListeners();

    try {
      await _dbService.deleteHabit(user.uid, habitId);
    } catch (e) {
      // Rollback
      _habits.insert(index, removedHabit);
      _saveToCache();
      notifyListeners();
      debugPrint('Error deleting habit: $e');
    }
  }

  Future<void> checkInHabit(String habitId, String status, String? note) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final previousHabit = _habits[index];
    final habit = _habits[index];

    // Optimistic: compute new streak values locally
    int newCurrentStreak = habit.currentStreak;
    int newLongestStreak = habit.longestStreak;
    int newTotalCleanDays = habit.totalCleanDays;

    if (status == 'clean') {
      newCurrentStreak++;
      newTotalCleanDays++;
      if (newCurrentStreak > newLongestStreak) {
        newLongestStreak = newCurrentStreak;
      }
    } else if (status == 'slip') {
      newCurrentStreak = 0;
    }

    // Create optimistic updated model
    _habits[index] = HabitModel(
      id: habit.id,
      name: habit.name,
      type: habit.type,
      category: habit.category,
      icon: habit.icon,
      color: habit.color,
      targetDays: habit.targetDays,
      startDate: habit.startDate,
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      totalCleanDays: newTotalCleanDays,
      lastCheckIn: Timestamp.now(),
      isActive: habit.isActive,
    );
    _saveToCache();
    notifyListeners();

    try {
      await _dbService.checkInHabit(user.uid, habitId, status, note);
    } catch (e) {
      // Rollback
      _habits[index] = previousHabit;
      _saveToCache();
      notifyListeners();
      debugPrint('Error checking in habit: $e');
    }
  }

  // ── Pending operations sync ─────────────────────────────────────────────

  Future<void> _syncPendingOps() async {
    // Firestore with persistence handles offline ops automatically
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void dispose() {
    _firestoreSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
