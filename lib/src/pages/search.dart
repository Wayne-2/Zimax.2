import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zimax/src/pages/extrapage.dart/placeholdersearchpage.dart';
import 'package:zimax/src/services/riverpod.dart';
import 'package:zimax/src/components/publicprofile.dart';

class Search extends ConsumerStatefulWidget {
  const Search({super.key});

  @override
  ConsumerState<Search> createState() => _SearchState();
}

class _SearchState extends ConsumerState<Search> {
  final supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();

  List recentSearches = [];
  List<Map<String, dynamic>> results = [];
  List<Map<String, dynamic>> userResults = [];
  bool loading = false;

Future<void> search(String query) async {
  final q = query.trim();

  if (q.isEmpty) {
    setState(() {
      results = [];
      userResults = [];
    });
    return;
  }

  setState(() => loading = true);

  try {

    final postsFuture = supabase
        .from('media_posts')
        .select()
        .or('title.ilike.%$q%,content.ilike.%$q%, media_url.ilike.%$q%')
        .order('created_at', ascending: false);

    final usersFuture = supabase
        .from('user_profile')
        .select()
        .or(
          'fullname.ilike.%$q%,email.ilike.%$q%,status.ilike.%$q%,profile_image_url.ilike.%$q%',
        )
        .order('created_at', ascending: false);

    final responses = await Future.wait([postsFuture, usersFuture]);

    setState(() {
      results = List<Map<String, dynamic>>.from(responses[0]);
      userResults = List<Map<String, dynamic>>.from(responses[1]);
    });
  } catch (e) {
    debugPrint("Search error: $e");

    setState(() {
      results = [];
      userResults = [];
    });
  } finally {
    setState(() => loading = false);
  }
}

  Future<void> saveSearch(String query) async {
    final cleaned = query.trim();

    // if (cleaned.length < 5) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    // check duplicate
    final existing = await supabase
        .from('recent_searches')
        .select()
        .eq('user_id', user.id)
        .eq('query', cleaned)
        .maybeSingle();

    if (existing != null) {
      // update timestamp
      await supabase
          .from('recent_searches')
          .update({'searched_at': DateTime.now().toIso8601String()})
          .eq('id', existing['id']);
    } else {
      // add new entry
      await supabase.from('recent_searches').insert({
        'user_id': user.id,
        'query': cleaned,
      });
    }

    // limit to 10
    final history = await supabase
        .from('recent_searches')
        .select('id')
        .eq('user_id', user.id)
        .order('searched_at', ascending: false);

    if (history.length > 10) {
      final idsToDelete = history.skip(10).map((e) => e['id']).toList();

      for (final id in idsToDelete) {
        await supabase.from('recent_searches').delete().eq('id', id);
      }
    }
    loadRecent();
  }

  Future<void> loadRecent() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => recentSearches = []);
      return;
    }

    final response = await supabase
        .from('recent_searches')
        .select()
        .eq('user_id', user.id)
        .order('searched_at', ascending: false);

    setState(() {
      recentSearches = List<Map<String, dynamic>>.from(response);
    });
  }

  void handleChipTap(String query) {
    searchController.text = query;
    search(query);
  }

  Future<void> handleChipDelete(String query) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('recent_searches')
        .delete()
        .eq('user_id', user.id)
        .eq('query', query);

    await loadRecent();
  }

  @override
  void initState() {
    super.initState();
    loadRecent();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final hasTyped = searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 40,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 235, 235, 235),
            borderRadius: BorderRadius.circular(50),
          ),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Search zimax",
              hintStyle: GoogleFonts.poppins(fontSize: 13),
              suffixIcon: GestureDetector(
                onTap: () {
                  final q = searchController.text.trim();
                  search(q);
                  saveSearch(q);
                },
                child: const Icon(Icons.manage_search_sharp),
              ),
            ),
            onChanged: (_) {
              final q = searchController.text.trim();
              search(q);
              setState(() {});
            },
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              // Navigate to current user profile
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
                placeholder: (_, _) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: SizedBox(width: 30, height: 30),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),

      body: Column(
        children: [
          if (!hasTyped)
            Expanded(child: Placeholdersearchpage())
          else if (loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (results.isEmpty)
            const Expanded(child: Center(child: Text("No results found")))
          else
     Expanded(
       child: ListView(
         padding: const EdgeInsets.only(bottom: 20),
         children: [

        if (results.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Posts",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          ...results.map((post) {
            return ListTile(
              leading: Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(image: (post["media_url"] != null &&
                            post["media_url"].isNotEmpty)
                        ? NetworkImage(post["media_url"])
                        : const NetworkImage("https://kldaeoljhumowuegwjyq.supabase.co/storage/v1/object/public/media/zimaxpfp.png"),
                        fit: BoxFit.cover)
                ),
              ),
              title: Text(post['title'] ?? "", 
                style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w500),),
              subtitle: Text(post['content'] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w400),),
            );
          }),
        ],

        const SizedBox(height: 10),

        if (userResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Users",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          ...userResults.map((profile) {
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: (profile["profile_image_url"] != null &&
                        profile["profile_image_url"].isNotEmpty)
                    ? NetworkImage(profile["profile_image_url"])
                    : const NetworkImage("https://i.pravatar.cc/150?img=3"),
              ),

              title: Row(
                children: [
                  Text(
                    profile["fullname"] ?? "Unknown User",
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  _buildStatusIcon(profile["status"] ?? ""),
                ],
              ),

              subtitle: Text(
                profile["email"] ?? "No email",
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.black45),
              ),
            );
          }),
        ],

        if (results.isEmpty && userResults.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text("No results found")),
          ),
      ],
    ),
  )]
,
      ),
    );
  }
}

  Icon _buildStatusIcon(String status) {
    switch (status) {
      case "Student":
        return const Icon(Icons.school, size: 18, color: Colors.blue);
      case "Academic Staff":
        return const Icon(Icons.star, size: 18, color: Colors.amber);
      case "Non-Academic Staff":
        return const Icon(Icons.work, size: 18, color: Colors.red);
      case "Admin":
        return const Icon(Icons.verified, size: 18, color: Colors.green);
      default:
        return const Icon(Icons.person, size: 18, color: Colors.grey);
    }
  }