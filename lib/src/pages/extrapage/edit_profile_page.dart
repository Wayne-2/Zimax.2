import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/services/riverpod.dart';
import 'package:zimax/src/models/userprofile.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullnameController;
  late TextEditingController _emailController;
  late TextEditingController _departmentController;
  late TextEditingController _levelController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProfileProvider);
    _fullnameController = TextEditingController(text: user?.fullname ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _departmentController = TextEditingController(text: user?.department ?? '');
    _levelController = TextEditingController(text: user?.level ?? '');
    _bioController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _levelController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _uploadProfilePhoto() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _isLoading = true);

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final fileExt = image.path.split('.').last.toLowerCase();
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      // Upload to Supabase storage (media bucket instead of profile_photos)
      final bytes = await image.readAsBytes();
      
      // Try uploading to 'media' bucket (more likely to exist)
      try {
        await supabase.storage
            .from('media')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(
                contentType: 'image/$fileExt',
                upsert: true,
              ),
            );
      } catch (storageError) {
        // If media bucket fails, try creating with public URL structure
        debugPrint('Storage upload error: $storageError');
        throw Exception('Failed to upload image. Please check storage bucket permissions.');
      }

      // Get public URL
      final photoUrl = supabase.storage
          .from('media')
          .getPublicUrl(filePath);

      debugPrint('Photo URL: $photoUrl');

      // Update user profile with new photo URL
      await supabase
          .from('user_profile')
          .update({
            'profile_image_url': photoUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Update local state
      final updated = await supabase
          .from('user_profile')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (updated != null && mounted) {
        ref
            .read(userProfileProvider.notifier)
            .setUser(Userprofile.fromJson(updated));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      await supabase
          .from('user_profile')
          .update({
            'fullname': _fullnameController.text.trim(),
            'department': _departmentController.text.trim(),
            'level': _levelController.text.trim(),
            'bio':_bioController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId!);

      final updated = await supabase
          .from('user_profile')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (updated != null) {
        ref
            .read(userProfileProvider.notifier)
            .setUser(Userprofile.fromJson(updated));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Profile Photo Section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: user?.pfp != null
                        ? CachedNetworkImageProvider(user!.pfp)
                        : null,
                    child: user?.pfp == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey.shade400,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        await _uploadProfilePhoto();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Full Name
            _buildTextField(
              controller: _fullnameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Email (Read-only)
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              readOnly: true,
              enabled: false,
            ),

            const SizedBox(height: 16),

            // Department
            _buildTextField(
              controller: _departmentController,
              label: 'Department',
              icon: Icons.book_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your department';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Level
            _buildTextField(
              controller: _levelController,
              label: 'Level',
              icon: Icons.school_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your level';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Bio
            _buildTextField(
              controller: _bioController,
              label: 'Bio (Optional)',
              icon: Icons.notes_outlined,
              maxLines: 4,
              hint: 'Tell us about yourself...',
            ),

            const SizedBox(height: 24),

            // Status Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIconData(user?.status ?? ''),
                    color: _getStatusColor(user?.status ?? ''),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Type',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          user?.status ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    bool readOnly = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.grey.shade400,
        ),
        suffixIcon: Icon(icon, color: Colors.grey.shade600, size:18),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromARGB(156, 0, 0, 0), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  IconData _getStatusIconData(String status) {
    switch (status) {
      case "Student":
        return Icons.school;
      case "Academic Staff":
        return Icons.star;
      case "Non-Academic Staff":
        return Icons.work;
      case "Admin":
        return Icons.verified;
      default:
        return Icons.person;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Student":
        return const Color.fromARGB(255, 0, 0, 254);
      case "Academic Staff":
        return const Color.fromARGB(255, 255, 208, 0);
      case "Non-Academic Staff":
        return const Color.fromARGB(255, 255, 0, 0);
      case "Admin":
        return const Color.fromARGB(255, 2, 145, 19);
      default:
        return Colors.grey;
    }
  }
}
