import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';
import '../utils/constants.dart';

class ChatRateLimitException implements Exception {
  final int secondsRemaining;
  ChatRateLimitException(this.secondsRemaining);

  @override
  String toString() =>
      'Debes esperar $secondsRemaining segundos antes de enviar otro mensaje.';
}

class ChatWordLimitException implements Exception {
  final int wordCount;
  ChatWordLimitException(this.wordCount);

  @override
  String toString() =>
      'El mensaje tiene $wordCount palabras. Máximo ${AppConstants.chatMaxWordsPerMessage}.';
}

class ChatService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Uuid _uuid = const Uuid();

  static int countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  Stream<List<ChatMessageModel>> getGlobalChatStream() {
    return _database.child(AppConstants.globalChatPath).onValue.map((event) {
      final messages = <ChatMessageModel>[];

      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        data.forEach((key, value) {
          messages.add(ChatMessageModel.fromMap(
            Map<String, dynamic>.from(value as Map),
            key,
          ));
        });
      }

      messages.sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
      return messages;
    });
  }

  Future<int?> getLastMessageTimestampMs(String userId) async {
    final snapshot = await _database
        .child(AppConstants.usersPath)
        .child(userId)
        .child('lastChatMessageAt')
        .get();

    if (!snapshot.exists) return null;
    return (snapshot.value as num).toInt();
  }

  Future<void> sendMessage({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw 'El mensaje no puede estar vacío.';
    }

    final wordCount = countWords(trimmed);
    if (wordCount > AppConstants.chatMaxWordsPerMessage) {
      throw ChatWordLimitException(wordCount);
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastMs = await getLastMessageTimestampMs(userId);

    if (lastMs != null) {
      final elapsedSec = ((nowMs - lastMs) / 1000).floor();
      if (elapsedSec < AppConstants.chatCooldownSeconds) {
        throw ChatRateLimitException(
          AppConstants.chatCooldownSeconds - elapsedSec,
        );
      }
    }

    final messageId = _uuid.v4();
    final message = ChatMessageModel(
      id: messageId,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      text: trimmed,
      createdAtMs: nowMs,
    );

    final updates = <String, dynamic>{
      '${AppConstants.globalChatPath}/$messageId': message.toMap(),
      '${AppConstants.usersPath}/$userId/lastChatMessageAt': nowMs,
    };

    await _database.update(updates);
  }

  Future<void> cleanupExpiredMessages() async {
    final cutoffMs = DateTime.now()
        .subtract(const Duration(hours: AppConstants.chatRetentionHours))
        .millisecondsSinceEpoch;

    final metaRef =
        _database.child(AppConstants.globalChatMetaPath).child('lastCleanupAtMs');

    final metaSnap = await metaRef.get();
    if (metaSnap.exists) {
      final lastCleanup = (metaSnap.value as num).toInt();
      if (DateTime.now().millisecondsSinceEpoch - lastCleanup <
          const Duration(hours: 1).inMilliseconds) {
        return;
      }
    }

    final snapshot = await _database
        .child(AppConstants.globalChatPath)
        .orderByChild('createdAtMs')
        .endAt(cutoffMs)
        .get();

    if (!snapshot.exists || snapshot.value == null) {
      await metaRef.set(DateTime.now().millisecondsSinceEpoch);
      return;
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final removals = <String, dynamic>{};

    for (final key in data.keys) {
      removals['${AppConstants.globalChatPath}/$key'] = null;
    }

    if (removals.isNotEmpty) {
      await _database.update(removals);
    }

    await metaRef.set(DateTime.now().millisecondsSinceEpoch);
  }
}
