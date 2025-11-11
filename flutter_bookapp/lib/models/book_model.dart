class BookModel {
  final String id;
  final String userId;
  final String title;
  final String author;
  final String category;
  final String status;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.category,
    required this.status,
    required this.description,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return BookModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? 'Pendiente',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'author': author,
      'category': category,
      'status': status,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BookModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? author,
    String? category,
    String? status,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      status: status ?? this.status,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isPendingForTooLong() {
    if (status != 'Pendiente') return false;
    final hoursDifference = DateTime.now().difference(updatedAt).inHours;
    return hoursDifference >= 48;
  }
}

