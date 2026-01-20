// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/auth/uploadpfp.dart';
import 'package:zimax/src/components/inputfield.dart';
import 'package:zimax/src/models/userprofile.dart';
import 'package:zimax/src/services/supabase.dart';
import 'package:zimax/src/services/riverpod.dart';

class Relativeschoolinfo extends StatefulWidget {
  final String fullname;
  final String email;
  final String password;

  const Relativeschoolinfo({
    super.key,
    required this.email,
    required this.fullname,
    required this.password,
  });

  @override
  State<Relativeschoolinfo> createState() => _RelativeschoolinfoState();
}

class _RelativeschoolinfoState extends State<Relativeschoolinfo> {
  final _departmentController = TextEditingController();
  final _regNumberController = TextEditingController();

  String? selectedLevelValue;
  String? selectedStatusValue;

  bool _isLoading = false;

  final supabase = Supabase.instance.client;
  final profileService = UserProfileService();

Future<void> _saveProfile() async {
  if (_departmentController.text.isEmpty ||
      _regNumberController.text.isEmpty ||
      selectedLevelValue == null ||
      selectedStatusValue == null) {
    _showAlertDialog(
      context,
      title: "Missing Information",
      message: "Please fill in all fields before continuing.",
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Create account
    final response = await supabase.auth.signUp(
      email: widget.email.trim(),
      password: widget.password.trim(),
      data: {'fullname': widget.fullname.trim()},
    );

    // Auto sign in
    await supabase.auth.signInWithPassword(
      email: widget.email.trim(),
      password: widget.password.trim(),
    );

    if (selectedLevelValue == null || selectedStatusValue == null) {
      print("Please select level and status");
      return;
    }

    final user = response.user;

    if (user != null) {
      const String noimg =
          'https://kldaeoljhumowuegwjyq.supabase.co/storage/v1/object/public/avatar/profile/aaa466ec-c0c3-48f6-9f30-e6110fbf4e4d/nopfp.png';

      final profile = Userprofile(
        id: user.id,
        fullname: widget.fullname,
        email: widget.email,
        department: _departmentController.text.trim(),
        level: selectedLevelValue!,
        idNumber: _regNumberController.text.trim(),
        status: selectedStatusValue!,
        pfp: noimg, 
        bio: 'No bios available', 
        followerCount: 0, 
        followingCount: 0, 
        isPrivate: false,
        
      );

      await profileService.createProfile(profile);

      ProviderScope.containerOf(context)
          .read(userProfileProvider.notifier)
          .setUser(profile);
    }

    _showAlertDialog(
      context,
      title: "Success",
      message: "Your school information has been saved successfully!",
      confirmText: "Continue",
      onConfirm: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Uploadpfp()),
        );
      },
    );
  } catch (e) {
    final message = parseFriendlyError(e);
    _showAlertDialog(
      context,
      title: "Error",
      message: message,
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

String parseFriendlyError(dynamic error) {
  if (error is AuthException) {
    switch (error.code) {
      case 'user_already_exists':
        return "This email is already registered.";
      case 'invalid_email':
        return "Please enter a valid email address.";
      case 'weak_password':
        return "Your password is too weak. Try a stronger one.";
      case 'invalid_credentials':
        return "Incorrect email or password.";
      default:
        return error.message;
    }
  }

  if (error is PostgrestException) {
    return "A database error occurred. Please try again.";
  }

  if (error is SocketException) {
    return "No internet connection. Check your network and try again.";
  }

  return "Something went wrong. Please try again.";
}
void _showAlertDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelText = "OK",
  String? confirmText,
  VoidCallback? onConfirm,
}) {
  showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: Text(cancelText),
          onPressed: () => Navigator.pop(context),
        ),
        if (confirmText != null)
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(confirmText),
            onPressed: () {
              Navigator.pop(context);
              if (onConfirm != null) onConfirm();
            },
          ),
      ],
    ),
  );
}


  final List<String> levels = [
    "100 level",
    "200 level",
    "300 level",
    "400 level",
    "500 level",
    "N/A",
  ];

  final List<String> status = [
    "Student",
    "Academic Staff",
    "Non-Academic Staff",
    "Admin",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black,
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
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

              const SizedBox(height: 40),

              Text(
                "Create Account",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                "Relative School Details",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "These details help verify your identity and access to campus features.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 25),

              // Department
              InputField(
                controller: _departmentController,
                obscureText: false,
                hintText: "Department",
              ),

              const SizedBox(height: 15),

              // Level dropdown
              _buildDropdown(
                title: "Level",
                value: selectedLevelValue,
                items: levels,
                onChanged: (v) => setState(() => selectedLevelValue = v),
              ),

              const SizedBox(height: 15),

              // ID / Reg
              InputField(
                controller: _regNumberController,
                obscureText: false,
                hintText: "ID / Reg Number",
              ),

              const SizedBox(height: 15),

              // Status dropdown
              _buildDropdown(
                title: "Status",
                value: selectedStatusValue,
                items: status,
                onChanged: (v) => setState(() => selectedStatusValue = v),
              ),

              const SizedBox(height: 35),

              // Continue Button
              GestureDetector(
                onTap: _isLoading ? null : _saveProfile,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isLoading
                        ? LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.white,
                            size: 30,
                          )
                        : Text(
                            "Continue",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String title,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: Text(title),
            isExpanded: true,
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
