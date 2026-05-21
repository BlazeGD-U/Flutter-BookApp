class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final int totalPoints;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.totalPoints = 0,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'totalPoints': totalPoints,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    int? totalPoints,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

