import 'package:json_annotation/json_annotation.dart';

part 'catalog.g.dart';

@JsonSerializable()
class Catalog {
  @JsonKey(name: 'catalog_id')
  final String catalogId;

  @JsonKey(name: 'user_id')
  final String userId;

  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final String visibility;

  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  @JsonKey(name: 'item_count')
  final int itemCount;

  @JsonKey(name: 'owned_count')
  final int ownedCount;

  @JsonKey(name: 'completion_rate')
  final double completionRate;

  const Catalog({
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
    required this.itemCount,
    required this.ownedCount,
    required this.completionRate,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) =>
      _$CatalogFromJson(json);
  Map<String, dynamic> toJson() => _$CatalogToJson(this);
}

@JsonSerializable()
class CatalogCreate {
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final String visibility;

  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;

  const CatalogCreate({
    required this.title,
    required this.description,
    this.category = '미분류',
    this.tags = const [],
    this.visibility = 'public',
    this.thumbnailUrl,
  });

  factory CatalogCreate.fromJson(Map<String, dynamic> json) =>
      _$CatalogCreateFromJson(json);
  Map<String, dynamic> toJson() => _$CatalogCreateToJson(this);
}
