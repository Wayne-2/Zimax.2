// ignore_for_file: use_build_context_synchronously, strict_top_level_inference, avoid_print

import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zimax/src/components/svgicon.dart';
import 'package:zimax/src/models/mediapost.dart';
import 'package:zimax/src/services/riverpod.dart';

class Posts extends ConsumerStatefulWidget {
  const Posts({super.key});

  @override
  ConsumerState<Posts> createState() => _PostsState();
}

class _PostsState extends ConsumerState<Posts> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final linkController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  final supabase = Supabase.instance.client;

  String postType = "text"; // text | media | link
  String? selectedCommunity;

  File? selectedImage;
  bool uploading = false;

  // Pick image
  Future<void> pickImage() async {
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (file != null) {
      setState(() => selectedImage = File(file.path));
    }
  }

  // Upload image and return public URL
  Future<String?> uploadImage() async {
    if (selectedImage == null) return null;

    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final path =
        "posts/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    try {
      setState(() => uploading = true);

      await supabase.storage.from("media").upload(path, selectedImage!);

      return supabase.storage.from("media").getPublicUrl(path);
    } catch (e) {
      showSnack("Upload failed: $e", isError: true);
      print(e);
      return null;
    } finally {
      setState(() => uploading = false);
    }
  }

  Future<void> createPost() async {

    final messenger = ScaffoldMessenger.of(context);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final profile = ref.read(userProfileProvider);

    showPostingSnack();

    final imageUrl = postType == "media" ? await uploadImage() : null;

    final post = MediaPost(
       id : Uuid().v4(),
      userId: user.id,
      pfp: profile?.pfp ?? "",
      username: profile?.fullname ?? "",
      department: profile?.department ?? "",
      level: profile?.level ?? "",
      status: profile?.status ?? "",
      title: titleController.text.trim(),
      content: bodyController.text.trim(),
      mediaUrl: imageUrl,
      likes: 0,
      comments: 0,
      polls: 0,
      reposts: 0,
      postedTo: selectedCommunity ?? "",
      createdAt: DateTime.now(), 
      liked: false,
    );

    try {
      await supabase.from("media_posts").insert(post.toJson());

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      showSnack("Post published");

      resetPostFields();
    } on PostgrestException catch (e) {
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade600,
        content: Text(
          "Database error: ${e.message}",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }
  on SocketException {
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade600,
        content: Text(
          "No internet connection",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  on TimeoutException {
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade600,
        content: Text(
          "Request timed out",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      showSnack("Insert failed: $e", isError: true);
      print(e);
    }
  }

  void showPostingSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 1),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Posting...",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void resetPostFields() {
    titleController.clear();
    bodyController.clear();
    linkController.clear();
    selectedImage = null;
    postType = "text";
    selectedCommunity = null;

    setState(() {}); // refresh UI
  }

  void showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: isError ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isError ? Colors.red.shade200 : Colors.green.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error : Icons.check_circle,
                color: isError ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isError ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final canPost = titleController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          "Zimax Post",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextButton(
              onPressed: canPost ? () => createPost() : null,
              style: TextButton.styleFrom(
                backgroundColor: canPost ? Colors.black : Colors.grey.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Post", style: GoogleFonts.poppins(fontSize: 13)),
            ),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _communitySelector(),
          const SizedBox(height: 16),

          _postTypeSelector(),
          const SizedBox(height: 20),

          _header(profile),
          const SizedBox(height: 16),

          _titleField(),
          const SizedBox(height: 10),

          if (postType == "text") _bodyField(),
          if (postType == "media") _mediaPicker(),
          if (postType == "link") _linkField(),
        ],
      ),
    );
  }

  // COMMUNITY SELECTOR
  Widget _communitySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          SvgIcon(
            "assets/icons/post_icon.svg",
            size: 18,
            color: Colors.black54,
          ),
          const SizedBox(width: 10),

          Expanded(
            child: DropdownButton<String>(
              value: selectedCommunity,
              underline: const SizedBox(),
              isExpanded: true,
              hint: Text(
                "Post to...",
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              items: ["Zimax home", "Story", "Spaces", "Groups"]
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        "@ $e",
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedCommunity = v),
            ),
          ),
        ],
      ),
    );
  }

  // POST TYPE CHIPS
  Widget _postTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip("text", "assets/icons/text.svg"),
        const SizedBox(width: 10),
        _chip("media", "assets/icons/media.svg"),
        const SizedBox(width: 10),
        _chip("link", "assets/icons/link.svg"),
      ],
    );
  }

  Widget _chip(String type, String icon) {
    final active = postType == type;

    return GestureDetector(
      onTap: () => setState(() => postType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SvgIcon(
              icon,
              size: 18,
              color: active ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              type[0].toUpperCase() + type.substring(1),
              style: GoogleFonts.poppins(
                color: active ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // USER HEADER
  Widget _header(profile) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CachedNetworkImage(
            imageUrl: profile?.pfp ?? "",
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            placeholder: (_, _) => Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(width: 40, height: 40, color: Colors.white),
            ),
            errorWidget: (_, _, _) => Container(
              width: 40,
              height: 40,
              color: Colors.grey.shade200,
              child: const Icon(Icons.person),
            ),
          ),
        ),
        const SizedBox(width: 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile?.fullname ?? "",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              profile?.email ?? "",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w300,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // TITLE FIELD
  Widget _titleField() {
    return TextField(
      controller: titleController,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: "Title",
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  // BODY FIELD
  Widget _bodyField() {
    return TextField(
      controller: bodyController,
      maxLines: 6,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        hintText: "Type a post...",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  // LINK FIELD
  Widget _linkField() {
    return TextField(
      controller: linkController,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        hintText: "Paste link",
        prefixIcon: const Icon(Icons.link),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // MEDIA PICKER UI
  Widget _mediaPicker() {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),

        child: selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  selectedImage!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 34,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Add photo",
                      style: GoogleFonts.poppins(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
