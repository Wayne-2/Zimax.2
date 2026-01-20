class ChatPreview {
  final String chatroomId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatPreview({
    required this.chatroomId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });
}

