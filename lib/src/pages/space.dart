// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/models/communitymodel.dart';
import 'package:zimax/src/pages/extrapage.dart/community.dart';
import 'package:zimax/src/pages/extrapage.dart/createcommunity.dart';
import 'package:zimax/src/services/riverpod.dart';
import 'package:zimax/src/components/publicprofile.dart';

class Space extends ConsumerStatefulWidget {
  const Space({super.key});

  @override
  ConsumerState<Space> createState() => _SpaceState();
}

class _SpaceState extends ConsumerState<Space> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    // Example communities
    final communitiesAsync = ref.watch(recentCommunitiesProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 2,
        backgroundColor: Colors.white,
        title: Text(
          'Zimax Space',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: user!.pfp,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: 80,
            ), // leave space for bottom button
            child: Column(
              children: [
                const SizedBox(height: 10),
                _searchBar(),
                Expanded(
                  child: communitiesAsync.when(
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: 6, // Number of shimmer cards to show
                      itemBuilder: (context, index) => communityCardShimmer(),
                    ),
                    error: (e, _) => Center(child: Text(e.toString())),
                    data: (communities) {
                      if (communities.isEmpty) {
                        return Center(
                          child: Text(
                            "No communities yet",
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: communities.length,
                        itemBuilder: (context, index) =>
                            _communityCard(communities[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Create Community Button at the bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateCommunity()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      "Create Community",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search Zimax Space',
          hintStyle: GoogleFonts.poppins(fontSize: 13),
          prefixIcon: const Icon(Icons.manage_search_sharp),
        ),
      ),
    ),
  );

  Widget _communityCard(CommunityModel community) {
    final supabase = Supabase.instance.client;
    final isJoinedAsync = ref.watch(isJoinedProvider(community.id));
    final hasLiveSessionAsync = ref.watch(hasActiveLiveSessionProvider(community.id));
    final user = ref.watch(userProfileProvider);
    final username = user!.fullname;

    return isJoinedAsync.when(
      data: (joined) => GestureDetector(
        onTap: () async {
          if (joined) {
            // Already joined → navigate
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Community(communityId: community.id),
              ),
            );
          } else {
            // Not joined → join first
            final res = await supabase.from('community_members').insert({
              'community_id': community.id,
              'user_id': supabase.auth.currentUser!.id,
              'joined_at': DateTime.now().toIso8601String(),
            });

            print(res); // check for errors

            // Refresh providers
            ref.invalidate(isJoinedProvider(community.id));
            ref.invalidate(recentCommunitiesProvider);

            // Navigate after joining
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Community(communityId: community.id),
              ),
            );
          }
        },
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: community.avatarUrl != null
                              ? NetworkImage(community.avatarUrl!)
                              : const AssetImage('assets/community_placeholder.png')
                                    as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  community.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "${community.membersCount} members · ${community.isPrivate ? "Private" : "Public"}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Join button
                          ElevatedButton(
                            onPressed: () async {
                              if (!joined) {
                                final res = await supabase
                                    .from('community_members')
                                    .insert({
                                      'community_id': community.id,
                                      'user_id': supabase.auth.currentUser!.id,
                                      'user_name':username,
                                      'community_name':community.name,
                                      'joined_at': DateTime.now().toIso8601String(),
                                    });

                                print(res); // check for errors
                                ref.invalidate(isJoinedProvider(community.id));
                                ref.invalidate(recentCommunitiesProvider);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: joined
                                  ? Colors.grey.shade800
                                  : Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              joined ? "Joined" : "Join",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Live indicator badge
            hasLiveSessionAsync.when(
              data: (hasLive) {
                if (hasLive) {
                  return Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      loading: () => communityCardShimmer(),
      error: (e, _) => const SizedBox(),
    );
  }

  Widget communityCardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Container(width: 100, height: 12, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 60,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
