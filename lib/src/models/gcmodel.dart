class CommunityMessage {
  final String id;
  final String communityId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  CommunityMessage({
    required this.id,
    required this.communityId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory CommunityMessage.fromMap(Map<String, dynamic> map) {
    return CommunityMessage(
      id: map['id'],
      communityId: map['community_id'],
      senderId: map['sender_id'],
      senderName: map['sender_name'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
      isRead: map['is_read'] ?? false,
    );
  }
}

class ChatState {
  final List<CommunityMessage> messages;
  final List<String> typingUsers;
  final DateTime? lastRead;

  ChatState({
    required this.messages,
    this.typingUsers = const [],
    this.lastRead,
  });

  ChatState copyWith({
    List<CommunityMessage>? messages,
    List<String>? typingUsers,
    DateTime? lastRead,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      typingUsers: typingUsers ?? this.typingUsers,
      lastRead: lastRead ?? this.lastRead,
    );
  }
}