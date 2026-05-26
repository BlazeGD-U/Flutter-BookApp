class ChatMessageModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String text;
  final int createdAtMs;

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.text,
    required this.createdAtMs,
  });

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMs);

  factory ChatMessageModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return ChatMessageModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Usuario',
      userPhotoUrl: map['userPhotoUrl'],
      text: map['text'] ?? '',
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAtMs': createdAtMs,
    };
  }
}
