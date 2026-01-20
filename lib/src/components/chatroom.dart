// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/models/chat_item_hive.dart';
import 'package:zimax/src/pages/extrapage/callpage.dart';
import 'package:zimax/src/services/riverpod.dart';
import 'package:zimax/src/components/publicprofile.dart';

class Chatroom extends ConsumerStatefulWidget {
  final String roomId;
  final Map friend;

  const Chatroom({
    super.key,
    required this.roomId,
    required this.friend,
  });

  @override
  ConsumerState<Chatroom> createState() => _ChatroomState();
}

class _ChatroomState extends ConsumerState<Chatroom> {
  final supabase = Supabase.instance.client;
  late Box<ChatItemHive> chatBox;

  Map<String, dynamic>? selectedMessage;
  Map<String, dynamic>? replyTo;

  final List<Map<String, dynamic>> messages = [];
  final ScrollController scroll = ScrollController();
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  RealtimeChannel? channel;
  bool isLoading = true;
  bool _isAtBottom = true;
  bool _showScrollToBottom = false;
  int _unreadCount = 0;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeChatroom();
    scroll.addListener(_scrollListener);
    controller.addListener(_textListener);
  }

  @override
  void dispose() {
    channel?.unsubscribe();
    controller.removeListener(_textListener);
    controller.dispose();
    scroll.removeListener(_scrollListener);
    scroll.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!scroll.hasClients) return;

    final isAtBottom = scroll.position.pixels >= scroll.position.maxScrollExtent - 100;

    if (_isAtBottom != isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
        _showScrollToBottom = !isAtBottom;
        if (isAtBottom) _unreadCount = 0;
      });
    }
  }

  void _textListener() {
    final hasText = controller.text.trim().isNotEmpty;
    if (_isTyping != hasText) {
      setState(() => _isTyping = hasText);
    }
  }

  Future<void> _initializeChatroom() async {
    try {
      chatBox = Hive.box<ChatItemHive>('chatBox');
      await loadMessages();
      subscribeRealtime();

      // Mark messages as read
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatPreviewProvider.notifier).markAsRead(widget.roomId);
      });
    } catch (e) {
      debugPrint('Error initializing chatroom: $e');
    }
  }

  Future<void> loadMessages() async {
    try {
      setState(() => isLoading = true);

      final res = await supabase
          .from("messages")
          .select()
          .eq("chatroom_id", widget.roomId)
          .order("created_at", ascending: true);

      if (mounted) {
        setState(() {
          messages.clear();
          messages.addAll(List<Map<String, dynamic>>.from(res));
          isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom(animate: false));
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void subscribeRealtime() {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    channel = supabase.channel("room-${widget.roomId}");

    channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: "public",
          table: "messages",
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: "chatroom_id",
            value: widget.roomId,
          ),
          callback: (payload) async {
            try {
              final record = payload.newRecord;
              final isMine = record['sender'] == myId;

              // Only add if not already in local messages
              if (!messages.any((m) => m['id'] == record['id'])) {
                if (mounted) {
                  setState(() => messages.add(record));
                }

                // Update Hive chat preview for all messages
                await _updateChatPreviewInHive(
                  record['message'] as String,
                  record['created_at'] as String,
                );

                // Update Riverpod provider for unread count
                if (!isMine) {
                  ref.read(chatPreviewProvider.notifier).onNewMessage(
                        chatroomId: widget.roomId,
                        message: record['message'],
                        createdAt: DateTime.parse(record['created_at']),
                        isMine: false,
                      );

                  // Increment unread count if not at bottom
                  if (!_isAtBottom && mounted) {
                    setState(() => _unreadCount++);
                  }
                }

                // Auto-scroll based on conditions
                if (isMine || _isAtBottom) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) scrollToBottom();
                  });
                }
              }
            } catch (e) {
              debugPrint('Error processing realtime message: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: "public",
          table: "messages",
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: "chatroom_id",
            value: widget.roomId,
          ),
          callback: (payload) {
            final deletedId = payload.oldRecord['id'];
            if (mounted) {
              setState(() {
                messages.removeWhere((m) => m['id'] == deletedId);
              });
            }
          },
        )
        .subscribe();
  }

  /// Update chat preview in Hive
  Future<void> _updateChatPreviewInHive(
    String message,
    String timestamp,
  ) async {
    try {
      final existingChat = chatBox.get(widget.roomId);

      if (existingChat != null) {
        final updatedChat = ChatItemHive(
          roomId: existingChat.roomId,
          userId: existingChat.userId,
          name: existingChat.name,
          avatar: existingChat.avatar,
          preview: message,
          time: timestamp,
          online: existingChat.online,
        );

        await chatBox.put(widget.roomId, updatedChat);
      } else {
        // If chat doesn't exist in Hive, create it
        final newChat = ChatItemHive(
          roomId: widget.roomId,
          userId: widget.friend['id'],
          name: widget.friend['name'],
          avatar: widget.friend['avatar'],
          preview: message,
          time: timestamp,
          online: false,
        );

        await chatBox.put(widget.roomId, newChat);
      }
    } catch (e) {
      debugPrint('Error updating chat preview in Hive: $e');
    }
  }

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      controller.clear();
      focusNode.unfocus();

      // Insert message and return the inserted record
      final inserted = await supabase.from("messages").insert({
        "chatroom_id": widget.roomId,
        "sender": uid,
        "message": text,
        "reply_to": replyTo?["id"],
      }).select().single();

      await supabase.functions.invoke(
        'send-notification',
        body: {
          'receiver_id': widget.friend['id'],
          'sender_name': 'You', // or real name
          'message': text,
        },
      );

      if (mounted) {
        setState(() {
          replyTo = null;
          // Only add if not already present (realtime might add it first)
          if (!messages.any((m) => m['id'] == inserted['id'])) {
            messages.add(inserted);
          }
        });
      }

      // Update Hive with the new message preview
      await _updateChatPreviewInHive(
        inserted["message"],
        inserted["created_at"],
      );

      // Update Riverpod provider for outgoing message
      ref.read(chatPreviewProvider.notifier).onNewMessage(
            chatroomId: widget.roomId,
            message: inserted["message"],
            createdAt: DateTime.parse(inserted["created_at"]),
            isMine: true,
          );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) scrollToBottom();
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Failed to send message'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void scrollToBottom({bool animate = true}) {
    if (!scroll.hasClients) return;

    if (animate) {
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      scroll.jumpTo(scroll.position.maxScrollExtent);
    }

    setState(() {
      _unreadCount = 0;
      _showScrollToBottom = false;
    });
  }

  void _showMessageMenu(BuildContext context, Map msg, bool isMe) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                setState(() => selectedMessage = null);
                Navigator.pop(context);
              },
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              top: 200,
              right: isMe ? 20 : null,
              left: isMe ? null : 20,
              child: Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _menuItem(Icons.reply, "Reply", () {
                      setState(() {
                        replyTo = msg as Map<String, dynamic>;
                        selectedMessage = null;
                      });
                      Navigator.pop(context);
                      focusNode.requestFocus();
                    }),
                    _menuItem(Icons.copy, "Copy", () {
                      Clipboard.setData(ClipboardData(text: msg["message"]));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Message copied'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green[700],
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }),
                    if (isMe)
                      _menuItem(
                        Icons.delete,
                        "Delete",
                        () {
                          Navigator.pop(context);
                          _deleteMessage(msg["id"]);
                        },
                        color: Colors.red,
                      ),
                    _menuItem(Icons.info_outline, "Info", () {
                      Navigator.pop(context);
                      _showMessageInfo(context, msg);
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessageInfo(BuildContext context, Map msg) {
    final createdAt = DateTime.parse(msg['created_at']).toLocal();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Message Info',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Sent', _formatFullDateTime(createdAt)),
            const SizedBox(height: 8),
            _infoRow('Time', _formatTime(msg['created_at'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  String _formatFullDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return "${dt.day} ${months[dt.month - 1]}, ${dt.year}";
  }

  Future<void> _deleteMessage(String id) async {
    try {
      await supabase.from("messages").delete().eq("id", id);

      if (mounted) {
        setState(() {
          messages.removeWhere((m) => m["id"] == id);
          selectedMessage = null;
        });

        // Update Hive with the new last message if this was the last one
        if (messages.isNotEmpty) {
          final lastMessage = messages.last;
          await _updateChatPreviewInHive(
            lastMessage['message'],
            lastMessage['created_at'],
          );
        } else {
          // If no messages left, update with default message
          await _updateChatPreviewInHive(
            "Start a conversation",
            DateTime.now().toIso8601String(),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message deleted'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete message'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatTime(String isoTime) {
    final dt = DateTime.parse(isoTime).toLocal();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  bool _shouldShowDateSeparator(DateTime? prev, DateTime current) {
    if (prev == null) return true;
    return prev.year != current.year ||
        prev.month != current.month ||
        prev.day != current.day;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[date.weekday - 1];
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${date.day} ${months[date.month - 1]}, ${date.year}";
    }
  }

  Widget _buildDateSeparator(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _formatDateSeparator(date),
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _startCall({required bool isVideo}) async {
    try {
      final myId = supabase.auth.currentUser?.id;
      if (myId == null) throw Exception('Not authenticated');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(isVideo ? 'Starting video call...' : 'Starting audio call...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final callData = await supabase.from('calls').insert({
        'room_id': widget.roomId,
        'caller_id': myId,
        'receiver_id': widget.friend['id'],
        'is_video': isVideo,
        'status': 'ringing',
      }).select().single();


      // Convert ID to string (could be int or string from database)
      
      final callId = callData['id'];
      debugPrint('Call created with lessonId: $callId');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallPage(
            callId: callId,
            isCaller: true,
            isVideo: isVideo,
            userId: widget.friend['id'], 
            friendName: widget.friend['name'],
          ),
        ),
      );

      final receiverId = widget.friend['id'];

      final tokens = await supabase
          .from('device_tokens')
          .select('token')
          .eq('user_id', receiverId);

      if (tokens.isEmpty) {
        print('No FCM token for receiver');
        return;
      }

      final String receiverFcmToken = tokens.first['token'];

      final currentUser = await supabase.auth.getUser();
      final String currentUserName =
      currentUser.user?.userMetadata?['name'] ?? 'Someone';


      await supabase.functions.invoke(
        'send-notification',
        body: {
          'token': receiverFcmToken,
          'title': isVideo ? 'Incoming video call' : 'Incoming audio call',
          'body': '$currentUserName is calling you',
          'data': {
            'type': 'call',
            'call_id': callId,
          }
        },
      );


    } catch (e) {
      debugPrint('Error starting call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start call: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: Text('Mute notifications', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications muted')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: Text('Block user', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text('Clear chat', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser?.id;

    if (myId == null) {
      return const Scaffold(
        body: Center(child: Text('Authentication error')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildMessages(myId),
              ),
              _buildInputBar(),
            ],
          ),
          
          // Scroll to bottom button
          if (_showScrollToBottom)
            Positioned(
              bottom: 80,
              right: 16,
              child: _buildScrollToBottomButton(),
            ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leadingWidth: 50,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () {
          // Navigate to user profile
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Publicprofile(userId: widget.friend['id']),
            ),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.friend["avatar"]),
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.friend["name"],
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Online",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Colors.black87, size: 22),
          onPressed: () async {
            // Start audio call using LiveKit
            await _startCall(isVideo: false);
          },
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Colors.black87, size: 24),
          onPressed: () async {
            // Start video call using LiveKit
            await _startCall(isVideo: true);
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onPressed: () {
            // Show chat options
            _showChatOptions();
          },
        ),
      ],
    );
  }

  Widget _buildMessages(String myId) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start the conversation!',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        final prev = i > 0 ? messages[i - 1] : null;
        final next = i < messages.length - 1 ? messages[i + 1] : null;

        final isMe = msg["sender"] == myId;
        final isSelected = selectedMessage != null && selectedMessage!["id"] == msg["id"];

        final currentDate = DateTime.parse(msg["created_at"]).toLocal();
        final prevDate = prev != null ? DateTime.parse(prev["created_at"]).toLocal() : null;
        final nextDate = next != null ? DateTime.parse(next["created_at"]).toLocal() : null;

        final showDateSeparator = _shouldShowDateSeparator(prevDate, currentDate);
        
        // Show avatar if next message is from different sender or different day
        final showAvatar = next == null ||
            next["sender"] != msg["sender"] ||
            _shouldShowDateSeparator(currentDate, nextDate!);

        // Add spacing if messages are from same sender within same minute
        final showCompactSpacing = prev != null &&
            prev["sender"] == msg["sender"] &&
            !showDateSeparator &&
            currentDate.difference(prevDate!).inMinutes < 1;

        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(currentDate),
            GestureDetector(
              onLongPress: () {
                setState(() => selectedMessage = msg);
                _showMessageMenu(context, msg, isMe);
              },
              onHorizontalDragEnd: (details) {
                if (!isMe && details.primaryVelocity! > 150) {
                  setState(() => replyTo = msg);
                  focusNode.requestFocus();
                }
                if (isMe && details.primaryVelocity! < -150) {
                  setState(() => replyTo = msg);
                  focusNode.requestFocus();
                }
              },
              child: Container(
                color: isSelected ? Colors.black.withOpacity(0.05) : Colors.transparent,
                padding: EdgeInsets.only(
                  top: showCompactSpacing ? 2 : 4,
                  bottom: showAvatar ? 8 : 2,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isMe && showAvatar)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(widget.friend["avatar"]),
                          backgroundColor: Colors.grey[300],
                        ),
                      )
                    else if (!isMe)
                      const SizedBox(width: 36),
                    
                    Flexible(
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (msg["reply_to"] != null)
                            _buildReplyPreviewInsideBubble(msg["reply_to"], isMe),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFF2A2A2A) : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe || !showAvatar
                                    ? const Radius.circular(16)
                                    : const Radius.circular(4),
                                bottomRight: isMe && showAvatar
                                    ? const Radius.circular(4)
                                    : const Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              msg["message"],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                height: 1.4,
                                color: isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (showAvatar)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                              child: Text(
                                _formatTime(msg["created_at"]),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.black38,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReplyPreviewInsideBubble(String replyId, bool isMe) {
    final replyMsg = messages
        .cast<Map<String, dynamic>>()
        .firstWhereOrNull((m) => m['id'] == replyId);

    if (replyMsg == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[500],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Message deleted',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? Colors.black.withOpacity(0.2) : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 25,
            decoration: BoxDecoration(
              color: isMe ? Colors.white : Colors.black87,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              replyMsg["message"],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: scrollToBottom,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.arrow_downward, color: Colors.black87, size: 24),
              if (_unreadCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String text,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 10),
            Text(text, style: GoogleFonts.poppins(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: const Color.fromARGB(255, 243, 243, 243),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyTo != null) _buildReplyPreview(),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined,
                    color: Colors.black54),
                onPressed: () {
                  // TODO: Implement emoji picker
                },
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: TextField(
                    controller: controller,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Start typing...",
                      hintStyle: GoogleFonts.poppins(color: Colors.black38),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => send(),
                    maxLines: null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.black,
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded,
                      color: Colors.white, size: 18),
                  onPressed: send,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (replyTo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 25,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              replyTo!["message"],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() => replyTo = null);
            },
          ),
        ],
      ),
    );
  }
}