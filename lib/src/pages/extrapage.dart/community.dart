// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/components/svgicon.dart';
import 'package:zimax/src/components/publicprofile.dart';
import 'package:zimax/src/models/postmodel.dart';
import 'package:zimax/src/pages/extrapage.dart/groupchat.dart';
import 'package:zimax/src/pages/extrapage.dart/live_lessons_page.dart';


class Community extends StatefulWidget {
  final String communityId;
  const Community({super.key, required this.communityId});

  @override
  State<Community> createState() => _CommunityState();
}

class _CommunityState extends State<Community> {
  bool joining = false;
  bool joined = false;
  bool loading = true;
  CommunityModel? community;
  int membersCount = 0;
  bool showAllMembers = false;
  List<String> memberNames = [];
  late Future<Map<String, dynamic>?> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _fetchCommunityData();
    _userProfileFuture = _getCurrentUserProfile();
  }

  Future<void> _fetchCommunityData() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    try {
      final communityRes = await supabase
          .from('communities')
          .select('*, community_rules(*)')
          .eq('id', widget.communityId)
          .single();

      final joinedRes = await supabase
          .from('community_members')
          .select()
          .eq('community_id', widget.communityId)
          .eq('user_id', userId)
          .maybeSingle();

      final membersRes = await supabase
          .from('community_members')
          .select('user_name')
          .eq('community_id', widget.communityId);



      setState(() {
        community = CommunityModel.fromMap(communityRes);
        joined = joinedRes != null;
        membersCount = (membersRes as List).length;
        memberNames =
            membersRes.map((e) => e['user_name'] as String).toList();
        loading = false;
      });

    } catch (e) {
      setState(() => loading = false);
      // ScaffoldMessenger.of(context)
      //     .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<Map<String, dynamic>?> _getCurrentUserProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) return null;
      
      final userProfile = await supabase
          .from('user_profile')
          .select('id, avatar')
          .eq('id', userId)
          .maybeSingle();
      
      return userProfile;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: loading
          ? CommunityShimmer()
          : CustomScrollView(
              slivers: [
                _collapsingBanner(),
                // SliverToBoxAdapter(child: _communityHeader()),
                SliverToBoxAdapter(child: _aboutSection()),
                SliverToBoxAdapter(child: _rulesSection()),
                SliverToBoxAdapter(child: _moderatorsBar()),
                SliverToBoxAdapter(child: _navigationTiles()),
              ],
            ),
    );
  }

  Widget _collapsingBanner() {
    const double expanded = 260;

    return SliverAppBar(
      expandedHeight: expanded,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _userProfileFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final userProfile = snapshot.data!;
                return GestureDetector(
                  onTap: () {
                    final userId = userProfile['id'] as String?;
                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Publicprofile(userId: userId),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                      userProfile['avatar'] as String? ?? 'https://via.placeholder.com/100',
                    ),
                    backgroundColor: Colors.grey[300],
                  ),
                );
              }
              return CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Compute collapse factor t: 1.0 (expanded) -> 0.0 (collapsed)
          final double maxH = expanded + MediaQuery.of(context).padding.top;
          final double minH =
              kToolbarHeight + MediaQuery.of(context).padding.top;
          final double currentH = constraints.biggest.height;
          final double t = ((currentH - minH) / (maxH - minH)).clamp(0.0, 1.0);

          final String banner =
              community?.bannerUrl ?? 'https://via.placeholder.com/1200x600';
          final String avatar =
              community?.avatarUrl ?? 'https://via.placeholder.com/300';
          final String name = community?.name ?? '';

          final Color titleColor =
              Color.lerp(Colors.black, Colors.white, t) ?? Colors.black;
          final double avatarSize = lerpDouble(
            32,
            68,
            t,
          )!; // grows when expanded
          final double titleSize = lerpDouble(16, 22, t)!;
          final double btnRadius = lerpDouble(8, 10, t)!;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background image with stretch/zoom and slight blur when over-stretched
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: banner,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.shade300),
                  errorWidget: (context, url, error) =>
                      Container(color: Colors.grey.shade200),
                ),
              ),

              // Blur effect when collapsed (scrolling), clears when expanded
              // Blur effect - strong when expanded (t=1), clears when collapsed (t=0)
          // if (t > 0.3)  // Only blur when 70%+ expanded
          //   Positioned.fill(
          //     child: BackdropFilter(
          //       filter: ImageFilter.blur(
          //         sigmaX: t * 8,
          //         sigmaY: t * 8,
          //       ),
          //       child: const SizedBox.expand(),
          //     ),
          //   ),
              // Gradient scrim for contrast
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.15 * t),
                        Colors.black.withValues(alpha: 0.35 * t),
                      ],
                      stops: const [0.2, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // Bottom divider only visible when collapsed
              Align(
                alignment: Alignment.bottomCenter,
                child: Opacity(
                  opacity: 1 - t,
                  child: Container(height: 1, color: Colors.grey.shade200),
                ),
              ),

              // Foreground content (avatar, title, button)
              Positioned(
                left: 12,
                right: 12,
                bottom: lerpDouble(
                  8,
                  16,
                  1 - t,
                )!, // slightly lower when collapsed
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar with smooth scaling and shadow - CLICKABLE
                    GestureDetector(
                      onTap: () {
                        // Navigate to community info or creator profile
                        // For now, just show a message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${community?.name} community'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25 * t),
                              blurRadius: 14 * t,
                              offset: Offset(0, 6 * t),
                            ),
                          ],
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(avatar),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title + members
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: titleSize,
                              color: titleColor,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Opacity(
                            opacity:
                                0.9 * t +
                                0.5 * (1 - t), // keep slightly visible
                            child: Text(
                              '$membersCount members',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Color.lerp(
                                  Colors.grey.shade700,
                                  Colors.white70,
                                  t,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(), // Push buttons to right

                    // Join/Leave buttons
                    if (!joined)
                      GestureDetector(
                        onTap: _toggleJoin,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              Colors.black,
                              Colors.white.withValues(alpha: 0.22),
                              t,
                            ),
                            borderRadius: BorderRadius.circular(btnRadius),
                            border: Border.all(
                              color: Color.lerp(
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.35),
                                t,
                              )!,
                            ),
                            boxShadow: [
                              if (t > 0.4)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15 * t),
                                  blurRadius: 12 * t,
                                  offset: Offset(0, 6 * t),
                                ),
                            ],
                          ),
                          child: joining
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Join',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Leave button (red) - on LEFT
                          GestureDetector(
                            onTap: _toggleJoin,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                  Colors.red.shade700,
                                  Colors.red.withValues(alpha: 0.7),
                                  t,
                                ),
                                borderRadius: BorderRadius.circular(btnRadius),
                                border: Border.all(
                                  color: Color.lerp(
                                    Colors.red.shade600,
                                    Colors.red.withValues(alpha: 0.5),
                                    t,
                                  )!,
                                ),
                                boxShadow: [
                                  if (t > 0.4)
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.2 * t),
                                      blurRadius: 12 * t,
                                      offset: Offset(0, 6 * t),
                                    ),
                                ],
                              ),
                              child: joining
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Leave',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Joined button (disabled, just for display)  - on RIGHT
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                const Color(0xFF2B2A2A),
                                Colors.white.withValues(alpha: 0.18),
                                t,
                              ),
                              borderRadius: BorderRadius.circular(btnRadius),
                              border: Border.all(
                                color: Color.lerp(
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.35),
                                  t,
                                )!,
                              ),
                              boxShadow: [
                                if (t > 0.4)
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15 * t),
                                    blurRadius: 12 * t,
                                    offset: Offset(0, 6 * t),
                                  ),
                              ],
                            ),
                            child: Text(
                              'Joined',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      // Native stretch behaviors (zoom/blur/fade title if you later use FlexibleSpaceBar)
      stretchTriggerOffset: 120,
      onStretchTrigger: () async {
        // Optional: refresh community data on pull-stretch
        // await _fetchCommunityData();
      },
    );
  }

  Widget _aboutSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About Community",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            community?.description ?? '',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _rulesSection() {
    final rules = community?.rules ?? [];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Community Rules",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          if (rules.isEmpty)
            Text("No rules yet", style: GoogleFonts.poppins(fontSize: 13)),
          ...rules.map((r) => _ruleTile(r.ruleText)),
        ],
      ),
    );
  }

  Widget _ruleTile(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(

        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.black87),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rule,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

Widget _moderatorsBar() {
  final visibleMembers =
      showAllMembers ? memberNames : memberNames.take(3).toList();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header
        Row(
          children: [
            Text(
              "Community Members",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                if (memberNames.length > 3) {
                  _showAllMembersModal(memberNames);
                } else {
                  setState(() {
                    showAllMembers = !showAllMembers;
                  });
                }
              },
              child: Text(
                memberNames.length > 3 ? "View all (${memberNames.length})" : "View less",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        /// Expandable list
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Column(
            children: [
              /// Members
              ...visibleMembers.map((name) => _memberTile(name)),

              ///  Fade hint (ONLY when collapsed & more members exist)
              if (!showAllMembers && memberNames.length > 3)
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white,
                      ],
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

Widget _memberTile(String name) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.black,
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}


  Widget _navigationTiles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          _navTile('assets/commicon/groupchat.svg', "Group Chat", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Groupchat(communityId: community!.id, communityname: community!.name, communitypfp: community!.avatarUrl,)),
            );
          }),
          const SizedBox(height: 12),
          _navTile('assets/commicon/stream.svg', "Live Sessions", () async {
          final supabase = Supabase.instance.client;
          final uid = supabase.auth.currentUser!.id;
          
          final userProfile = await supabase
              .from('user_profile')
              .select('id, fullname')
              .eq('id', uid)
              .maybeSingle();
          
         final memberData = await supabase
              .from('community_members')
              .select('role')
              .eq('user_id', uid)
              .limit(1)
              .maybeSingle();
          
          if (userProfile != null && memberData != null && memberData['role'] == 'lecturer') {
            await supabase.from('profiles').upsert({
              'id': userProfile['id'],
              'full_name': userProfile['fullname'],
              'role': 'lecturer', // must match DB constraint
            });
          } else {
            // user is not a lecturer, so do not allow profile creation for live lesson
            print('User is not a lecturer, cannot create live lesson');
          }

        


          final existingLesson = await supabase
              .from('lessons')
              .select()
              .eq('community_id', widget.communityId)
              .eq('is_live', true)
              .maybeSingle();

          String lessonId;

          if (existingLesson != null) {
      
            lessonId = existingLesson['id'];
          } else {
        
            final newLesson = await supabase
                .from('lessons')
                .insert({
                  'community_id': widget.communityId,
                  'lecturer_id': uid,
                  'is_live': true,
                })
                .select()
                .single();

            lessonId = newLesson['id'];
          }

  
          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveLessonPage(lessonId: lessonId),
            ),
          );
        }),


          const SizedBox(height: 12),
          _navTile('assets/commicon/locker.svg', "Media and assets", () {}),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _navTile(String icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          children: [
            SvgIcon(icon, color: Colors.black, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAllMembersModal(List<String> members) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Community Members (${members.length})',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.black,
                            child: Text(
                              members[index][0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              members[index],
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleJoin() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    if (joining) return;
    setState(() => joining = true);

    try {
      if (joined) {
        // User is already joined, remove them
        await supabase
            .from('community_members')
            .delete()
            .eq('community_id', widget.communityId)
            .eq('user_id', userId);

        setState(() {
          joined = false;
          membersCount--;
          memberNames.removeWhere((name) => name == 'You');
        });
      } else {
        // User is not joined, add them
        await supabase.from('community_members').insert({
          'community_id': widget.communityId,
          'user_id': userId,
          'joined_at': DateTime.now().toIso8601String(),
        });

        setState(() {
          joined = true;
          membersCount++;
          memberNames.insert(0, 'You');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => joined = !joined); // Revert state on error
    } finally {
      if (mounted) setState(() => joining = false);
    }
  }

}

class CommunityShimmer extends StatelessWidget {
  const CommunityShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: CustomScrollView(
        slivers: [
          _bannerShimmer(),
          SliverToBoxAdapter(child: _sectionShimmer()),
          SliverToBoxAdapter(child: _rulesShimmer()),
          SliverToBoxAdapter(child: _moderatorsShimmer()),
          SliverToBoxAdapter(child: _navTilesShimmer()),
        ],
      ),
    );
  }

  // ---------------- Banner ----------------
  static Widget _bannerShimmer() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      flexibleSpace: Container(
        color: Colors.grey.shade300,
        child: Stack(
          children: [
            Positioned(
              left: 16,
              bottom: 16,
              child: Row(
                children: [
                  _circle(68),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _line(width: 140, height: 18),
                      const SizedBox(height: 8),
                      _line(width: 90, height: 12),
                    ],
                  ),
                  const SizedBox(width: 20),
                  _pill(width: 64, height: 32),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ---------------- About ----------------
  static Widget _sectionShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(width: 140, height: 16),
          const SizedBox(height: 12),
          _line(width: double.infinity, height: 12),
          const SizedBox(height: 8),
          _line(width: double.infinity, height: 12),
          const SizedBox(height: 8),
          _line(width: 200, height: 12),
        ],
      ),
    );
  }

  // ---------------- Rules ----------------
  static Widget _rulesShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                _circle(8),
                const SizedBox(width: 10),
                Expanded(child: _line(height: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Moderators ----------------
  static Widget _moderatorsShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _line(width: 160, height: 14),
          const Spacer(),
          _line(width: 60, height: 12),
        ],
      ),
    );
  }

  // ---------------- Navigation ----------------
  static Widget _navTilesShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Helpers ----------------
  static Widget _line({
    double width = double.infinity,
    double height = 10,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  static Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget _pill({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
