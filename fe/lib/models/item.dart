import 'package:json_annotation/json_annotation.dart';

part 'item.g.dart';

@JsonSerializable()
class Item {
  @JsonKey(name: 'item_id')
  final String itemId;

  @JsonKey(name: 'catalog_id')
  final String catalogId;

  final String name;
  final String description;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  final bool owned;

  @JsonKey(name: 'user_fields')
  final Map<String, String> userFields;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const Item({
    required this.itemId,
    required this.catalogId,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.owned,
    required this.userFields,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}

@JsonSerializable()
class ItemCreate {
  @JsonKey(name: 'catalog_id')
  final String catalogId;

  final String name;
  final String description;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  final bool owned;

  @JsonKey(name: 'user_fields')
  final Map<String, String> userFields;

  const ItemCreate({
    required this.catalogId,
    required this.name,
    required this.description,
    this.imageUrl,
    this.owned = false,
    this.userFields = const {},
  });

  factory ItemCreate.fromJson(Map<String, dynamic> json) =>
      _$ItemCreateFromJson(json);
  Map<String, dynamic> toJson() => _$ItemCreateToJson(this);
}
