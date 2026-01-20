import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zimax/src/services/riverpod.dart';

class ShareBottomSheet extends ConsumerStatefulWidget {
  const ShareBottomSheet({super.key});
  
  @override
  ConsumerState<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends ConsumerState<ShareBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userServiceStreamProvider);
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),

          /// Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(height: 14),

          /// Header
          Text(
            "Share",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          /// Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Icon(Icons.search, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    "Search",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          /// Recent users
          SizedBox(
            height: 90,
            child: usersAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  height: 90,
                  child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (_, _) => UserBubbleShimmer() 
                ),
                ),
              ),
              error: (e, _) => Center(
                child: Text("Error: $e", style: GoogleFonts.poppins()),
              ),
              data: (users) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: users.length > 10 ? 10 : users.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return _UserBubble(
                      username: users[index]['fullname']?? 'unknown user',
                      imageUrl:users[index]["profile_image_url"] ?? "https://kldaeoljhumowuegwjyq.supabase.co/storage/v1/object/public/media/zimaxpfp.png",
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          /// Share actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: const [
                _ShareAction(
                  icon: Icons.link,
                  title: "Copy link",
                ),
                _ShareAction(
                  icon: Icons.send,
                  title: "Share to story",
                ),
                _ShareAction(
                  icon: Icons.more_horiz,
                  title: "Share to…",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String username;
  final String imageUrl;

  const _UserBubble({
    required this.username,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(imageUrl),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1)
                ),
                child: const Icon(
                  Icons.arrow_upward,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 54,
          child: Center(
            child: Text(
              username,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShareAction extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ShareAction({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserBubbleShimmer extends StatelessWidget {
  const UserBubbleShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade900,
          highlightColor: Colors.grey.shade800,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white10,
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade900,
          highlightColor: Colors.grey.shade800,
          child: Container(
            width: 48,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}