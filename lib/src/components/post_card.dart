// ignore_for_file: avoid_print

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/appbar/profile.dart';
import 'package:zimax/src/components/commentsheets.dart';
import 'package:zimax/src/components/dropdownmenu.dart';
import 'package:zimax/src/components/publicprofile.dart';
import 'package:zimax/src/components/repostingbutton.dart';
import 'package:zimax/src/components/sharebottomsheet.dart';
import 'package:zimax/src/components/svgicon.dart';

class PostCard extends StatefulWidget {
  final String id;
  final String username;
  final String department;
  final String status;
  final String pfp;
  final String postId;
  final String postcontent;
  final String? imageUrl;
  final String repost;
  final String like;
  final String comment;
  final String poll;
  final DateTime createdAt;
  final String level;
  final String? title;
  final String postedTo;
  final bool initialLiked;


  const PostCard({
    super.key,
    required this.id,
    required this.username,
    required this.department,
    required this.status,
    required this.pfp,
    required this.postId,
    required this.postcontent,
    required this.repost,
    required this.like,
    required this.comment,
    required this.poll,
    this.imageUrl,
    required this.createdAt,
    this.level = '',
    this.title,
    this.postedTo = '',
    required this.initialLiked,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isExpanded = false; 
  late bool isLiked;

  @override
  void initState() {
    super.initState();
    isLiked = widget.initialLiked;
  }


  void _openCommentsSheet(BuildContext context, String postId) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;
    print(widget.comment);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CommentSheet(postId: postId, userId: user.id);
      },
    );
  }

  void _openShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShareBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final readableDate = timeAgo(widget.createdAt);
    final hasContent = widget.postcontent.trim().isNotEmpty;
    final hasImage = widget.imageUrl != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final supabase = Supabase.instance.client;
                        final currentUser = supabase.auth.currentUser;

                        if (currentUser == null) return;

                        if (currentUser.id == widget.id) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Profilepage(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Publicprofile(userId: widget.id),
                            ),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: widget.pfp,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey.shade200,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.username,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.black,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              _buildStatusIcon(widget.status),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.department,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Icon(
                                  Icons.circle,
                                  size: 3,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                readableDate,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PostOptionsMenu(postId: widget.postId, userId: widget.id),
            ],
          ),

          // Post Content with Read More
          if (hasContent) ...[
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) {
                final textPainter = TextPainter(
                  text: TextSpan(
                    text: widget.postcontent,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      letterSpacing: -0.1,
                    ),
                  ),
                  maxLines: 3,
                  textDirection: TextDirection.ltr,
                )..layout(maxWidth: constraints.maxWidth);

                final isOverflowing = textPainter.didExceedMaxLines;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.postcontent,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        letterSpacing: -0.1,
                      ),
                      maxLines: isExpanded ? null : 3,
                      overflow: isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    if (isOverflowing)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            isExpanded ? 'Read less' : 'Read more',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],

          // Post Image
          if (hasImage) ...[
            SizedBox(height: hasContent ? 12 : 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                height: 300,
                width: double.infinity,
                imageUrl: widget.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
          ],

          SizedBox(height: hasContent || hasImage ? 12 : 4),

          // Actions Row
          Row(
            children: [
              _ActivIcon(
                icon: 'assets/activicon/comment.svg',
                count: widget.comment,
                onTap: () => _openCommentsSheet(context, widget.postId),
              ),
              const SizedBox(width: 24),
              RepostButton(
                count: widget.repost,
                postId: widget.postId,
                originalUserId: widget.id,
                originalUsername: widget.username,
                originalUserPfp: widget.pfp,
                originalDepartment: widget.department,
                originalStatus: widget.status,
                originalLevel: widget.level,
                originalTitle: widget.title ??
                    widget.postcontent.split('\n').first,
                originalContent: widget.postcontent,
                originalMediaUrl: widget.imageUrl,
                postedTo: widget.postedTo,
              ),
              const SizedBox(width: 24),
              LikeButton(
                postId: widget.postId,
                count: int.tryParse(widget.like) ?? 0,
                initialLiked: isLiked,
              ),
              const SizedBox(width: 24),
              _ActivIcon(
                icon: 'assets/activicon/activity.svg',
                count: widget.poll,
                onTap: () {},
              ),
              const Spacer(),
              const BookmarkButton(),
              const SizedBox(width: 16),
              _ActivIcon(
                icon: 'assets/activicon/share.svg',
                count: '',
                onTap: () => _openShareSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
Icon _buildStatusIcon(String status) {
  switch (status) {
    case "Student":
      return const Icon(Icons.school, size: 16, color: Color(0xFF2563EB));
    case "Academic Staff":
      return const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B));
    case "Non-Academic Staff":
      return const Icon(Icons.work, size: 16, color: Color(0xFFEF4444));
    case "Admin":
      return const Icon(Icons.verified, size: 16, color: Color(0xFF10B981));
    default:
      return const Icon(Icons.person, size: 16, color: Colors.grey);
  }
}

String timeAgo(DateTime createdAt) {
  final now = DateTime.now();
  final diff = now.difference(createdAt);

  if (diff.inSeconds < 60) {
    return "now";
  } else if (diff.inMinutes < 60) {
    return "${diff.inMinutes}m";
  } else if (diff.inHours < 24) {
    return "${diff.inHours}h";
  } else if (diff.inDays == 1) {
    return "1d";
  } else if (diff.inDays < 7) {
    return "${diff.inDays}d";
  } else if (diff.inDays < 30) {
    final weeks = (diff.inDays / 7).floor();
    return "${weeks}w";
  } else {
    final months = (diff.inDays / 30).floor();
    return "${months}mo";
  }
}

class _ActivIcon extends StatelessWidget {
  final String icon;
  final String count;
  final VoidCallback? onTap;

  const _ActivIcon({
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          SvgIcon(icon, color: Colors.grey.shade800, size: 20),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              count,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LikeButton extends StatefulWidget {
  final String postId;
  final int count;
  final bool initialLiked;

  const LikeButton({
    super.key,
    required this.postId,
    required this.count,
    this.initialLiked = false,
  });


  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late bool isLiked;
  late int likeCount;
  bool isLoading = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    isLiked = widget.initialLiked;
    likeCount = widget.count;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _controller.reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

Future<void> _toggleLike() async {
  if (isLoading) return;

  final user = supabase.auth.currentUser;
  if (user == null) return;

  setState(() {
    isLoading = true;
    isLiked = !isLiked;
    likeCount += isLiked ? 1 : -1;
  });

  _controller.forward();

  try {
    await supabase.rpc('toggle_media_post_like', params: {
      'p_media_post_id': widget.postId,
    });
  } catch (_) {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
  } finally {
    setState(() => isLoading = false);
  }
}



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleLike,
      child: Row(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: SvgIcon(
              isLiked
                  ? 'assets/activicon/like-filled.svg'
                  : 'assets/activicon/like.svg',
              color: isLiked
                  ? const Color(0xFFEF4444)
                  : Colors.grey.shade800,
              size: 20,
            ),
          ),
          if (likeCount > 0) ...[
            const SizedBox(width: 6),
            Text(
              likeCount.toString(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isLiked
                    ? const Color(0xFFEF4444)
                    : Colors.grey.shade700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class BookmarkButton extends StatefulWidget {
  const BookmarkButton({super.key});

  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton>
    with SingleTickerProviderStateMixin {
  bool isBookmarked = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _controller.reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleBookmark() {
    setState(() {
      isBookmarked = !isBookmarked;
    });
    _controller.forward();
    // TODO: Save bookmark state to backend if needed
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleBookmark,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SvgIcon(
          isBookmarked
              ? 'assets/activicon/bookmark-filled.svg'
              : 'assets/activicon/bookmark.svg',
          color: isBookmarked ? Colors.black : Colors.grey.shade800,
          size: 20,
        ),
      ),
    );
  }
}
