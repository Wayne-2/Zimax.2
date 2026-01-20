// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateCommunity extends StatefulWidget {
  const CreateCommunity({super.key});

  @override
  State<CreateCommunity> createState() => _CreateCommunityState();
}

class _CreateCommunityState extends State<CreateCommunity> {
  final supabase = Supabase.instance.client;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _customLink = TextEditingController();
  final TextEditingController _ruleController = TextEditingController();
  final List<String> _rules = [];

  String? selectedCategory;
  bool isPrivate = false;
  bool ageRestricted = false;
  File? avatar;
  File? banner;
  bool isCreating = false;

  final categories = [
    "Technology",
    "Gaming",
    "Education",
    "Programming",
    "Entertainment",
    "Fashion",
    "Music",
    "Business",
    "Sports",
    "Crypto",
  ];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _customLink.dispose();
    _ruleController.dispose();
    super.dispose();
  }

  Future<void> pickAvatar() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (file != null && mounted) {
        setState(() => avatar = File(file.path));
      }
    } catch (e) {
      debugPrint('Error picking avatar: $e');
      if (mounted) {
        _showError('Failed to pick image: ${e.toString()}');
      }
    }
  }

  Future<void> pickBanner() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 400,
      );
      if (file != null && mounted) {
        setState(() => banner = File(file.path));
      }
    } catch (e) {
      debugPrint('Error picking banner: $e');
      if (mounted) {
        _showError('Failed to pick image: ${e.toString()}');
      }
    }
  }

  void _addRule() {
    final text = _ruleController.text.trim();
    if (text.isEmpty) return;

    if (_rules.length >= 10) {
      _showError('Maximum 10 rules allowed');
      return;
    }

    setState(() {
      _rules.add(text);
      _ruleController.clear();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  bool _validateForm() {
    final name = _name.text.trim();

    if (name.isEmpty) {
      _showError("Community name is required");
      return false;
    }

    if (name.length < 3) {
      _showError("Name must be at least 3 characters");
      return false;
    }

    if (name.length > 50) {
      _showError("Name must be less than 50 characters");
      return false;
    }

    if (selectedCategory == null) {
      _showError("Please select a category");
      return false;
    }

    final customLink = _customLink.text.trim();
    if (customLink.isNotEmpty) {
      // Validate custom link format (alphanumeric, hyphens, underscores only)
      final linkRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
      if (!linkRegex.hasMatch(customLink)) {
        _showError("Custom link can only contain letters, numbers, hyphens, and underscores");
        return false;
      }
    }

    return true;
  }

  Future<void> create() async {
    if (!_validateForm()) return;

    if (isCreating) return; // Prevent double submission

    setState(() => isCreating = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Upload images first if they exist
      String? avatarUrl;
      String? bannerUrl;

      // Create a temporary community ID for uploads
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();

      if (avatar != null) {
        avatarUrl = await uploadCommunityImage(
          file: avatar!,
          bucket: 'community-avatars',
          communityId: tempId,
        );
      }

      if (banner != null) {
        bannerUrl = await uploadCommunityImage(
          file: banner!,
          bucket: 'community-banners',
          communityId: tempId,
        );
      }

      // Create community
      final community = await supabase
          .from('communities')
          .insert({
            'owner_id': userId,
            'name': _name.text.trim(),
            'description': _description.text.trim().isEmpty 
                ? null 
                : _description.text.trim(),
            'category': selectedCategory,
            'custom_link': _customLink.text.trim().isEmpty 
                ? null 
                : _customLink.text.trim(),
            'is_private': isPrivate,
            // 'age_restricted': ageRestricted,
            'avatar_url': avatarUrl,
            'banner_url': bannerUrl,
          })
          .select()
          .single();

      final communityId = community['id'];

      // Insert rules if any
      if (_rules.isNotEmpty) {
        final rulesPayload = _rules.asMap().entries.map((e) {
          return {
            'community_id': communityId,
            'rule_text': e.value,
            'rule_order': e.key + 1,
          };
        }).toList();

        await supabase.from('community_rules').insert(rulesPayload);
      }

      // Success
      if (mounted) {
        _showSuccess('Community created successfully!');
        
        // Wait a bit for the success message to show
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Return the created community data
        if (mounted) {
          Navigator.pop(context, community);
        }
      }
    } catch (e) {
      debugPrint('Error creating community: $e');
      if (mounted) {
        String errorMessage = 'Failed to create community';
        
        if (e.toString().contains('duplicate key')) {
          errorMessage = 'A community with this name or link already exists';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection';
        }
        
        _showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => isCreating = false);
      }
    }
  }

  Future<String> uploadCommunityImage({
    required File file,
    required String bucket,
    required String communityId,
  }) async {
    try {
      final extension = file.path.split('.').last;
      final path = '$communityId/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await supabase.storage.from(bucket).upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      return supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: Text(
          "Create Community",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _form()),
              _createButton(),
            ],
          ),
          if (isCreating)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _form() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bannerPicker(),
          const SizedBox(height: 20),
          _avatarPicker(),
          const SizedBox(height: 20),
          _textField(
            "Community Name *",
            "Enter name",
            _name,
            required: true,
          ),
          const SizedBox(height: 16),
          _textField(
            "Description",
            "Tell people what this community is about",
            _description,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _sectionTitle("Category *"),
          const SizedBox(height: 8),
          _categoryDropdown(),
          const SizedBox(height: 24),
          _sectionTitle("Custom Community Link"),
          const SizedBox(height: 8),
          _customLinkField(),
          const SizedBox(height: 24),
          _sectionTitle("Community Rules"),
          const SizedBox(height: 8),
          _rulesSection(),
          const SizedBox(height: 24),
          _toggles(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _bannerPicker() {
    return GestureDetector(
      onTap: pickBanner,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          image: banner != null
              ? DecorationImage(
                  image: FileImage(banner!),
                  fit: BoxFit.cover,
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: banner == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_outlined,
                      size: 36,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Add Banner Image",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "(Optional)",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                      onPressed: () => setState(() => banner = null),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _avatarPicker() {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: pickAvatar,
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: avatar != null ? FileImage(avatar!) : null,
              child: avatar == null
                  ? const Icon(
                      Icons.camera_alt_outlined,
                      size: 32,
                      color: Colors.white70,
                    )
                  : null,
            ),
          ),
          if (avatar != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => setState(() => avatar = null),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black,
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _textField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.black,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _customLinkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _customLink,
          decoration: InputDecoration(
            prefixText: "zimax.app/c/",
            prefixStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            hintText: "my-community",
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.black,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Letters, numbers, hyphens, and underscores only",
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _categoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          hint: Text(
            "Select a category",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          items: categories
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => selectedCategory = value),
        ),
      ),
    );
  }

  Widget _toggles() {
    return Column(
      children: [
        _toggleItem(
          title: "Private Community",
          subtitle: "Only approved members can see posts",
          value: isPrivate,
          onChanged: (v) => setState(() => isPrivate = v),
        ),
        
      ],
    );
  }

  Widget _toggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        ),
        value: value,
        activeColor: Colors.black,
        onChanged: onChanged,
      ),
    );
  }

  Widget _createButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        height: 50,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isCreating ? null : create,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black,
            disabledBackgroundColor: Colors.grey.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isCreating
              ? SizedBox(
                   height: 22,
                   width: 22,
                   child: LoadingAnimationWidget.staggeredDotsWave(
                     color: const Color.fromARGB(255, 255, 255, 255),
                     size: 30,
                   ),
                 )
              : Text(
                  "Create Community",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  Widget _rulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ruleController,
                decoration: InputDecoration(
                  hintText: "Add a rule (e.g. Be respectful)",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.black,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: (_) => _addRule(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _addRule,
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_rules.isNotEmpty)
          Column(
            children: List.generate(
              _rules.length,
              (index) => _ruleItem(index),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "No rules added yet",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _ruleItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${index + 1}. ${_rules[index]}",
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _rules.removeAt(index)),
          ),
        ],
      ),
    );
  }
}