class UserProfile {
  final String uid;
  final String name;
  final String avatar;
  final bool isGoogle;
  final int lastSeenAt;
  final String? avatarFrameId;
  final String? coverId;
  final List<String> badgeIds;
  final String? avatarBadgeId;
  final String? titleId;
  final String? chatStyleId;
  final String? bio;
  final int gold;

  UserProfile({
    required this.uid,
    required this.name,
    required this.avatar,
    required this.isGoogle,
    required this.lastSeenAt,
    this.avatarFrameId,
    this.coverId,
    required this.badgeIds,
    this.avatarBadgeId,
    this.titleId,
    this.chatStyleId,
    this.bio,
    this.gold = 0,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    List<String> badges = [];
    if (map['badgeIds'] is List) {
      badges = List<String>.from(map['badgeIds']);
    } else if (map['badgeIds'] is Map) {
      badges = (map['badgeIds'] as Map).keys.map((k) => k.toString()).toList();
    }

    return UserProfile(
      uid: uid,
      name: map['name']?.toString() ?? 'Misafir Oyuncu',
      avatar: map['avatar']?.toString() ?? '🍄',
      isGoogle: map['isGoogle'] == true,
      lastSeenAt: int.tryParse(map['lastSeenAt']?.toString() ?? '0') ?? 0,
      avatarFrameId: map['avatarFrameId']?.toString(),
      coverId: map['coverId']?.toString(),
      badgeIds: badges,
      avatarBadgeId: map['avatarBadgeId']?.toString(),
      titleId: map['titleId']?.toString(),
      chatStyleId: map['chatStyleId']?.toString(),
      bio: map['bio']?.toString(),
      gold: int.tryParse(map['gold']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'avatar': avatar,
      'isGoogle': isGoogle,
      'lastSeenAt': lastSeenAt,
      if (avatarFrameId != null) 'avatarFrameId': avatarFrameId,
      if (coverId != null) 'coverId': coverId,
      'badgeIds': badgeIds,
      if (avatarBadgeId != null) 'avatarBadgeId': avatarBadgeId,
      if (titleId != null) 'titleId': titleId,
      if (chatStyleId != null) 'chatStyleId': chatStyleId,
      if (bio != null) 'bio': bio,
      'gold': gold,
    };
  }

  UserProfile copyWith({
    String? name,
    String? avatar,
    bool? isGoogle,
    int? lastSeenAt,
    String? avatarFrameId,
    String? coverId,
    List<String>? badgeIds,
    String? avatarBadgeId,
    String? titleId,
    String? chatStyleId,
    String? bio,
    int? gold,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isGoogle: isGoogle ?? this.isGoogle,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      avatarFrameId: avatarFrameId ?? this.avatarFrameId,
      coverId: coverId ?? this.coverId,
      badgeIds: badgeIds ?? this.badgeIds,
      avatarBadgeId: avatarBadgeId ?? this.avatarBadgeId,
      titleId: titleId ?? this.titleId,
      chatStyleId: chatStyleId ?? this.chatStyleId,
      bio: bio ?? this.bio,
      gold: gold ?? this.gold,
    );
  }
}
