import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/models/chatitem.dart';
import 'package:zimax/src/services/riverpod.dart';

class AddChatPage extends ConsumerStatefulWidget {
  const AddChatPage({super.key});

  @override
  ConsumerState<AddChatPage> createState() => _AddChatPageState();
}

class _AddChatPageState extends ConsumerState<AddChatPage> {
  final TextEditingController _searchController = TextEditingController();
  String query = "";
  Timer? _debounce;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Debounced search for better UX
  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => query = value.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userServiceStreamProvider);
    final myUser = supabase.auth.currentUser;
    final myId = myUser?.id;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.chevron_left, size: 22, color: Colors.black),
        ),
        title: Text(
          "New Conversations",
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildHeader("Available on Zimax"),
          const SizedBox(height: 6),
          Expanded(
            child: usersAsync.when(
              loading: () => _buildShimmerList(),
              error: (e, _) => Center(
                child: Text("Error: $e", style: GoogleFonts.poppins()),
              ),
              data: (users) {
                // Filter out current user and users without IDs
                final filtered = users
                    .where((u) => u["id"] != null && u["id"] != myId)
                    .toList();

                // Apply search query
                final searched = filtered.where((u) {
                  final name = (u["fullname"] ?? "").toString().toLowerCase();
                  final email = (u["email"] ?? "").toString().toLowerCase();
                  return name.contains(query) || email.contains(query);
                }).toList();

                if (searched.isEmpty) {
                  return Center(
                    child: Text(
                      "No users found",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: searched.length,
                  itemBuilder: (context, index) {
                    final user = searched[index];
                    return _buildUserTile(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.grey.shade200,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Search users",
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(Icons.manage_search_sharp),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );

  Widget _buildUserTile(Map user) {
    final createdAt = user["created_at"]?.toString();
    String readableDate = "Unknown";
    if (createdAt != null) {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) readableDate = DateFormat("d MMM yyyy").format(dt);
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: (user["profile_image_url"] != null &&
                (user["profile_image_url"] as String).isNotEmpty)
            ? NetworkImage(user["profile_image_url"])
            : const NetworkImage("https://i.pravatar.cc/150?img=3"),
      ),
      title: Row(
        children: [
          Text(
            user["fullname"] ?? "Unknown User",
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          _buildStatusIcon(user["status"] ?? ""),
          const SizedBox(width: 4),
          const Icon(Icons.circle, size: 4, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            "Joined $readableDate",
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(

              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      subtitle: Text(
        user["email"] ?? "No email",
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.black45,
        ),
      ),
      onTap: () {
        final chatItem = ChatItem(
          name: user["fullname"] ?? "Unknown User",
          preview: "Start a conversation",
          avatar: user["profile_image_url"] ?? "",
          userId: user["id"] ?? '',
          time: "now",
          verified: user["status"] == "verified",
          online: user["status"] == "online",
        );

        Navigator.pop(context, chatItem);
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (_, _) => shimmerTile(),
    );
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
}

Widget shimmerTile() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 160,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
