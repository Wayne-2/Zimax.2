import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zimax/src/components/post_card.dart';
import 'package:zimax/src/services/riverpod.dart';

class BookmarkedPostsPage extends ConsumerStatefulWidget {
  const BookmarkedPostsPage({super.key});

  @override
  ConsumerState<BookmarkedPostsPage> createState() => _BookmarkedPostsPageState();
}

class _BookmarkedPostsPageState extends ConsumerState<BookmarkedPostsPage> {
  @override
  Widget build(BuildContext context) {
    final bookmarkedPosts = ref.watch(bookmarkedPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Posts"),
      ),
      body: bookmarkedPosts.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text("No saved posts"));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard.fromMediaPost(posts[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}
