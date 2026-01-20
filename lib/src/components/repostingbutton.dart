import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zimax/src/components/svgicon.dart';

class RepostButton extends StatefulWidget {
  final String count;
  final String postId;
  final String originalUserId;
  final String originalUsername;
  final String originalUserPfp;
  final String originalDepartment;
  final String originalStatus;
  final String originalLevel;
  final String originalTitle;
  final String? originalContent;
  final String? originalMediaUrl;
  final String postedTo;

  const RepostButton({
    super.key,
    required this.count,
    required this.postId,
    required this.originalUserId,
    required this.originalUsername,
    required this.originalUserPfp,
    required this.originalDepartment,
    required this.originalStatus,
    required this.originalLevel,
    required this.originalTitle,
    this.originalContent,
    this.originalMediaUrl,
    required this.postedTo,
  });

  @override
  State<RepostButton> createState() => _RepostButtonState();
}

class _RepostButtonState extends State<RepostButton>
    with SingleTickerProviderStateMixin {
  bool isReposted = false;
  bool isLoading = false;

  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _rotation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRepost() async {
    if (isLoading || isReposted) return;

    setState(() => isLoading = true);

    // 🔄 animate rotation
    _controller.forward(from: 0);

    // 🔔 show loading snackbar
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 1),
        content: _loadingSnack(),
      ),
    );

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get current user profile info
      final userProfile = await supabase
          .from('user_profile')
          .select('fullname, profile_image_url, department, status, level')
          .eq('id', currentUser.id)
          .single();

      // Create a repost as a new post with reference to original
      final repostId = const Uuid().v4();
      
      await supabase.from('media_posts').insert({
        'id': repostId,
        'user_id': currentUser.id,
        'username': userProfile['fullname'],
        'pfp': userProfile['profile_image_url'],
        'department': userProfile['department'],
        'status': userProfile['status'],
        'level': userProfile['level'],
        'title': 'Reposted: ${widget.originalTitle}',
        'content': widget.originalContent,
        'media_url': widget.originalMediaUrl,
        'posted_to': widget.postedTo,
        'likes': 0,
        'comments_count': 0,
        'polls': 0,
        'reposts': 0,
        'original_post_id': widget.postId,
        'original_user_id': widget.originalUserId,
        'original_username': widget.originalUsername,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Increment repost count on original post
      await supabase.rpc('increment_repost_count', params: {'post_id': widget.postId});

      messenger.hideCurrentSnackBar();

      setState(() {
        isReposted = true;
        isLoading = false;
      });

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Post reposted successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error reposting: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      setState(() => isLoading = false);
    }
  }

  Widget _loadingSnack() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 12),
          Text(
            "re-posting...",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleRepost,
      child: Row(
        children: [
          RotationTransition(
            turns: _rotation,
            child: SvgIcon(
              'assets/activicon/repost.svg',
              size: 18,
              color: isReposted
                  ? Colors.green
                  : const Color.fromARGB(255, 8, 10, 12),
            ),
          ),
          if (widget.count.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              widget.count,
              style: TextStyle(
                fontSize: 13,
                color: isReposted
                    ? Colors.green
                    : const Color.fromARGB(255, 7, 7, 8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
