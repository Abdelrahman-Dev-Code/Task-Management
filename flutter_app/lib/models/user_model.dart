class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String provider;
  final String? googleId;
  final String? emailVerifiedAt;
  final String createdAt;
  final String updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.provider,
    this.googleId,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmailVerified => emailVerifiedAt != null && emailVerifiedAt!.isNotEmpty;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      avatar: json['avatar'] as String?,
      provider: (json['provider'] ?? 'local') as String,
      googleId: json['google_id'] as String?,
      emailVerifiedAt: json['email_verified_at'] as String?,
      createdAt: (json['created_at'] ?? '') as String,
      updatedAt: (json['updated_at'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'provider': provider,
      'google_id': googleId,
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
