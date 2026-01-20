// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/auth/loadingpage.dart';

class Uploadpfp extends StatefulWidget {
  const Uploadpfp({super.key});

  @override
  State<Uploadpfp> createState() => _UploadpfpState();
}

class _UploadpfpState extends State<Uploadpfp> {
  File? _selectedImage;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();
  final supabase = Supabase.instance.client;

  // Pick Image
  Future<void> pickImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (file != null) {
      setState(() => _selectedImage = File(file.path));
    }
  }

  // Upload + update DB
  Future<void> uploadImage() async {
    if (_selectedImage == null) {
      _showAlert("No Image", "Please select an image first.");
      return;
    }

    setState(() => _isUploading = true);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final fileName =
        "profile/${user.id}/${DateTime.now().millisecondsSinceEpoch}.png";

    try {
      // Upload file
      await supabase.storage.from("avatar").upload(fileName, _selectedImage!);

      // Get public URL
      final imageUrl = supabase.storage.from("avatar").getPublicUrl(fileName);

      // Update profile table
      await supabase
          .from("user_profile")
          .update({"profile_image_url": imageUrl})
          .eq("id", user.id);

      _showSuccessInfo("Success", "Profile photo updated successfully!");
    } catch (error) {
      _showAlert("Error", "Failed to upload image: $error");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        content: Text(
          msg,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessInfo(String title, String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        content: Text(
          msg,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Loadingpage()),
              );
            },

            child: Text(
              "OK",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: Colors.black,
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Back",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              Center(
                child: Text(
                  "Update Profile Photo",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Profile Photo
              Center(
                child: GestureDetector(
                  onTap: pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 135,
                        height: 135,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: _selectedImage == null
                            ? Image.asset(
                                "assets/nopfp.png",
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _selectedImage!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    "Tap to edit profile photo",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: _isUploading ? null : uploadImage,
                child: Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isUploading
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: LoadingAnimationWidget.staggeredDotsWave(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              size: 30,
                            ),
                          )
                        : Text(
                            'Finish',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
