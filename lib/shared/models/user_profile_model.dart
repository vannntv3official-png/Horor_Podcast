class UserProfileModel {
  final String id;
  final String? displayName;
  final String? avatarPath;
  final String preferredLanguage;
  final bool notificationsEnabled;
  final String role;
  final DateTime? createdAt;

  const UserProfileModel({
    required this.id,
    this.displayName,
    this.avatarPath,
    this.preferredLanguage = 'km',
    this.notificationsEnabled = true,
    this.role = 'user',
    this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    String role = 'user';
    if (json['user_roles'] != null && json['user_roles'] is List && (json['user_roles'] as List).isNotEmpty) {
      role = (json['user_roles'] as List).first['role'] as String? ?? 'user';
    }

    return UserProfileModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarPath: json['avatar_path'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'km',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      role: role,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_path': avatarPath,
      'preferred_language': preferredLanguage,
      'notifications_enabled': notificationsEnabled,
    };
  }
}
