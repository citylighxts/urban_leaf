import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'content': content,
        'category': category.name,
        'emoji': emoji,
        'readTime': readTime,
        'publishedAt': publishedAt.millisecondsSinceEpoch,
        'isFeatured': isFeatured,
      };

  factory ArticleModel.fromMap(
    Map<String, dynamic> map, {
    String? docId,
  }) {
    final publishedAtValue = map['publishedAt'];
    DateTime parsedPublishedAt;

    if (publishedAtValue is Timestamp) {
      parsedPublishedAt = publishedAtValue.toDate();
    } else if (publishedAtValue is DateTime) {
      parsedPublishedAt = publishedAtValue;
    } else if (publishedAtValue is int) {
      parsedPublishedAt = DateTime.fromMillisecondsSinceEpoch(publishedAtValue);
    } else if (publishedAtValue is String) {
      parsedPublishedAt = DateTime.tryParse(publishedAtValue) ??
          DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(publishedAtValue) ?? 0,
          );
    } else if (publishedAtValue is num) {
      parsedPublishedAt = DateTime.fromMillisecondsSinceEpoch(
        publishedAtValue.toInt(),
      );
    } else {
      parsedPublishedAt = DateTime.now();
    }

    return ArticleModel(
      id: docId ?? (map['id'] as String? ?? ''),
      title: (map['title'] as String?) ?? '',
      subtitle: (map['subtitle'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      category: ArticleCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ArticleCategory.tips,
      ),
      emoji: (map['emoji'] as String?) ?? '📘',
      readTime: (map['readTime'] as String?) ?? '0 menit',
      publishedAt: parsedPublishedAt,
      isFeatured: (map['isFeatured'] as bool?) ?? false,
    );
  }
}
