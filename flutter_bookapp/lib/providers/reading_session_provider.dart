import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/book_model.dart';

class ReadingSessionProvider with ChangeNotifier {
  BookModel? _activeBook;
  Duration? _totalDuration;
  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool _isActive = false;
  bool _completedWithPoints = false;

  BookModel? get activeBook => _activeBook;
  bool get isActive => _isActive;
  Duration get remaining => _remaining;
  Duration? get totalDuration => _totalDuration;
  bool get completedWithPoints => _completedWithPoints;

  String get formattedRemaining {
    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = _remaining.inHours;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void startSession(BookModel book, Duration duration) {
    _timer?.cancel();
    _activeBook = book;
    _totalDuration = duration;
    _remaining = duration;
    _isActive = true;
    _completedWithPoints = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 1) {
        _endSession(awardPoints: false);
      } else {
        _remaining -= const Duration(seconds: 1);
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Completa la sesión antes de que termine el tiempo (+10 puntos).
  bool completeEarly() {
    if (!_isActive || _activeBook == null) return false;
    _completedWithPoints = true;
    _endSession(awardPoints: true);
    return true;
  }

  void cancelSession() {
    if (!_isActive) return;
    _endSession(awardPoints: false);
  }

  void _endSession({required bool awardPoints}) {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    if (!awardPoints) {
      _completedWithPoints = false;
    }
    notifyListeners();
  }

  void clearCompletedFlag() {
    _completedWithPoints = false;
    _activeBook = null;
    _totalDuration = null;
    _remaining = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
