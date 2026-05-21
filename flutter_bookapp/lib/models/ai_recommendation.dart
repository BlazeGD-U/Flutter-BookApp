class AiBookRecommendation {
  final String title;
  final String author;
  final String category;
  final String description;

  const AiBookRecommendation({
    required this.title,
    required this.author,
    required this.category,
    required this.description,
  });

  factory AiBookRecommendation.fromJson(Map<String, dynamic> json) {
    return AiBookRecommendation(
      title: (json['title'] ?? '').toString().trim(),
      author: (json['author'] ?? '').toString().trim(),
      category: (json['category'] ?? 'Otro').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
    );
  }

  bool get isValid => title.isNotEmpty && author.isNotEmpty;
}
