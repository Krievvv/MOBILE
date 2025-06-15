class UserProfile {
  final String id;
  final DateTime createdAt;
  final String username; // Required field
  final String? fullName;
  final String? bio;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.createdAt,
    required this.username,
    this.fullName,
    this.bio,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'username': username,
      'full_name': fullName,
      'bio': bio,
      'avatar_url': avatarUrl,
    };
  }

  UserProfile copyWith({
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      createdAt: createdAt,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
