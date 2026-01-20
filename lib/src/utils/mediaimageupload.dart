// ignore_for_file: avoid_print

import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

final ImagePicker _picker = ImagePicker();

Future<File?> pickImage() async {
  final XFile? pickedFile = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 80,
  );

  if (pickedFile != null) {
    return File(pickedFile.path);
  } else {
    return null;
  }
}

Future<String?> uploadProfileImage(File file, String userId) async {
  final supabase = Supabase.instance.client;

  final fileName =
      'profile/$userId/${DateTime.now().millisecondsSinceEpoch}.png';

  try {
    await supabase.storage
        .from('avatars') 
        .upload(fileName, file);

    final String publicUrl =
        supabase.storage.from('avatars').getPublicUrl(fileName);

    return publicUrl;
  } catch (e) {
    print("Upload Error: $e");
    return null;
  }
}

Future<void> updateProfileImageUrl(String userId, String imageUrl) async {
  final supabase = Supabase.instance.client;

  await supabase.from('user_profile').update({
    'profile_image_url': imageUrl,
  }).eq('id', userId);
}
