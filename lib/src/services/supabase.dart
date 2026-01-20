import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/models/userprofile.dart';

class UserProfileService {
  final supabase = Supabase.instance.client;

  // Insert a new profile after sign-up
  Future<void> createProfile(Userprofile profile) async {
    final response = await supabase
        .from('user_profile')
        .insert(profile.toJson());

    if (response != null) {
      // Errors are thrown by Supabase package automatically
    }
  }

  // Fetch profile for logged-in user
  Future<Userprofile?> getProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await supabase
        .from('user_profile')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Userprofile.fromJson(data);
  }

  // Update profile
  Future<void> updateProfile(Userprofile profile) async {
    await supabase
        .from('user_profile')
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  // Check if profile exists
  Future<bool> profileExists(String userId) async {
    final data = await supabase
        .from('user_profile')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    return data != null;
  }
}
