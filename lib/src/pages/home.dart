// ignore_for_file: avoid_print

import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zimax/src/appbar/profile.dart';
import 'package:zimax/src/components/appdrawer.dart';
import 'package:zimax/src/components/post_card.dart';
import 'package:zimax/src/components/videotiles.dart';
import 'package:zimax/src/services/riverpod.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  final Random _random = Random();
  Set<int> _videoIndices = {};

  @override
  void initState() {
    super.initState();
    handleInitialMessage();
  }

  void handleInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print("Opened From TERMINATED by tapping notification");
    }
  }

  Set<int> _generateVideoIndices(int totalPosts) {
    final indices = <int>{};
    int nextIndex = _random.nextInt(6) + 5; // Start between 5-10

    while (nextIndex < totalPosts) {
      indices.add(nextIndex);
      nextIndex += _random.nextInt(6) + 5; // Next appearance in 5-10 posts
    }

    return indices;
  }

  Future<void> _onRefresh() async {
    ref.invalidate(zimaxHomePostsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(zimaxHomePostsProvider);
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        title: Text(
          'Zimax',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Profilepage()),
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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.black,
        child: postsAsync.when(
          loading: () => ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (_, _) => postShimmer(),
          ),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Text(
                    "Error: $err",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
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

            // Generate random indices when posts load
            _videoIndices = _generateVideoIndices(posts.length);

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final postCard = PostCard(
                  id: post.userId,
                  postId: post.id,
                  username: post.username,
                  pfp: post.pfp,
                  department: post.department,
                  status: post.status,
                  imageUrl: post.mediaUrl,
                  postcontent: post.content ?? '',
                  like: post.likes.toString(),
                  initialLiked: post.liked,
                  comment: post.comments.toString(),
                  poll: post.polls.toString(),
                  repost: post.reposts.toString(),
                  createdAt: post.createdAt,
                  level: post.level,
                  title: post.title,
                  postedTo: post.postedTo,
                );

                // Show video tiles at random intervals (5-10 posts)
                if (_videoIndices.contains(index)) {
                  return Column(
                    children: [
                      postCard,
                      const SizedBox(height: 10),
                      VideoTileRow(
                        videoThumbnails: [
                          "https://picsum.photos/400/600",
                          "https://picsum.photos/401/600",
                          "https://picsum.photos/402/600",
                          "https://picsum.photos/403/600",
                          "https://picsum.photos/404/600",
                          "https://picsum.photos/405/600",
                        ],
                      ),
                    ],
                  );
                }

                return postCard;
              },
            );
          },
        ),
      ),
    );
  }
}

Widget postShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 160,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            width: double.infinity,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 12,
            color: Colors.white,
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            height: 12,
            color: Colors.white,
          ),
          const SizedBox(height: 6),
          Container(
            width: 200,
            height: 12,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconShimmer(),
              _iconShimmer(),
              _iconShimmer(),
              _iconShimmer(),
              _iconShimmer(),
              _iconShimmer(),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _iconShimmer() {
  return Container(
    width: 24,
    height: 24,
    color: Colors.white,
  );
}