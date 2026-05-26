import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../utils/constants.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatMessageModel> _messages = [];
  bool _isSending = false;
  bool _isCleaning = false;
  String? _error;
  int? _cooldownSecondsRemaining;

  StreamSubscription<List<ChatMessageModel>>? _chatSubscription;
  Timer? _cooldownTimer;

  List<ChatMessageModel> get messages => _messages;
  bool get isSending => _isSending;
  String? get error => _error;
  int? get cooldownSecondsRemaining => _cooldownSecondsRemaining;
  bool get canSend =>
      (_cooldownSecondsRemaining ?? 0) <= 0 && !_isSending;

  void initialize(String userId) {
    _chatSubscription?.cancel();
    _chatSubscription = _chatService.getGlobalChatStream().listen(
      (messages) {
        _messages = messages;
        notifyListeners();
      },
      onError: (err) {
        _error = err.toString();
        notifyListeners();
      },
    );

    _runCleanup();
    _refreshCooldown(userId);
  }

  Future<void> _runCleanup() async {
    if (_isCleaning) return;
    _isCleaning = true;
    try {
      await _chatService.cleanupExpiredMessages();
    } catch (e) {
      debugPrint('Chat cleanup: $e');
    } finally {
      _isCleaning = false;
    }
  }

  Future<void> _refreshCooldown(String userId) async {
    _cooldownTimer?.cancel();
    final lastMs = await _chatService.getLastMessageTimestampMs(userId);
    if (lastMs == null) {
      _cooldownSecondsRemaining = 0;
      notifyListeners();
      return;
    }

    final elapsed =
        ((DateTime.now().millisecondsSinceEpoch - lastMs) / 1000).floor();
    final remaining = AppConstants.chatCooldownSeconds - elapsed;

    if (remaining <= 0) {
      _cooldownSecondsRemaining = 0;
      notifyListeners();
      return;
    }

    _cooldownSecondsRemaining = remaining;
    notifyListeners();

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if ((_cooldownSecondsRemaining ?? 0) <= 1) {
        _cooldownSecondsRemaining = 0;
        _cooldownTimer?.cancel();
      } else {
        _cooldownSecondsRemaining = (_cooldownSecondsRemaining ?? 1) - 1;
      }
      notifyListeners();
    });
  }

  Future<bool> sendMessage({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String text,
  }) async {
    _error = null;
    _isSending = true;
    notifyListeners();

    try {
      await _chatService.sendMessage(
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        text: text,
      );
      await _refreshCooldown(userId);
      _isSending = false;
      notifyListeners();
      return true;
    } on ChatRateLimitException catch (e) {
      _error = e.toString();
      _cooldownSecondsRemaining = e.secondsRemaining;
      _isSending = false;
      notifyListeners();
      _refreshCooldown(userId);
      return false;
    } on ChatWordLimitException catch (e) {
      _error = e.toString();
      _isSending = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  static int wordCount(String text) => ChatService.countWords(text);

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
