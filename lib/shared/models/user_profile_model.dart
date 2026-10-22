class UserProfileModel {
  final String id;
  final String? displayName;
  final String? avatarPath;
  final String preferredLanguage;
  final bool notificationsEnabled;
  final String role;
  final bool isVip;
  final DateTime? vipExpiresAt;
  final DateTime? createdAt;

  const UserProfileModel({
    required this.id,
    this.displayName,
    this.avatarPath,
    this.preferredLanguage = 'km',
    this.notificationsEnabled = true,
    this.role = 'user',
    this.isVip = false,
    this.vipExpiresAt,
    this.createdAt,
  });

  bool get isVipActive {
    if (!isVip) return false;
    if (vipExpiresAt == null) return true; // Lifetime or unexpired
    return vipExpiresAt!.isAfter(DateTime.now());
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    String role = 'user';
    if (json['user_roles'] != null && json['user_roles'] is List && (json['user_roles'] as List).isNotEmpty) {
      role = (json['user_roles'] as List).first['role'] as String? ?? 'user';
    }

    final isVip = json['is_vip'] as bool? ?? false;
    final vipExpiresAt = json['vip_expires_at'] != null
        ? DateTime.tryParse(json['vip_expires_at'] as String)
        : null;

    return UserProfileModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarPath: json['avatar_path'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'km',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      role: role,
      isVip: isVip,
      vipExpiresAt: vipExpiresAt,
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
      'is_vip': isVip,
      'vip_expires_at': vipExpiresAt?.toIso8601String(),
    };
  }
}
