class User {
  final int id;
  final String email;
  final String nickname;
  final String? profileImage;
  final String? introduction;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  User({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImage,
    this.introduction,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      profileImage: json['profileImage'] as String?,
      introduction: json['introduction'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'profileImage': profileImage,
      'introduction': introduction,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  User copyWith({
    int? id,
    String? email,
    String? nickname,
    String? profileImage,
    String? introduction,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      profileImage: profileImage ?? this.profileImage,
      introduction: introduction ?? this.introduction,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

