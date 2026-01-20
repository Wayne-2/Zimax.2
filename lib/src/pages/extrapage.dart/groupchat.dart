// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/models/gcmodel.dart';
import 'package:zimax/src/services/riverpod.dart';

class Groupchat extends ConsumerStatefulWidget {
  final String communityId;
  final String communityname;
  final String? communitypfp;

  const Groupchat({
    super.key,
    required this.communityId,
    required this.communityname,
    this.communitypfp,
  });

  @override
  ConsumerState<Groupchat> createState() => _GroupchatState();
}

class _GroupchatState extends ConsumerState<Groupchat> {
  final TextEditingController msgController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  
  bool _isAtBottom = true;
  bool _showScrollToBottom = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
    focusNode.addListener(_focusListener);
    
    // Mark as opened when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityChatProvider(widget.communityId).notifier).markChatOpened();
    });
  }

  void _scrollListener() {
    if (!scrollController.hasClients) return;
    
    final isAtBottom = scrollController.position.pixels >= 
        scrollController.position.maxScrollExtent - 100;
    
    if (_isAtBottom != isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
        _showScrollToBottom = !isAtBottom;
        if (isAtBottom) _unreadCount = 0;
      });
    }
  }

  void _focusListener() {
    if (focusNode.hasFocus) {
      // Update typing status
      ref.read(communityChatProvider(widget.communityId).notifier)
          .setTypingStatus(true);
    } else {
      ref.read(communityChatProvider(widget.communityId).notifier)
          .setTypingStatus(false);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!scrollController.hasClients) return;
    
    if (animate) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
    
    setState(() {
      _unreadCount = 0;
      _showScrollToBottom = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(communityChatProvider(widget.communityId));
    final notifier = ref.read(communityChatProvider(widget.communityId).notifier);
    final myId = Supabase.instance.client.auth.currentUser!.id;

    // Auto-scroll only for new messages from current user
    ref.listen(communityChatProvider(widget.communityId), (previous, next) {
      if (previous != null && next.messages.length > previous.messages.length) {
        final lastMsg = next.messages.last;
        if (lastMsg.senderId == myId) {
          // Always scroll for own messages
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollToBottom();
          });
        } else if (_isAtBottom) {
          // Scroll for others' messages only if already at bottom
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollToBottom();
          });
        } else {
          // Show unread count
          setState(() {
            _unreadCount++;
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xfff3f3f3),
      appBar: _buildAppBar(chatState.typingUsers),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  itemCount: chatState.messages.length,
                  itemBuilder: (_, i) {
                    final msg = chatState.messages[i];
                    final prev = i > 0 ? chatState.messages[i - 1] : null;
                    final next = i < chatState.messages.length - 1 
                        ? chatState.messages[i + 1] 
                        : null;

                    final isMe = msg.senderId == myId;
                    final showHeader = prev == null || 
                        prev.senderId != msg.senderId ||
                        _shouldShowDateSeparator(prev.createdAt, msg.createdAt);
                    final showAvatar = next == null || 
                        next.senderId != msg.senderId ||
                        _shouldShowDateSeparator(msg.createdAt, next.createdAt);
                    
                    final showDateSeparator = prev == null || 
                        _shouldShowDateSeparator(prev.createdAt, msg.createdAt);

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _buildDateSeparator(msg.createdAt),
                        _messageBubble(
                          msg: msg,
                          isMe: isMe,
                          showHeader: showHeader,
                          showAvatar: showAvatar,
                        ),
                      ],
                    );
                  },
                ),
              ),
              _buildInputBar(notifier),
            ],
          ),
          
          // Scroll to bottom button with unread count
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

  AppBar _buildAppBar(List<String> typingUsers) {
    final typingText = _getTypingText(typingUsers);
    
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: const BackButton(color: Colors.black),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: widget.communitypfp != null
                ? NetworkImage(widget.communitypfp!)
                : null,
            backgroundColor: Colors.grey[300],
            child: widget.communitypfp == null
                ? const Icon(Icons.group, color: Colors.black54, size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.communityname,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (typingText != null)
                  Text(
                    typingText,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.green[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Colors.black87),
          onPressed: () {
            // Navigate to live class
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDateSeparator(date),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _messageBubble({
    required CommunityMessage msg,
    required bool isMe,
    required bool showHeader,
    required bool showAvatar,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 40 : 0,
        right: isMe ? 0 : 40,
        bottom: showAvatar ? 8 : 2,
        top: showHeader && !isMe ? 8 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 2),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: _getColorFromName(msg.senderName),
                child: Text(
                  msg.senderName[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else if (!isMe)
            const SizedBox(width: 36),
          
          Flexible(
            child: Column(
              crossAxisAlignment: isMe 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                if (showHeader && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      msg.senderName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _getColorFromName(msg.senderName),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.black87
                        : Colors.white,
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
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.content,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isMe ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    _formatTime(msg.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.black38,
                    ),
                  ),
                ),
              ],
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
        onTap: _scrollToBottom,
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

  Widget _buildInputBar(CommunityChatNotifier notifier) {
    final user = ref.watch(userProfileProvider)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.black54),
                onPressed: () {
                  // Show attachment options
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: msgController,
                    focusNode: focusNode,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Message',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.black38,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                  onPressed: () async {
                    final text = msgController.text.trim();
                    if (text.isEmpty) return;

                    msgController.clear();
                    notifier.setTypingStatus(false);

                    await notifier.sendMessage(
                      content: text,
                      senderName: user.fullname,
                    );
                  },
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowDateSeparator(DateTime prev, DateTime current) {
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
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }

  String? _getTypingText(List<String> typingUsers) {
    if (typingUsers.isEmpty) return null;
    if (typingUsers.length == 1) {
      return '${typingUsers[0]} is typing...';
    } else if (typingUsers.length == 2) {
      return '${typingUsers[0]} and ${typingUsers[1]} are typing...';
    } else {
      return '${typingUsers.length} people are typing...';
    }
  }

  Color _getColorFromName(String name) {
    final colors = [
      const Color(0xFF1976D2),
      const Color(0xFF388E3C),
      const Color(0xFFD32F2F),
      const Color(0xFF7B1FA2),
      const Color(0xFFF57C00),
      const Color(0xFF0097A7),
      const Color(0xFFC2185B),
      const Color(0xFF5D4037),
    ];
    
    final hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }

  @override
  void dispose() {
    msgController.dispose();
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    focusNode.removeListener(_focusListener);
    focusNode.dispose();
    
    // Stop typing when leaving
    ref.read(communityChatProvider(widget.communityId).notifier)
        .setTypingStatus(false);
    
    super.dispose();
  }
}

// ============================================================================
// IMPROVED PROVIDER WITH TYPING INDICATORS AND PROPER STATE
// ============================================================================



