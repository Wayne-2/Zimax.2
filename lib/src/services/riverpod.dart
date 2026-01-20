// import 'dart:async';
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/models/addchatinfo.dart';
import 'package:zimax/src/models/chatpreview.dart';
import 'package:zimax/src/models/communitymodel.dart';
import 'package:zimax/src/models/gcmodel.dart';
import 'package:zimax/src/models/mediapost.dart';
import 'package:zimax/src/models/userprofile.dart';

class UserNotifier extends StateNotifier<Userprofile?> {
  UserNotifier() : super(null);

  void setUser(Userprofile user) {
    state = user;
  }

  void clearUser() {
    state = null;
  }
}

final userProfileProvider = StateNotifierProvider<UserNotifier, Userprofile?>((
  ref,
) {
  return UserNotifier();
});

final usersStreamProvider = StreamProvider.autoDispose((ref) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('user_profile')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((rows) {
        return rows.map((e) => Addchatinfo.fromMap(e)).toList();
      });
});

final userServiceStreamProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('user_profile')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((rows) {
        return rows.map((e) {
          return {
            'id': e['id'],
            'fullname': e['fullname'] ?? '',
            'email': e['email'] ?? '',
            'status': e['status'] ?? '',
            'bio': e['bio'] ?? 'No bio available',
            'profile_image_url': e['profile_image_url'] ?? '',
            'created_at': e['created_at'] ?? '',
          };
        }).toList();
      });
});

// media_post riverpod streaming

final mediaPostsStreamProvider = StreamProvider.autoDispose<List<MediaPost>>((
  ref,
) {
  final supabase = Supabase.instance.client;

  final stream = supabase
      .from('media_posts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) {
        return rows.map((e) => MediaPost.fromJson(e)).toList();
      });

  return stream;
});

final zimaxHomePostsProvider = StreamProvider<List<MediaPost>>((ref) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('media_posts')
      .stream(primaryKey: ['id'])
      .eq('posted_to', 'Zimax home')
      .order('created_at', ascending: false)
      .map((rows) => rows.map((e) => MediaPost.fromJson(e)).toList());
});

// users posted content
final userPostsProvider =
    StreamProvider.family<List<MediaPost>, String>((ref, userId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('media_posts')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map((rows) {
        return rows
            .where((e) => e['posted_to'] != 'story')
            .map((e) => MediaPost.fromJson(e))
            .toList();
      });
});

// user comments provider
final userCommentsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('comment')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map((rows) {
        return rows.map((e) => Map<String, dynamic>.from(e)).toList();
      });
});

// chatpreview
class ChatPreviewNotifier extends StateNotifier<Map<String, ChatPreview>> {
  ChatPreviewNotifier() : super({});

  void onNewMessage({
    required String chatroomId,
    required String message,
    required DateTime createdAt,
    required bool isMine,
  }) {
    final current = state[chatroomId];

    state = {
      ...state,
      chatroomId: ChatPreview(
        chatroomId: chatroomId,
        lastMessage: message,
        lastMessageTime: createdAt,
        unreadCount: isMine ? 0 : (current?.unreadCount ?? 0) + 1,
      ),
    };
  }

  void markAsRead(String chatroomId) {
    final preview = state[chatroomId];
    if (preview == null) return;

    state = {
      ...state,
      chatroomId: ChatPreview(
        chatroomId: chatroomId,
        lastMessage: preview.lastMessage,
        lastMessageTime: preview.lastMessageTime,
        unreadCount: 0,
      ),
    };
  }
}

final chatPreviewProvider =
    StateNotifierProvider<ChatPreviewNotifier, Map<String, ChatPreview>>(
      (ref) => ChatPreviewNotifier(),
    );

// community provider
final recentCommunitiesProvider = FutureProvider<List<CommunityModel>>((
  ref,
) async {
  final supabase = Supabase.instance.client;

  final data = await supabase.rpc('get_recent_communities');

  if (data == null) return [];

  print(data);

  return (data as List<dynamic>)
      .map((e) => CommunityModel.fromMap(e as Map<String, dynamic>))
      .toList();
});

final isJoinedProvider = FutureProvider.family<bool, String>((
  ref,
  communityId,
) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;

  final res = await supabase
      .from('community_members')
      .select()
      .eq('community_id', communityId)
      .eq('user_id', userId)
      .maybeSingle();

  return res != null;
});

final enableWebVisualEffectsProvider = StateProvider<bool>((ref) => false);

final communityChatProvider =
    StateNotifierProvider.family<CommunityChatNotifier, ChatState, String>(
      (ref, communityId) => CommunityChatNotifier(communityId, ref),
    );

class CommunityChatNotifier extends StateNotifier<ChatState> {
  final String communityId;
  final Ref ref;
  final supabase = Supabase.instance.client;

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _typingSub;

  CommunityChatNotifier(this.communityId, this.ref)
    : super(ChatState(messages: [], typingUsers: [], lastRead: null)) {
    _loadInitialMessages();
    _subscribeToMessages();
    _subscribeToTyping();
  }

  /// Load initial chat messages
  Future<void> _loadInitialMessages() async {
    try {
      final res = await supabase
          .from('community_messages')
          .select()
          .eq('community_id', communityId)
          .order('created_at', ascending: true);

      final msgs = res
          .map<CommunityMessage>((e) => CommunityMessage.fromMap(e))
          .toList();
      state = state.copyWith(messages: msgs);
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  /// Real-time messages stream
  void _subscribeToMessages() {
    final stream = supabase
        .from('community_messages')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .order('created_at', ascending: true);

    _messagesSub = stream.listen((data) {
      final msgs = data.map((e) => CommunityMessage.fromMap(e)).toList();
      state = state.copyWith(messages: msgs);
    }, onError: (error) => debugPrint('Error in message stream: $error'));
  }

  /// Real-time typing status stream
  void _subscribeToTyping() {
    final currentUserId = supabase.auth.currentUser?.id;
    final stream = supabase
        .from('typing_status')
        .stream(primaryKey: ['user_id'])
        .eq('community_id', communityId);

    _typingSub = stream.listen((data) {
      final typingUsers = data
          .where((e) => e['user_id'] != currentUserId)
          .map<String>((e) => e['user_name'] as String)
          .toList();
      state = state.copyWith(typingUsers: typingUsers);
    }, onError: (error) => debugPrint('Error in typing stream: $error'));
  }

  /// Send a new message
  Future<void> sendMessage({
    required String content,
    required String senderName,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('community_messages').insert({
        'community_id': communityId,
        'sender_id': user.id,
        'sender_name': senderName,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  /// Update typing status
  Future<void> setTypingStatus(bool isTyping) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final userName = ref.read(userProfileProvider)?.fullname ?? 'User';

    try {
      if (isTyping) {
        await supabase.from('typing_status').upsert({
          'user_id': user.id,
          'community_id': communityId,
          'user_name': userName,
          'is_typing': true,
          'last_typed': DateTime.now().toIso8601String(),
        });
      } else {
        await supabase
            .from('typing_status')
            .delete()
            .eq('user_id', user.id)
            .eq('community_id', communityId);
      }
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }

  /// Mark chat as read (for read receipts)
  Future<void> markChatOpened() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    state = state.copyWith(lastRead: DateTime.now());

    try {
      await supabase.from('community_read_status').upsert({
        'user_id': user.id,
        'community_id': communityId,
        'last_read': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error marking chat as opened: $e');
    }
  }

  @override
  void dispose() {
    setTypingStatus(false);
    _messagesSub?.cancel();
    _typingSub?.cancel();
    super.dispose();
  }
}

// public profile riverpod

final publicUserProfileProvider = StreamProvider.family<Userprofile, String>((
  ref,
  userId,
) {
  final supabase = Supabase.instance.client;

  final stream = supabase
      .from('user_profile')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((rows) {
        if (rows.isEmpty) {
          throw Exception('User profile not found');
        }
        return Userprofile.fromJson(rows.first);
      });

  ref.onDispose(() {
    // Stream automatically closed by Supabase
  });

  return stream;
});

// followers provider
final followStatusStreamProvider =
    StreamProvider.family<bool, String>((ref, targetId) {
  final supabase = Supabase.instance.client;
  final uid = supabase.auth.currentUser!.id;

return supabase
    .from('follows')
    .stream(primaryKey: ['id'])
    .eq('follower_id', uid)
    .map((rows) {
      return rows.any(
        (row) => row['following_id'] == targetId,
      );
    });

});


// for private accounts

final followRequestProvider = FutureProvider.family<bool, String>((
  ref,
  targetId,
) async {
  final uid = Supabase.instance.client.auth.currentUser!.id;

  final res = await Supabase.instance.client
      .from('follow_requests')
      .select('id')
      .eq('requester_id', uid)
      .eq('target_id', targetId)
      .maybeSingle();

  return res != null;
});

final lessonMessagesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
  (ref, lessonId) {
    final supabase = Supabase.instance.client;

    return supabase
        .from('lesson_messages')
        .stream(primaryKey: ['id'])
        .eq('lesson_id', lessonId)
        .order('created_at', ascending: false);
  },
);

// Check if a community has an active live session
final hasActiveLiveSessionProvider = FutureProvider.family<bool, String>((
  ref,
  communityId,
) async {
  final supabase = Supabase.instance.client;

  try {
    final result = await supabase
        .from('lessons')
        .select('id')
        .eq('community_id', communityId)
        .eq('is_live', true)
        .maybeSingle();

    return result != null;
  } catch (e) {
    return false;
  }
});



final followCountsStreamProvider =
    StreamProvider.family<Map<String, int>, String>((ref, userId) {
  final supabase = Supabase.instance.client;

  final followersStream = supabase
      .from('follows')
      .stream(primaryKey: ['id'])
      .eq('following_id', userId);

  final followingStream = supabase
      .from('follows')
      .stream(primaryKey: ['id'])
      .eq('follower_id', userId);

  return Rx.combineLatest2(
    followersStream,
    followingStream,
    (List followers, List following) => {
      'followers': followers.length,
      'following': following.length,
    },
  );
});

final bookmarkedPostsProvider =
    StreamProvider.autoDispose<List<MediaPost>>((ref) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return const Stream.empty();

  return supabase
      .from('media_posts')
      .stream(primaryKey: ['id'])
      .inFilter(
        'id',
        supabase
            .from('media_post_bookmarks')
            .select('media_post_id')
            .eq('user_id', user.id) as List<Object>,
      )
      .order('created_at', ascending: false)
      .map((rows) =>
          rows.map((e) => MediaPost.fromJson(e)).toList());
});
