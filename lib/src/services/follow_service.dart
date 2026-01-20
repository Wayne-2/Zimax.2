import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowService {
  static final _client = Supabase.instance.client;

  static Future<void> followOrRequest(
    String targetId,
    bool isPrivate,
  ) async {
    final uid = _client.auth.currentUser!.id;

    if (uid == targetId) return;

    if (isPrivate) {
      await _client.from('follow_requests').insert({
        'requester_id': uid,
        'target_id': targetId,
      });
    } else {
      // Insert follow relationship
      await _client.from('follows').insert({
        'follower_id': uid,
        'following_id': targetId,
      });
      
      // Update follower count for target user
      await _updateFollowerCount(targetId);
      
      // Update following count for current user
      await _updateFollowingCount(uid);
    }
  }

  static Future<void> unfollow(String targetId) async {
    final uid = _client.auth.currentUser!.id;

    await _client
        .from('follows')
        .delete()
        .eq('follower_id', uid)
        .eq('following_id', targetId);
    
    // Update follower count for target user
    await _updateFollowerCount(targetId);
    
    // Update following count for current user
    await _updateFollowingCount(uid);
  }

  static Future<void> _updateFollowerCount(String userId) async {
    try {
      // Count followers
      final response = await _client
          .from('follows')
          .select()
          .eq('following_id', userId);
      
      final count = response.length;
      
      // Update user profile
      await _client
          .from('user_profile')
          .update({'follower_count': count, 'followers_count': count})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating follower count: $e');
    }
  }

  static Future<void> _updateFollowingCount(String userId) async {
    try {
      // Count following
      final response = await _client
          .from('follows')
          .select()
          .eq('follower_id', userId);
      
      final count = response.length;
      
      // Update user profile
      await _client
          .from('user_profile')
          .update({'following_count': count})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating following count: $e');
    }
  }
}
