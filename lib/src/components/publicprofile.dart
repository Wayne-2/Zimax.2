import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zimax/src/components/post_card.dart';
import 'package:zimax/src/components/chatroom.dart';
import 'package:zimax/src/services/follow_service.dart';
import 'package:zimax/src/services/riverpod.dart';

class Publicprofile extends ConsumerStatefulWidget {
  final String userId;
  const Publicprofile({super.key, required this.userId});

  Future<void> followOrRequest(String targetId, bool isPrivate) async {
    final uid = Supabase.instance.client.auth.currentUser!.id;

    if (isPrivate) {
      await Supabase.instance.client.from('follow_requests').insert({
        'requester_id': uid,
        'target_id': targetId,
      });
    } else {
      await Supabase.instance.client.from('follows').insert({
        'follower_id': uid,
        'following_id': targetId,
      });
    }
  }

  Future<void> unfollowUser(String targetId) async {
    final uid = Supabase.instance.client.auth.currentUser!.id;

    await Supabase.instance.client
        .from('follows')
        .delete()
        .eq('follower_id', uid)
        .eq('following_id', targetId);
  }

  @override
  ConsumerState<Publicprofile> createState() => _PublicprofileState();
}

class _PublicprofileState extends ConsumerState<Publicprofile>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Move _getOrCreateRoom here
  Future<String> _getOrCreateRoom(String otherUserId) async {
    final supabase = Supabase.instance.client;
    try {
      final myId = supabase.auth.currentUser?.id;
      if (myId == null) throw Exception('User not authenticated');

      final existing = await supabase
          .from('chatrooms')
          .select('id')
          .or(
            'and(user1.eq.$myId,user2.eq.$otherUserId),and(user1.eq.$otherUserId,user2.eq.$myId)',
          )
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

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(
      publicUserProfileProvider(widget.userId),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: userProfileAsync.when(
          data: (user) => Text(
            user.fullname.toLowerCase().replaceAll(" ", "_"),
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          loading: () => const SizedBox(),
          error: (error, stackTrace) => const SizedBox(),
        ),
        centerTitle: true,
      ),
      body: userProfileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
        ),
        error: (error, stackTrace) => _ErrorState(),
        data: (user) => _ProfileView(
          user: user,
          tabController: _tabController,
          parentContext: context,
          getOrCreateRoom: _getOrCreateRoom, // Pass the function
        ),
      ),
    );
  }
}

class _ProfileView extends ConsumerStatefulWidget {
  final dynamic user;
  final TabController tabController;
  final BuildContext parentContext;
  final Future<String> Function(String) getOrCreateRoom; // Add this

  const _ProfileView({
    required this.user,
    required this.tabController,
    required this.parentContext,
    required this.getOrCreateRoom, // Add this
  });

  @override
  ConsumerState<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<_ProfileView> {
  void _showFollowersList(
    BuildContext context,
    String userId,
    String userName,
  ) {
    final supabase = Supabase.instance.client;

    showModalBottomSheet(
      context: context,
      builder: (_) => FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('follows')
            .select('follower_id, user_profile(*)')
            .eq('following_id', userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('Error loading followers: ${snapshot.error}'),
            );
          }

          final followers = snapshot.data ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Followers of $userName",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: followers.isEmpty
                    ? Center(
                        child: Text(
                          'No followers yet',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: followers.length,
                        itemBuilder: (context, index) {
                          final follower = followers[index];
                          final userData = follower['user_profile'] as List?;
                          final user = userData != null && userData.isNotEmpty
                              ? userData[0]
                              : null;

                          if (user == null) return const SizedBox();

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(user['pfp'] ?? ''),
                            ),
                            title: Text(user['fullname'] ?? 'Unknown'),
                            subtitle: Text(user['department'] ?? ''),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      Publicprofile(userId: user['id']),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFollowingList(
    BuildContext context,
    String userId,
    String userName,
  ) {
    final supabase = Supabase.instance.client;

    showModalBottomSheet(
      context: context,
      builder: (_) => FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('follows')
            .select('following_id, user_profile(*)')
            .eq('follower_id', userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('Error loading following: ${snapshot.error}'),
            );
          }

          final following = snapshot.data ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Following by $userName",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: following.isEmpty
                    ? Center(
                        child: Text(
                          'Not following anyone yet',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: following.length,
                        itemBuilder: (context, index) {
                          final followingData = following[index];
                          final userData =
                              followingData['user_profile'] as List?;
                          final user = userData != null && userData.isNotEmpty
                              ? userData[0]
                              : null;

                          if (user == null) return const SizedBox();

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(user['pfp'] ?? ''),
                            ),
                            title: Text(user['fullname'] ?? 'Unknown'),
                            subtitle: Text(user['department'] ?? ''),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      Publicprofile(userId: user['id']),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    Future openchat() async {
      try {
        final roomId = await widget.getOrCreateRoom(user.id);
        ref.read(chatPreviewProvider.notifier).markAsRead(roomId);
        if (mounted) {
          Navigator.push(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (_) => Chatroom(
                roomId: roomId,
                friend: {
                  "id": user.id, // FIXED
                  "name": user.fullname, // FIXED
                  "avatar": user.pfp, // FIXED
                },
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error opening chat: $e');
      }
    }

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Top Row: Avatar + Stats
                Row(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: NetworkImage(user.pfp),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Consumer(
                            builder: (BuildContext context, WidgetRef ref, Widget? child) { 
                                  final postsAsync = ref.watch(userPostsProvider(widget.user.id));

                                  return postsAsync.when(
                                    data: (count){
                                       if (count.isEmpty) {
                                        return Text('0');
                                      }
                                      final postcount = count.length.toString();
                                      return _ProfileStat(
                                        count: postcount,
                                        label: "Posts",
                                        onTap: null,
                                      );
                                     }, 
                                    error: (err, _)=> _ProfileStat(
                                      count: "0",
                                      label: "Posts",
                                      onTap: null,
                                    ), 
                                    loading: ()=> _ProfileStat(
                                      count: "0",
                                      label: "Posts",
                                      onTap: null,
                                    ),);
                             },
                            child: _ProfileStat(count: "0", label: "Posts", onTap: null)),
                          Consumer(
                            builder: (context, ref, _) {
                              final followCountsAsync = ref.watch(followCountsStreamProvider(user.id));

                              return followCountsAsync.when(
                                data: (counts) {
                                  final followers = counts['followers'] ?? 0;
                                  final following = counts['following'] ?? 0;

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _ProfileStat(
                                        count: "$followers",
                                        label: "Followers",
                                        onTap: () => _showFollowersList(
                                          context,
                                          user.id,
                                          user.fullname,
                                        ),
                                      ),
                                      SizedBox(width: 25,),
                                      _ProfileStat(
                                        count: "$following",
                                        label: "Following",
                                        onTap: () => _showFollowingList(
                                          context,
                                          user.id,
                                          user.fullname,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                loading: () => Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _ProfileStat(
                                      count: "0",
                                      label: "Followers",
                                      onTap: null,
                                    ),
                                    _ProfileStat(
                                      count: "0",
                                      label: "Following",
                                      onTap: null,
                                    ),
                                  ],
                                ),
                                error: (err, _) => Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _ProfileStat(count: "0", label: "Followers", onTap: null),
                                    _ProfileStat(count: "0", label: "Following", onTap: null),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Name and Bio
                Text(
                  user.fullname,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user.department,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.bio,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final currentUserId =
                              Supabase.instance.client.auth.currentUser!.id;

                          if (currentUserId == user.id) {
                            return const SizedBox();
                          }

                          final isFollowing = ref.watch(
                            followStatusStreamProvider(user.id),
                          );

                          final isRequested = ref.watch(
                            followRequestProvider(user.id),
                          );

                          return isFollowing.when(
                            loading: () => _ActionButton(
                              label: "Loading...",
                              onPressed: null,
                              isPrimary: true,
                            ),
                            error: (error, stackTrace) => _ActionButton(
                              label: "Error",
                              onPressed: null,
                              isPrimary: true,
                            ),
                            data: (following) {
                              if (following) {
                                return _ActionButton(
                                  label: "Following",
                                  isPrimary: false,
                                  onPressed: () async {
                                    try {
                                      await FollowService.unfollow(user.id);
                                      ref.invalidate(
                                        followStatusStreamProvider(user.id),
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Unfollowed successfully',
                                            ),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                );
                              }

                              return isRequested.when(
                                loading: () => _ActionButton(
                                  label: "Loading...",
                                  onPressed: null,
                                  isPrimary: true,
                                ),
                                error: (error, stackTrace) => _ActionButton(
                                  label: "Error",
                                  onPressed: null,
                                  isPrimary: true,
                                ),
                                data: (requested) => _ActionButton(
                                  label: requested ? "Requested" : "Follow",
                                  isPrimary: !requested,
                                  onPressed: requested
                                      ? null
                                      : () async {
                                          try {
                                            await FollowService.followOrRequest(
                                              user.id,
                                              user.isPrivate,
                                            );
                                            ref.invalidate(
                                              followStatusStreamProvider(
                                                user.id,
                                              ),
                                            );
                                            ref.invalidate(
                                              followRequestProvider(user.id),
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    user.isPrivate
                                                        ? 'Follow request sent'
                                                        : 'Followed successfully',
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 1,
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: "Chat user",
                        onPressed: openchat,
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverTabDelegate(widget.tabController),
        ),
      ],
      body: TabBarView(
        controller: widget.tabController,
        children: [
          _PostsTabs(userId: user.id),
          _CommentTab(userId: user.id),
          _ImageGrid(userId: user.id),
        ],
      ),
    );
  }
}

// Rest of the widgets remain the same...
class _ProfileStat extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback? onTap;

  const _ProfileStat({required this.count, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends ConsumerStatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  ConsumerState<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends ConsumerState<_ActionButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextButton(
        onPressed: widget.onPressed,
        style: TextButton.styleFrom(
          backgroundColor: widget.isPrimary
              ? Colors.black
              : Colors.grey.shade100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.isPrimary ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _PostsTabs extends ConsumerStatefulWidget {
  final String userId;
  const _PostsTabs({required this.userId});

  @override
  ConsumerState<_PostsTabs> createState() => _PostsTabsState();
}

class _PostsTabsState extends ConsumerState<_PostsTabs> {
  final Map<int, bool> _expandedStates = {}; // Track expanded state per post

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(userPostsProvider(widget.userId));
    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Text(
                    "No posts yet",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final isExpanded = _expandedStates[index] ?? false; // FIXED
            final readableDate = timeAgo(post.createdAt);
            final hasContent = (post.content?.trim().isNotEmpty ?? false);
            final hasImage = (post.mediaUrl?.trim().isNotEmpty ?? false);

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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(
                                imageUrl: post.pfp,
                                width: 35,
                                height: 35,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                      baseColor: Colors.grey.shade300,
                                      highlightColor: Colors.grey.shade100,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          post.username,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: Colors.black,
                                            letterSpacing: -0.2,
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
                    ],
                  ),

                  if (hasContent) ...[
                    const SizedBox(height: 4),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textPainter = TextPainter(
                          text: TextSpan(
                            text: post.content ?? '',
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
                              post.content ?? '',
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
                                    _expandedStates[index] =
                                        !isExpanded; // FIXED
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    isExpanded ? 'Read less' : 'Read more',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
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

                  // Post Image - with conditional spacing
                  if (hasImage) ...[
                    SizedBox(height: hasContent ? 12 : 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        height: 300,
                        width: double.infinity,
                        imageUrl: post.mediaUrl!,
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
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
      ),
      error: (error, stackTrace) =>
          const Center(child: Text('Error loading posts')),
    );
  }
}

class _CommentTab extends ConsumerStatefulWidget {
  final String userId;
  const _CommentTab({required this.userId});

  @override
  ConsumerState<_CommentTab> createState() => _CommentTabState();
}

class _CommentTabState extends ConsumerState<_CommentTab> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('No comments yet'));
  }
}

class _ImageGrid extends ConsumerStatefulWidget {
  final String userId;
  const _ImageGrid({required this.userId});

  @override
  ConsumerState<_ImageGrid> createState() => _ImageGridState();
}

class _ImageGridState extends ConsumerState<_ImageGrid> {
  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(userPostsProvider(widget.userId));

    return postsAsync.when(
      data: (posts) {
        final mediaPosts = posts
            .where((post) => post.mediaUrl != null)
            .toList();

        if (mediaPosts.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Text(
                    "No Media yet",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ),
            ],
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.only(top: 2),
          itemCount: mediaPosts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemBuilder: (context, index) {
            final post = mediaPosts[index];

            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(post.mediaUrl!, fit: BoxFit.cover),
                const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.collections_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      error: (_, __) => const Center(child: Text('Error loading posts')),
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
      ),
    );
  }
}

class _SliverTabDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  _SliverTabDelegate(this.controller);

  @override
  double get minExtent => 45;
  @override
  double get maxExtent => 45;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: TabBar(
        controller: controller,
        indicatorColor: Colors.black,
        indicatorWeight: 1.5,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey.shade400,
        tabs: [
          Tab(text: 'Posts'),
          Tab(text: 'Comments'),
          Tab(text: 'Media'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_) => false;
}

class _ErrorState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Profile unavailable',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Go Back"),
          ),
        ],
      ),
    );
  }
}
