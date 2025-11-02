// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
  itemId: json['item_id'] as String,
  catalogId: json['catalog_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  imageUrl: json['image_url'] as String?,
  owned: json['owned'] as bool,
  userFields: Map<String, String>.from(json['user_fields'] as Map),
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
  'item_id': instance.itemId,
  'catalog_id': instance.catalogId,
  'name': instance.name,
  'description': instance.description,
  'image_url': instance.imageUrl,
  'owned': instance.owned,
  'user_fields': instance.userFields,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

ItemCreate _$ItemCreateFromJson(Map<String, dynamic> json) => ItemCreate(
  catalogId: json['catalog_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  imageUrl: json['image_url'] as String?,
  owned: json['owned'] as bool? ?? false,
  userFields:
      (json['user_fields'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
);

Map<String, dynamic> _$ItemCreateToJson(ItemCreate instance) =>
    <String, dynamic>{
      'catalog_id': instance.catalogId,
      'name': instance.name,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'owned': instance.owned,
      'user_fields': instance.userFields,
    };
