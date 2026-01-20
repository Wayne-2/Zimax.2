import 'package:hive/hive.dart';

part 'chat_item_hive.g.dart';

@HiveType(typeId: 1)
class ChatItemHive extends HiveObject {
  @HiveField(0)
  String roomId; // REQUIRED for linking with Supabase

  @HiveField(1)
  String userId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String avatar;

  @HiveField(4)
  String preview;

  @HiveField(5)
  String time; // ISO String

  @HiveField(6)
  bool online;

  ChatItemHive({
    required this.roomId,
    required this.userId,
    required this.name,
    required this.avatar,
    required this.preview,
    required this.time,
    required this.online,
  });
}
