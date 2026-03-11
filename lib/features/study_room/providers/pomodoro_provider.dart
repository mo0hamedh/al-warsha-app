import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:el_warsha/features/auth/services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../services/connectivity_service.dart';

class PomodoroProvider extends ChangeNotifier {
  final AuthService _authService;
  final DatabaseService _dbService = DatabaseService();

  int _currentDuration = 25 * 60; // default 25 minutes
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isRestMode = false;
  Timer? _timer;

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isRestMode => _isRestMode;
  int get currentDuration => _currentDuration;

  String get timeDisplay {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progress => _remainingSeconds / _currentDuration;

  StreamSubscription? _connectivitySubscription;

  PomodoroProvider(this._authService) {
    _connectivitySubscription = ConnectivityService.onlineStatus.listen((isOnline) {
      if (isOnline) {
        _syncPendingSessions();
      }
    });
  }

  void startTimer() {
    if (_isRunning) return;
    
    _isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _isRunning = false;
        _onSessionComplete();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _remainingSeconds = _currentDuration;
    _isRunning = false;
    notifyListeners();
  }

  void setSession(int minutes, {required bool isRest}) {
    _timer?.cancel();
    _isRestMode = isRest;
    _currentDuration = minutes * 60;
    _remainingSeconds = _currentDuration;
    _isRunning = false;
    notifyListeners();
  }

  Future<void> _onSessionComplete() async {
    final user = _authService.currentUser;
    if (user != null) {
      final minutes = (_currentDuration / 60).round();
      final type = _isRestMode ? 'break' : 'focus';
      
      final session = {
        'date': DateTime.now().toIso8601String(),
        'uid': user.uid,
        'duration': minutes,
        'type': type,
        'synced': false,
      };

      // احفظ محلياً دائماً
      final box = Hive.box('settings');
      final pending = List<Map<dynamic, dynamic>>.from(box.get('pending_sessions', defaultValue: []));
      pending.add(session);
      await box.put('pending_sessions', pending);

      // لو المتصل ارفع فوراً
      if (await ConnectivityService.isOnline()) {
        await _syncPendingSessions();
      }
    }

    // Reset timer to original duration
    _remainingSeconds = _currentDuration;
    notifyListeners();
  }

  Future<void> _syncPendingSessions() async {
    final box = Hive.box('settings');
    final pending = List<Map<dynamic, dynamic>>.from(box.get('pending_sessions', defaultValue: []));
    bool hasChanges = false;

    for (var i = 0; i < pending.length; i++) {
      var session = pending[i];
      if (session['synced'] == false) {
        try {
          // This requires DatabaseService to accept the uid parameter. Since earlier signatures did:
          await _dbService.saveFocusSession(session['uid'], session['duration'], session['type']);
          session['synced'] = true;
          hasChanges = true;
        } catch(e) {
          debugPrint('Error syncing session: $e');
        }
      }
    }

    if (hasChanges) {
      // Remove synced items from local or just keep them synced (we'll cleanly remove to save space)
      final remaining = pending.where((s) => s['synced'] == false).toList();
      await box.put('pending_sessions', remaining);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
