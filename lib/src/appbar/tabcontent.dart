import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zimax/src/components/post_card.dart';
import 'package:zimax/src/services/riverpod.dart';

class PostsTab extends ConsumerStatefulWidget {
  final String userId;
  const PostsTab({super.key, required this.userId});

  @override
  ConsumerState<PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends ConsumerState<PostsTab> {
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
                    Text(
                      post.content ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        letterSpacing: -0.1,
                      ),
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

                  // Actions Row - smart spacing
                  SizedBox(height: hasContent || hasImage ? 12 : 4),

                  // Actions Row
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

class CommentsTab extends StatelessWidget {
  const CommentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No Comments yet',
        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400),
      ),
    );
  }
}

class BookmarkedTab extends StatelessWidget {
  final String userId;
  const BookmarkedTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No bookmarks yet',
        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400),
      ),
    );
  }
}

class MediaTab extends ConsumerStatefulWidget {
  final String userId;
  const MediaTab({super.key, required this.userId});

  @override
  ConsumerState<MediaTab> createState() => _MediaTabState();
}

class _MediaTabState extends ConsumerState<MediaTab> {
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
      loading: () => _buildShimmerGrid(),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 2),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        return _buildAnimatedShimmer();
      },
    );
  }

  Widget _buildAnimatedShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0),
        ),
      ),
    );
  }
}