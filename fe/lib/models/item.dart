class Item {
  final String itemId;
  final String catalogId;
  final String name;
  final String description;
  final String? imageUrl;
  final bool owned;
  final Map<String, String> userFields;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Item({
    required this.itemId,
    required this.catalogId,
    required this.name,
    required this.description,
    this.imageUrl,
    this.owned = false,
    Map<String, String>? userFields,
    required this.createdAt,
    required this.updatedAt,
  }) : userFields = userFields ?? {};
  
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemId: json['item_id'] as String,
      catalogId: json['catalog_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      owned: json['owned'] as bool? ?? false,
      userFields: (json['user_fields'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'catalog_id': catalogId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'owned': owned,
      'user_fields': userFields,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  Item copyWith({
    String? itemId,
    String? catalogId,
    String? name,
    String? description,
    String? imageUrl,
    bool? owned,
    Map<String, String>? userFields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      itemId: itemId ?? this.itemId,
      catalogId: catalogId ?? this.catalogId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      owned: owned ?? this.owned,
      userFields: userFields ?? this.userFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

