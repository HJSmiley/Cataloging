// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Catalog _$CatalogFromJson(Map<String, dynamic> json) => Catalog(
  catalogId: json['catalog_id'] as String,
  userId: json['user_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  visibility: json['visibility'] as String,
  thumbnailUrl: json['thumbnail_url'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
  itemCount: (json['item_count'] as num).toInt(),
  ownedCount: (json['owned_count'] as num).toInt(),
  completionRate: (json['completion_rate'] as num).toDouble(),
);

Map<String, dynamic> _$CatalogToJson(Catalog instance) => <String, dynamic>{
  'catalog_id': instance.catalogId,
  'user_id': instance.userId,
  'title': instance.title,
  'description': instance.description,
  'category': instance.category,
  'tags': instance.tags,
  'visibility': instance.visibility,
  'thumbnail_url': instance.thumbnailUrl,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'item_count': instance.itemCount,
  'owned_count': instance.ownedCount,
  'completion_rate': instance.completionRate,
};

CatalogCreate _$CatalogCreateFromJson(Map<String, dynamic> json) =>
    CatalogCreate(
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? '미분류',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      visibility: json['visibility'] as String? ?? 'public',
      thumbnailUrl: json['thumbnail_url'] as String?,
    );

Map<String, dynamic> _$CatalogCreateToJson(CatalogCreate instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'tags': instance.tags,
      'visibility': instance.visibility,
      'thumbnail_url': instance.thumbnailUrl,
    };
