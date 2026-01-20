// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zimax/src/components/chatroom.dart';
import 'package:zimax/src/components/svgicon.dart';
import 'package:zimax/src/models/chat_item_hive.dart';
import 'package:zimax/src/models/chatitem.dart';
import 'package:zimax/src/models/chatpreview.dart';
// import 'package:zimax/src/models/mediapost.dart';
import 'package:zimax/src/models/story.dart';
import 'package:zimax/src/pages/extrapage.dart/addchat.dart';
import 'package:zimax/src/pages/extrapage.dart/storypage.dart';
import 'package:zimax/src/services/riverpod.dart';
import 'package:zimax/src/components/publicprofile.dart';

class Chat extends ConsumerStatefulWidget {
  const Chat({super.key});

  @override
  ConsumerState<Chat> createState() => _ChatState();
}

class _ChatState extends ConsumerState<Chat> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late Box<ChatItemHive> chatBox;
  List<ChatItemHive> chats = [];

  List<StoryItem> stories = [];
  bool loading = true;
  bool isLoadingChats = false;

  // Separate channels for better management
  RealtimeChannel? _chatPreviewChannel;
  RealtimeChannel? _storyChannel;

  late AnimationController _intro;
  late AnimationController _pulse;
  late Animation<double> fade, slide, bounce, pulseAnim;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeChat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _intro.dispose();
    _pulse.dispose();
    _chatPreviewChannel?.unsubscribe();
    _storyChannel?.unsubscribe();
    super.dispose();
  }

  /// Initialize chat data and subscriptions
  Future<void> _initializeChat() async {
    await _loadHive();
    await _syncWithSupabase();
    await loadStatus();
    subscribeChatPreviews();
    subscribeStoryRealtime();
  }

  /// Load saved chats from Hive
  Future<void> _loadHive() async {
    try {
      chatBox = Hive.box<ChatItemHive>('chatBox');

      setState(() {
        chats = chatBox.values.toList();
        chats.sort((a, b) => b.time.compareTo(a.time));
      });
    } catch (e) {
      debugPrint('Error loading Hive: $e');
    }
  }

  /// Sync chats with Supabase chatrooms
  Future<void> _syncWithSupabase() async {
    if (isLoadingChats) return;

    setState(() => isLoadingChats = true);

    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final rooms = await supabase
          .from('chatrooms')
          .select("""
            id,
            user1,
            user2,
            created_at,
            last_message:messages(message, created_at)
          """)
          .or('user1.eq.$uid,user2.eq.$uid');

      if (rooms.isEmpty) {
        setState(() {
          chats = [];
          isLoadingChats = false;
        });
        return;
      }

      // Batch fetch all user profiles
      final otherIds = rooms
          .map((r) => r['user1'] == uid ? r['user2'] : r['user1'])
          .toSet()
          .toList();

      // Fetch profiles one by one or use filter
      final profiles = <Map<String, dynamic>>[];
      for (final id in otherIds) {
        try {
          final profile = await supabase
              .from('user_profile')
              .select()
              .eq('id', id)
              .maybeSingle();
          if (profile != null) {
            profiles.add(profile);
          }
        } catch (e) {
          debugPrint('Error fetching profile for $id: $e');
        }
      }

      final profileMap = {for (var p in profiles) p['id']: p};

      // Build chat items
      final newChats = <ChatItemHive>[];
      for (final r in rooms) {
        final otherId = r['user1'] == uid ? r['user2'] : r['user1'];
        final profile = profileMap[otherId];

        if (profile == null) continue;

        // Get the last message from the messages array
        final messages = r['last_message'] as List?;
        String lastMsg = "Start a conversation";
        String time = r['created_at'];

        if (messages != null && messages.isNotEmpty) {
          // Sort messages by created_at to get the latest
          messages.sort((a, b) => 
            DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']))
          );
          lastMsg = messages[0]['message'] ?? lastMsg;
          time = messages[0]['created_at'];
        }

        final chatItem = ChatItemHive(
          roomId: r['id'],
          userId: otherId,
          name: profile['fullname'] ?? 'Unknown',
          avatar: profile['profile_image_url'] ?? '',
          preview: lastMsg,
          time: time,
          online: false,
        );

        await chatBox.put(r['id'], chatItem);
        newChats.add(chatItem);
      }

      setState(() {
        chats = newChats..sort((a, b) => b.time.compareTo(a.time));
        isLoadingChats = false;
      });
    } catch (e) {
      debugPrint('Error syncing chats: $e');
      setState(() => isLoadingChats = false);

      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Failed to sync chats: ${e.toString()}'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      // }
    }
  }

  /// Subscribe to chat preview updates
  void subscribeChatPreviews() {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    _chatPreviewChannel = supabase.channel('chat_preview_channel');

    _chatPreviewChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) async {
        try {
          final record = payload.newRecord;

          // Ignore my own messages for preview updates
          if (record['sender'] == myId) return;

          final chatroomId = record['chatroom_id'] as String?;
          final message = record['message'] as String? ?? '';
          final createdAt = record['created_at'] as String?;

          if (chatroomId == null || createdAt == null) return;

          // Update chat preview in Hive
          final existingChat = chatBox.get(chatroomId);
          if (existingChat != null) {
            final updatedChat = ChatItemHive(
              roomId: existingChat.roomId,
              userId: existingChat.userId,
              name: existingChat.name,
              avatar: existingChat.avatar,
              preview: message,
              time: createdAt,
              online: existingChat.online,
            );

            await chatBox.put(chatroomId, updatedChat);

            // Update local state
            setState(() {
              final index = chats.indexWhere((c) => c.roomId == chatroomId);
              if (index != -1) {
                chats[index] = updatedChat;
                // Move to top
                chats.removeAt(index);
                chats.insert(0, updatedChat);
              }
            });
          }

          // Update Riverpod provider for unread count
          ref.read(chatPreviewProvider.notifier).onNewMessage(
                chatroomId: chatroomId,
                message: message,
                createdAt: DateTime.parse(createdAt),
                isMine: false,
              );
        } catch (e) {
          debugPrint('Error processing chat preview: $e');
        }
      },
    )
        .subscribe();
  }

  /// Fetch status posts
  Future<void> loadStatus() async {
    try {
      final posts = await supabase
          .from('media_posts')
          .select()
          .eq('posted_to', 'Story')
          .order('created_at', ascending: false);

      final postList = List<Map<String, dynamic>>.from(posts);

      if (mounted) {
        setState(() {
          stories = postList
              .map((json) => StoryItem(
                    id: json['id'], // Story ID
                    userId: json['user_id'] ?? '', // Creator's user ID
                    name: json['username'] ?? 'Unknown',
                    avatar: json['pfp'],
                    imageUrl: json['media_url'],
                    text: json['content'],
                  ))
              .toList();
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stories: $e');
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  /// Subscribe to Realtime updates for new status posts
  void subscribeStoryRealtime() {
    _storyChannel = supabase.channel('story_channel');

    _storyChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'media_posts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'posted_to',
            value: 'Story',
          ),
          callback: (payload) {
            try {
              final json = payload.newRecord;
              final newStory = StoryItem(
                id: json['id'], // Story ID
                userId: json['user_id'] ?? '', // Creator's user ID
                name: json['username'] ?? 'Unknown',
                avatar: json['pfp'],
                imageUrl: json['media_url'],
                text: json['content'],
              );

              if (mounted) {
                setState(() {
                  if (!stories.any((s) => s.id == newStory.id)) {
                    stories.insert(0, newStory);
                  }
                });
              }
            } catch (e) {
              debugPrint('Error processing new story: $e');
            }
          },
        )
        .subscribe();
  }

  /// Setup animations
  void _setupAnimations() {
    _intro = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _pulse = AnimationController(
        vsync: this, duration: const Duration(seconds: 2));

    fade = CurvedAnimation(parent: _intro, curve: Curves.easeIn);
    slide = Tween<double>(begin: 30, end: 0)
        .animate(CurvedAnimation(parent: _intro, curve: Curves.easeOut));
    bounce = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _intro, curve: Curves.elasticOut));
    pulseAnim = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    _intro.forward();
    _intro.addStatusListener((s) {
      if (s == AnimationStatus.completed) _pulse.repeat(reverse: true);
    });
  }

  /// Create or get chat room
  Future<String> getOrCreateRoom(String otherUserId) async {
    try {
      final myId = supabase.auth.currentUser?.id;
      if (myId == null) throw Exception('User not authenticated');

      final existing = await supabase
          .from('chatrooms')
          .select('id')
          .or(
              'and(user1.eq.$myId,user2.eq.$otherUserId),and(user1.eq.$otherUserId,user2.eq.$myId)')
          .maybeSingle();

      if (existing != null) return existing['id'];

      final roomId = const Uuid().v4();
      await supabase.from('chatrooms').insert({
        "id": roomId,
        "user1": myId,
        "user2": otherUserId,
      });

      return roomId;
    } catch (e) {
      debugPrint('Error creating/getting room: $e');
      rethrow;
    }
  }

  /// Add new chat
  void addChat(ChatItem item) async {
    try {
      final roomId = await getOrCreateRoom(item.userId);
      final hiveItem = ChatItemHive(
        roomId: roomId,
        userId: item.userId,
        name: item.name,
        avatar: item.avatar,
        preview: item.preview,
        time: DateTime.now().toIso8601String(),
        online: item.online,
      );

      await chatBox.put(roomId, hiveItem);

      setState(() {
        chats.removeWhere((c) => c.roomId == roomId);
        chats.insert(0, hiveItem);
      });
    } catch (e) {
      debugPrint('Error adding chat: $e');
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Failed to create chat: ${e.toString()}'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      // }
    }
  }

  /// Get filtered chats based on search query
  List<ChatItemHive> get _filteredChats {
    if (_searchQuery.isEmpty) return chats;

    return chats.where((chat) {
      return chat.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          chat.preview.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          "Zimax Chat",
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Publicprofile(userId: user.id),
                ),
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundImage: CachedNetworkImageProvider(user.pfp),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _syncWithSupabase();
          await loadStatus();
        },
        child: Column(
          children: [
            _searchBar(),
            _buildStoryHeader(),
            _buildStoryList(user),
            _buildChatHeader(),
            _buildChatList(),
          ],
        ),
      ),
      floatingActionButton: _fab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          height: 40,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 226, 226, 226),
            borderRadius: BorderRadius.circular(50),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Search chats...',
              hintStyle: GoogleFonts.poppins(fontSize: 13),
              prefixIcon: const Icon(Icons.manage_search_sharp),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
      );

  Widget _buildStoryHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Story',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  Map<String, List<StoryItem>> _groupStoriesByUser(List<StoryItem> stories) {
    final Map<String, List<StoryItem>> grouped = {};
    for (var story in stories) {
      grouped.putIfAbsent(story.name, () => []).add(story);
    }
    return grouped;
  }

  Widget _buildStoryList(dynamic user) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SizedBox(
          height: 90,
          child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (_, _) => storyItemShimmer() 
        ),
        ),
      );
    }

    if (stories.isEmpty) {
      return SizedBox(
        height: 90,
        child: Center(
          child: Text(
            "No stories available",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
        ),
      );
    }

    final groupedStories = _groupStoriesByUser(stories);
    final userList = groupedStories.keys.toList();

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: userList.length,
        padding: const EdgeInsets.all(10),
        itemBuilder: (_, index) {
          final username = userList[index];
          final userStories = groupedStories[username]!;
          final firstStory = userStories[0];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoryPage(
                    stories: userStories,
                    initialIndex: 0,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: CachedNetworkImageProvider(
                          firstStory.avatar ?? 'https://kldaeoljhumowuegwjyq.supabase.co/storage/v1/object/public/avatar/profile/nopfp.png',
                        ),
                      ),
                      if (userStories.length > 1)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                '${userStories.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Text(
                      username,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatHeader() => Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Text(
              "Conversations",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _buildChatList() {
    final previews = ref.watch(chatPreviewProvider);
    final filteredChats = _filteredChats;

    if (isLoadingChats) {
      return Expanded(
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (_, _) => chatItemShimmer()
        ),
      );
    }

    if (filteredChats.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            _searchQuery.isEmpty
                ? "Tap on New to start conversation"
                : "No chats found",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
          ),
        ),
      );
    }

    // Sort chats: latest message first
    final sortedChats = [...filteredChats];
    sortedChats.sort((a, b) {
      final aTime =
          previews[a.roomId]?.lastMessageTime ?? DateTime.parse(a.time);
      final bTime =
          previews[b.roomId]?.lastMessageTime ?? DateTime.parse(b.time);
      return bTime.compareTo(aTime);
    });

    return Expanded(
      child: ListView.builder(
        itemCount: sortedChats.length,
        itemBuilder: (_, i) {
          final chat = sortedChats[i];
          final preview = previews[chat.roomId];

          return _chatTile(chat, preview: preview);
        },
      ),
    );
  }

  Widget _chatTile(
    ChatItemHive chat, {
    ChatPreview? preview,
  }) =>
      InkWell(
        onTap: () async {
          try {
            final roomId = await getOrCreateRoom(chat.userId);

            // Mark messages as read immediately
            ref.read(chatPreviewProvider.notifier).markAsRead(roomId);

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Chatroom(
                    roomId: roomId,
                    friend: {
                      "id": chat.userId,
                      "name": chat.name,
                      "avatar": chat.avatar,
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint('Error opening chat: $e');
            // if (mounted) {
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     SnackBar(
            //       content: Text('Failed to open chat: ${e.toString()}'),
            //       backgroundColor: Colors.red,
            //     ),
            //   );
            // }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black12, width: .4),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: CachedNetworkImageProvider(chat.avatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preview?.lastMessage ?? chat.preview,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (preview?.lastMessageTime != null)
                    Text(
                      _formatPreviewTime(preview!.lastMessageTime),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (preview != null && preview.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        preview.unreadCount > 99
                            ? '99+'
                            : preview.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );

  String _formatPreviewTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Widget _fab() => AnimatedBuilder(
        animation: Listenable.merge([_intro, _pulse]),
        builder: (_, child) {
          final scale = bounce.value * pulseAnim.value;

          return Opacity(
            opacity: fade.value,
            child: Transform.translate(
              offset: Offset(0, slide.value),
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: GestureDetector(
          onTap: () async {
            final ChatItem? item = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddChatPage()),
            );

            if (item != null) addChat(item);
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  color: Colors.black.withOpacity(0.25),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgIcon(
                  "assets/icons/newchat.svg",
                  size: 25,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                const Text(
                  "New",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
Widget chatItemShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black12, width: .4),
        ),
      ),
      child: Row(
        children: [
          // Avatar placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name placeholder
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.white,
                ),
                const SizedBox(height: 6),
                // Last message placeholder
                Container(
                  width: 150,
                  height: 12,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Time placeholder
              Container(
                width: 40,
                height: 10,
                color: Colors.white,
              ),
              const SizedBox(height: 6),
              // Unread badge placeholder
              Container(
                width: 20,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget storyItemShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circle avatar placeholder
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          // Username placeholder
          Container(
            width: 60,
            height: 12,
            color: Colors.white,
          ),
        ],
      ),
    ),
  );
}
