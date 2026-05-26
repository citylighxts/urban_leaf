enum ArticleCategory { tips, tutorial, weather, plant, pest }

class ArticleModel {
  final String id;
  final String title;
  final String subtitle;
  final String content;
  final ArticleCategory category;
  final String emoji;
  final String readTime;
  final DateTime publishedAt;
  final bool isFeatured;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.category,
    required this.emoji,
    required this.readTime,
    required this.publishedAt,
    this.isFeatured = false,
  });

  String get categoryLabel {
    switch (category) {
      case ArticleCategory.tips:
        return 'Tips';
      case ArticleCategory.tutorial:
        return 'Tutorial';
      case ArticleCategory.weather:
        return 'Cuaca';
      case ArticleCategory.plant:
        return 'Tanaman';
      case ArticleCategory.pest:
        return 'Hama & Penyakit';
    }
  }
}

class RecommendedPlantModel {
  final String name;
  final String emoji;
  final String reason;
  final String difficulty;
  final List<String> benefits;

  const RecommendedPlantModel({
    required this.name,
    required this.emoji,
    required this.reason,
    required this.difficulty,
    required this.benefits,
  });
}
