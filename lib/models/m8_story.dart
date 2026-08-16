class M8Story {
  final String storyId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;

  final String mediaUrl;
  final M8StoryMediaType mediaType;

  final String caption;

  final DateTime createdAt;
  final DateTime expiresAt;

  final int viewCount;
  final bool isActive;

  M8Story({
    required this.storyId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.mediaUrl,
    required this.mediaType,
    this.caption = '',
    required this.createdAt,
    required this.expiresAt,
    this.viewCount = 0,
    this.isActive = true,
  });

  /// Story dianggap masih aktif jika:
  /// 1. isActive = true
  /// 2. belum melewati waktu expiresAt
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  bool get isAvailable {
    return isActive && !isExpired;
  }

  /// Membuat Story dengan masa aktif 24 jam.
  factory M8Story.create({
    required String storyId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String mediaUrl,
    required M8StoryMediaType mediaType,
    String caption = '',
  }) {
    final now = DateTime.now();

    return M8Story(
      storyId: storyId,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      caption: caption,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );
  }

  /// Untuk membaca data Story dari API / database.
  factory M8Story.fromJson(Map<String, dynamic> json) {
    return M8Story(
      storyId: json['story_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      userPhotoUrl: json['user_photo_url']?.toString(),
      mediaUrl: json['media_url']?.toString() ?? '',
      mediaType: M8StoryMediaType.fromString(json['media_type']?.toString()),
      caption: json['caption']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt:
          DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
          DateTime.now().add(const Duration(hours: 24)),
      viewCount: int.tryParse(json['view_count']?.toString() ?? '0') ?? 0,
      isActive:
          json['is_active'] == true || json['is_active']?.toString() == '1',
    );
  }

  /// Untuk dikirim kembali ke API / database.
  Map<String, dynamic> toJson() {
    return {
      'story_id': storyId,
      'user_id': userId,
      'user_name': userName,
      'user_photo_url': userPhotoUrl,
      'media_url': mediaUrl,
      'media_type': mediaType.value,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'view_count': viewCount,
      'is_active': isActive,
    };
  }

  M8Story copyWith({
    String? storyId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? mediaUrl,
    M8StoryMediaType? mediaType,
    String? caption,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? viewCount,
    bool? isActive,
  }) {
    return M8Story(
      storyId: storyId ?? this.storyId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewCount: viewCount ?? this.viewCount,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum M8StoryMediaType {
  image,
  video;

  String get value {
    switch (this) {
      case M8StoryMediaType.image:
        return 'image';
      case M8StoryMediaType.video:
        return 'video';
    }
  }

  static M8StoryMediaType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'video':
        return M8StoryMediaType.video;
      case 'image':
      default:
        return M8StoryMediaType.image;
    }
  }
}
