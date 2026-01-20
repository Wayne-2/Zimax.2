import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zimax/src/appbar/tabcontent.dart';
import 'package:zimax/src/pages/extrapage/edit_profile_page.dart';
import 'package:zimax/src/pages/extrapage/settings_page.dart';
import 'package:zimax/src/services/riverpod.dart';

class Profilepage extends ConsumerStatefulWidget {
  const Profilepage({super.key});

  @override
  ConsumerState<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends ConsumerState<Profilepage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final username = user!.fullname;
    final status = user.status;
    final department = user.department;
    final level = user.level;
    final joinIn = user.createdAt;
    // final followers = user.followerCount;
    // final following = user.followingCount;
    final readable = DateFormat('MMM yyyy').format(joinIn!);
    final memberSince = DateTime.now().difference(joinIn).inDays ~/ 30;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(user, readable, memberSince,),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ];
        },
        body: Column(
          children: [
            // Stats Card
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildStatsCard(
                  username,
                  status,
                  department,
                  level,
                  user.email,
                  user.bio,
                ),
              ),
            ),

            // Tabs
            Expanded(
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        indicatorColor: Colors.black,
                        indicatorWeight: 3,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        tabs: const [
                          Tab(text: "Posts"),
                          Tab(text: "Comments"),
                          Tab(text: "Media"),
                          Tab(text: "Saved"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          PostsTab(userId: user.id),
                          CommentsTab(),
                          MediaTab(userId: user.id,),
                          BookmarkedTab(userId: user.id,),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildHeader(dynamic user, String readable, int memberSince) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      // Gradient Background
      Container(
        width: double.infinity,
        height: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey.shade900,
              Colors.grey.shade800,
            ],
          ),
        ),
      ),

      // Background Pattern
      Positioned.fill(
        child: Opacity(
          opacity: 0.1,
          child: Image.asset('assets/bgimg1.png', fit: BoxFit.cover),
        ),
      ),

      // Blur overlay
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(color: Colors.black.withValues(alpha: 0.2)),
        ),
      ),

      // Decorative circles
      Positioned(
        top: -50,
        right: -50,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent],
            ),
          ),
        ),
      ),

      Positioned(
        bottom: -80,
        left: -80,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
            ),
          ),
        ),
      ),

      Positioned(
        bottom: 20,
        left: 0,
        right: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Profile picture
              Hero(
                tag: 'profile_${user.id}',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: CachedNetworkImage(
                      imageUrl: user.pfp,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: 100,
                          height: 100,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, size: 40),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Quick Stats - Consumer only here
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final followCountsAsync = ref.watch(followCountsStreamProvider(user.id));

                    return followCountsAsync.when(
                    data: (counts) {
                      final followers = counts['followers'] ?? 0;
                      final following = counts['following'] ?? 0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              _buildQuickStat('$followers', "Followers"),
                              const SizedBox(width: 20),
                              _buildQuickStat('$following', "Following"),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // ... rest of your code
                        ],
                      );
                    },
                    loading: () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            _buildQuickStat('0', "Followers", isLoading: true),
                            const SizedBox(width: 20),
                            _buildQuickStat('0', "Following", isLoading: true),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ... rest of your loading state UI
                      ],
                    ),
                    error: (err, _) => const SizedBox(
                      height: 60,
                      child: Center(child: Text("Failed to load", style: TextStyle(color: Colors.white70))),
                    ),
                  );
                  },
                ),
              ),

              // Edit Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      child: Text(
                        'Edit',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildQuickStat(String count, String label, {bool isLoading = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      isLoading
          ? Shimmer.fromColors(
              baseColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.5),
              direction: ShimmerDirection.ltr,
              child: Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )
          : Text(
              count,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
      const SizedBox(height: 2),
      Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    ],
  );
}

  Widget _buildStatsCard(
    String username,
    String status,
    String department,
    String level,
    String email,
    String bio,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                username,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              _getStatusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                email,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '$bio ',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color.fromARGB(255, 79, 79, 79),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.business_outlined, department, Colors.blue),
              _buildInfoChip(Icons.school_outlined, level, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case "Student":
        color = const Color(0xFF2563EB);
        icon = Icons.school;
        label = "Student";
        break;
      case "Academic Staff":
        color = const Color(0xFFF59E0B);
        icon = Icons.star;
        label = "Academic";
        break;
      case "Non-Academic Staff":
        color = const Color(0xFFEF4444);
        icon = Icons.work;
        label = "Staff";
        break;
      case "Admin":
        color = const Color(0xFF10B981);
        icon = Icons.verified;
        label = "Admin";
        break;
      default:
        color = Colors.grey;
        icon = Icons.person;
        label = "User";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


