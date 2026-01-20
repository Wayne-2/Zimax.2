import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/components/carousel.dart';
import 'package:zimax/src/components/post_card.dart';
// import 'package:zimax/src/pages/home.dart';
import 'package:zimax/src/services/riverpod.dart';

class Placeholdersearchpage extends ConsumerStatefulWidget {
  const Placeholdersearchpage({super.key});

  @override
  ConsumerState<Placeholdersearchpage> createState() =>
      _PlaceholdersearchpageState();
}

class _PlaceholdersearchpageState extends ConsumerState<Placeholdersearchpage> {
  List recent = [];

  Future<List<Map<String, dynamic>>> fetchRecentSearches() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return [];

    final response = await supabase
        .from('recent_searches')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  void initState() {
    super.initState();
    loadRecent();
  }

  Future<void> loadRecent() async {
    recent = await fetchRecentSearches();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(zimaxHomePostsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientCarousel(
            images: [
              "https://picsum.photos/400/250",
              "https://picsum.photos/401/250",
              "https://picsum.photos/402/250",
            ],
            titles: [
              "Welcome to Zimax",
              "Discover Trending Posts",
              "Engage With Your Community",
            ],
          ),

          // Recent Search Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Text(
              "Recent Search",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Recent Search Chips
          SizedBox(
            height: 32,
            child: recent.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      "No recent search",
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: recent.length,
                    itemBuilder: (_, index) {
                      final item = recent[index]['query'];
                      return Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 233, 233, 233),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            item,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 10),

          // Posts Section
          postsAsync.when(
            loading: () => Column(
              children: List.generate(4, (_) => shimmerPostItem(context)),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Error: $err",
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ),
            data: (posts) {
              if (posts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "No new update",
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                );
              }

              return Column(
                children: List.generate(4, (index) {
                  final post = posts[index];
                  final readableDate = timeAgo(post.createdAt);
                  return ListTile(
                    trailing: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl:
                            post.mediaUrl ??
                            "https://kldaeoljhumowuegwjyq.supabase.co/storage/v1/object/public/media/zimaxpfp.png",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,

                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade200,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      post.content ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: post.pfp,
                            width: 18,
                            height: 18,
                            fit: BoxFit.cover,

                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(35),
                                ),
                              ),
                            ),

                            errorWidget: (context, url, error) => Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.grey.shade200,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          readableDate,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget shimmerPostItem(BuildContext context) {
  return Shimmer.fromColors(
    baseColor: const Color.fromARGB(255, 223, 223, 223),
    highlightColor: Colors.grey.shade100,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: _box(),
                ),

                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.5,
                  decoration: _box(),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 10),
                    Container(
                      height: 12,
                      width: 70,
                      decoration: _box(radius: 3),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),
          Container(width: 80, height: 60, decoration: _box(radius: 8)),
        ],
      ),
    ),
  );
}

BoxDecoration _box({double radius = 6}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
);
