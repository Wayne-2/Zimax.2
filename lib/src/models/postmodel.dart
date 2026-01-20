class CommunityModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? category;
  final String? customLink;
  final bool isPrivate;
  final String? avatarUrl;
  final String? bannerUrl;
  final List<CommunityRule> rules;
  final DateTime createdAt;
  final int membersCount;

  CommunityModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.category,
    this.customLink,
    required this.isPrivate,
    this.avatarUrl,
    this.bannerUrl,
    this.rules = const [],
    required this.createdAt,
    required this.membersCount,
  });

  factory CommunityModel.fromMap(Map<String, dynamic> map) {
    // If rules are nested under 'community_rules' key
    final rulesData = map['community_rules'] as List<dynamic>? ?? [];

    return CommunityModel(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      customLink: map['custom_link'] as String?,
      isPrivate: map['is_private'] as bool? ?? false,
      avatarUrl: map['avatar_url'] as String?,
      bannerUrl: map['banner_url'] as String?,
      rules: rulesData.map((r) => CommunityRule.fromMap(r)).toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
      membersCount: map['members_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'category': category,
      'custom_link': customLink,
      'is_private': isPrivate,
      'avatar_url': avatarUrl,
      'banner_url': bannerUrl,
      'created_at': createdAt.toIso8601String(),
      // rules are handled separately during insert
    };
  }
}

class CommunityRule {
  final String ruleText;
  final int ruleOrder;

  CommunityRule({required this.ruleText, required this.ruleOrder});

  factory CommunityRule.fromMap(Map<String, dynamic> map) {
    return CommunityRule(
      ruleText: map['rule_text'] as String,
      ruleOrder: map['rule_order'] as int,
    );
  }

  Map<String, dynamic> toMap(String communityId) {
    return {
      'community_id': communityId,
      'rule_text': ruleText,
      'rule_order': ruleOrder,
    };
  }
}
