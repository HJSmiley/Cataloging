class Catalog {
  final String catalogId;
  final String userId;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final String visibility;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int itemCount;
  final int ownedCount;
  final double completionRate;
  final String? originalCatalogId; // 복사본인 경우 원본 카탈로그 ID

  Catalog({
    required this.catalogId,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.visibility,
    this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
    this.itemCount = 0,
    this.ownedCount = 0,
    this.completionRate = 0.0,
    this.originalCatalogId,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      catalogId: json['catalog_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      visibility: json['visibility'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      itemCount: json['item_count'] as int? ?? 0,
      ownedCount: json['owned_count'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      originalCatalogId: json['original_catalog_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'catalog_id': catalogId,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'visibility': visibility,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'item_count': itemCount,
      'owned_count': ownedCount,
      'completion_rate': completionRate,
      'original_catalog_id': originalCatalogId,
    };
  }
}
