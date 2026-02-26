import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class PomodoroProvider extends ChangeNotifier {
  final AuthService _authService;
  final DatabaseService _dbService = DatabaseService();

  static const int _pomodoroDuration = 25 * 60; // 25 minutes in seconds
  int _remainingSeconds = _pomodoroDuration;
  bool _isRunning = false;
  Timer? _timer;

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;

  String get timeDisplay {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progress => _remainingSeconds / _pomodoroDuration;

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
        _onPomodoroComplete();
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
    _remainingSeconds = _pomodoroDuration;
    _isRunning = false;
    notifyListeners();
  }

  Future<void> _onPomodoroComplete() async {
    final user = _authService.currentUser;
    if (user != null) {
      // Adds 1 point AND 25 minutes to Firestore atomically
      await _dbService.addFocusSession(user.uid, minutesAdded: 25);
    }

    // Reset timer for next session
    _remainingSeconds = _pomodoroDuration;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
