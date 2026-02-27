import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

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

  PomodoroProvider(this._authService);

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
      await _dbService.saveFocusSession(user.uid, minutes, type);
    }

    // Reset timer to original duration
    _remainingSeconds = _currentDuration;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
