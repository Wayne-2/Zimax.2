// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/components/svgicon.dart';
import 'package:zimax/src/components/publicprofile.dart';
import 'package:zimax/src/services/riverpod.dart';

class CommentSheet extends ConsumerStatefulWidget {
  final String postId;
  final String userId;


  const CommentSheet({
    super.key,
    required this.postId,
    required this.userId,
  });

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final supabase = Supabase.instance.client;
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  List<Map<String, dynamic>> comments = [];
  bool loading = true;
  bool sending = false;
  String? error;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    fetchComments();
    subscribeRealtime();
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  /// Fetch comments from Supabase with error handling
  Future<void> fetchComments() async {
    try {
      final data = await supabase
          .from('comment')
          .select(
            'comment, created_at, commenter_name, profile_image_url, user_id',
          )
          .eq('post_id', widget.postId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          comments = List<Map<String, dynamic>>.from(data);
          loading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
    }
  }

  /// Subscribe to realtime comments with proper channel management
  void subscribeRealtime() {
    _channel = supabase.channel('post_${widget.postId}');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'comment',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: widget.postId,
          ),
          callback: (payload) {
            // Add new comment optimistically without full refetch
            if (mounted) {
              final newComment = payload.newRecord;
              setState(() {
                comments.add(newComment);
              });
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'comment',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: widget.postId,
          ),
          callback: (payload) {
            // Remove deleted comment
            if (mounted) {
              fetchComments(); // Refetch to sync state
            }
          },
        )
        .subscribe();
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await supabase.from('comment').delete().eq('id', commentId);
      
      if (mounted) {
        // Remove from local list
        setState(() {
          comments.removeWhere((c) => c['id'] == commentId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> sendComment(String username, String userpfp) async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;

    // Hide keyboard
    focusNode.unfocus();

    setState(() => sending = true);

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      await supabase.from('comment').insert({
        'post_id': widget.postId,
        'user_id': user.id,
        'comment': text,
        'commenter_name': username,
        'profile_image_url': userpfp,
      });

      // Clear input immediately for better UX
      controller.clear();

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comment posted!'),
            backgroundColor: Colors.black,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to post: ${e.toString().split(':').last.trim()}',
            ),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: ()=> sendComment(username, userpfp),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  String _formatTimeAgo(String? createdAt) {
    if (createdAt == null) return '';

    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // final user = ref.watch(userProfileProvider);
    return DraggableScrollableSheet(
      expand: false,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      initialChildSize: 0.65,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Drag handle
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      "Comments",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!loading)
                      Text(
                        "(${comments.length})",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Comments list
              Expanded(child: _buildCommentsList(scrollController)),

              // Input field
              _buildCommentInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsList(ScrollController scrollController) {
    if (loading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => _commentShimmer(),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                "Failed to load comments",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    loading = true;
                    error = null;
                  });
                  fetchComments();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon('assets/activicon/comment.svg', color: Colors.grey.shade400, size: 64),
            const SizedBox(height: 16),
            Text(
              "No comments yet",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Be the first to comment!",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: comments.length,
      itemBuilder: (context, i) {
        final c = comments[i];
        final name = c['commenter_name'] ?? "Unknown";
        final pfp =
            c['profile_image_url'] ??
            'https://kldaeoljhumowuegwjyq.supabase.co/storage/v1/object/public/avatar/profile/aaa466ec-c0c3-48f6-9f30-e6110fbf4e4d/nopfp.png';
        final text = c['comment'] ?? '';
        final createdAt = c['created_at'];
        final isOwnComment = c['user_id'] == widget.userId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Publicprofile(userId: c['user_id']),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(pfp),
                  backgroundColor: Colors.grey.shade300,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Publicprofile(userId: c['user_id']),
                              ),
                            );
                          },
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isOwnComment) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "You",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color.fromARGB(255, 50, 50, 50),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          _formatTimeAgo(createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        if (isOwnComment)
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteComment(c['id']);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            icon: const Icon(Icons.more_horiz, size: 16),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(text, style: GoogleFonts.poppins(fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    final user = ref.watch(userProfileProvider);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(user!.pfp),
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Add a comment...",
                  hintStyle: GoogleFonts.poppins(fontSize: 14),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => sendComment(user.fullname, user.pfp),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: ()=> sending ? null : sendComment(user.fullname, user.pfp),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sending ? Colors.grey : Colors.black,
                ),
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commentShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 14,
                    width: MediaQuery.of(context).size.width * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
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
}
