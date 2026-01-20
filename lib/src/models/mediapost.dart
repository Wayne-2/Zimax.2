class MediaPost {
  final String id;
  final String userId;
  final String pfp;
  final String username;
  final String department;
  final String level;
  final String status;
  final String title;
  final String? content;
  final String? mediaUrl;
  final int likes;
  final int comments;
  final int polls;
  final bool liked;
  final int reposts;
  final String postedTo;
  final DateTime createdAt;

  MediaPost({
    required this.id,
    required this.userId,
    required this.pfp,
    required this.username,
    required this.department,
    required this.level,
    required this.status,
    required this.title,
    this.content,
    this.mediaUrl,
    required this.likes,
    required this.comments,
    required this.polls,
    required this.liked,
    required this.postedTo,
    required this.reposts,
    required this.createdAt,
  });

  factory MediaPost.fromJson(Map<String, dynamic> json) {
    return MediaPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      pfp: json['pfp'] ?? "",
      username: json['username'] ?? "",
      department: json['department'] ?? "",
      level: json['level'] ?? "",
      status: json['status'] ?? "",
      title: json['title'] ?? "",
      content: json['content'],
      mediaUrl: json['media_url'],
      likes: (json['likes'] ?? 0) as int,
      comments: (json['comments_count'] ?? 0) as int,
      polls: (json['polls'] ?? 0) as int,
      postedTo: json['posted_to'] ?? "",
      reposts: (json['reposts'] ?? 0) as int,
      createdAt: DateTime.tryParse(json['created_at'] ?? "") ??
          DateTime.now(), liked: (json['liked'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'pfp': pfp,
      'username': username,
      'department': department,
      'level': level,
      'status': status,
      'title': title,
      'content': content,
      'media_url': mediaUrl,
      'likes': likes,
      'comments_count': comments,
      'posted_to': postedTo,
      'polls': polls,
      'reposts': reposts,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
