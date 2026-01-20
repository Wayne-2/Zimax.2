class CommunityModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isPrivate;
  final int membersCount;

  CommunityModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isPrivate,
    required this.membersCount,
  });

  factory CommunityModel.fromMap(Map<String, dynamic> map) {
    return CommunityModel(
      id: map['id'],
      name: map['name'],
      avatarUrl: map['avatar_url'],
      isPrivate: map['is_private'] ?? false,
      membersCount: map['members_count'] ?? 0,
    );
  }
}
