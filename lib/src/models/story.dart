class StoryItem {
  final String id; // Story ID
  final String userId; // Story creator's user ID
  final String name;
  final String? imageUrl;
  final String? avatar;
  final bool isText;
  final String? text;

  StoryItem({
    required this.id,
    required this.userId,
    required this.name,
    this.imageUrl,
    this.avatar,
    this.isText = false,
    this.text,
  });
}
