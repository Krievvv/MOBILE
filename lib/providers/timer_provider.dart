import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/book.dart';
import '../services/reading_session_service.dart';

class TimerProvider with ChangeNotifier {
  Timer? _timer;
  int _totalSeconds = 1800; // Default 30 minutes
  int _remainingSeconds = 1800;
  bool _isRunning = false;
  bool _isPaused = false;
  Book? _currentBook;
  DateTime? _startTime;
  DateTime? _pauseTime;

  // Getters
  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  Book? get currentBook => _currentBook;
  double get progress {
    if (_totalSeconds == 0) return 0.0;
    return (_totalSeconds - _remainingSeconds) / _totalSeconds;
  }

  // Set duration
  void setDuration(int seconds) {
    if (_isRunning) return; // Don't change duration while running
    
    _totalSeconds = seconds;
    _remainingSeconds = seconds;
    notifyListeners();
  }

  // Set current book
  void setCurrentBook(Book? book) {
    _currentBook = book;
    notifyListeners();
  }

  // Start timer
  void startTimer() {
    if (_remainingSeconds <= 0) return;
    
    _isRunning = true;
    _isPaused = false;
    _startTime = DateTime.now();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completeSession();
      }
    });
    
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  // Pause timer
  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = true;
    _pauseTime = DateTime.now();
    
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  // Resume timer
  void resumeTimer() {
    startTimer();
  }

  // Stop timer
  void stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _remainingSeconds = _totalSeconds;
    _startTime = null;
    _pauseTime = null;
    
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  // Reset timer
  void resetTimer() {
    _remainingSeconds = _totalSeconds;
    _isRunning = false;
    _isPaused = false;
    _startTime = null;
    _pauseTime = null;
    notifyListeners();
  }

  // Complete session
  void _completeSession() async {
    print('=== TIMER COMPLETION STARTED ===');
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    
    print('Current book: ${_currentBook?.title}');
    print('Duration: $_totalSeconds seconds');
    
    // Save reading session
    if (_currentBook != null) {
      try {
        print('Attempting to save reading session...');
        await ReadingSessionService.saveSession(
          bookId: _currentBook!.id,
          duration: _totalSeconds,
          completedAt: DateTime.now(),
        );
        print('✅ Reading session saved successfully for book: ${_currentBook!.title}');
      } catch (e) {
        print('❌ Error saving reading session: $e');
        // Still notify completion even if save fails
      }
    } else {
      print('⚠️ No current book selected, session not saved');
    }
    
    HapticFeedback.heavyImpact();
    notifyListeners();
    
    print('=== TIMER COMPLETION FINISHED ===');
    
    // Notify completion (listeners can handle UI)
    _onSessionCompleted?.call();
  }

  // Callback for session completion
  VoidCallback? _onSessionCompleted;
  void setOnSessionCompleted(VoidCallback? callback) {
    _onSessionCompleted = callback;
  }

  // Format duration
  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  // Get remaining time as string
  String get remainingTimeString => formatDuration(_remainingSeconds);

  // Get elapsed time
  int get elapsedSeconds => _totalSeconds - _remainingSeconds;
  String get elapsedTimeString => formatDuration(elapsedSeconds);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
