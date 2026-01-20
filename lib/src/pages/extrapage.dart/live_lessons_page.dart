import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/services/livekit_service.dart';
import 'package:zimax/src/services/riverpod.dart';

class LiveLessonPage extends ConsumerStatefulWidget {
  final String lessonId;
  const LiveLessonPage({super.key, required this.lessonId});

  @override
  ConsumerState<LiveLessonPage> createState() => _LiveLessonPageState();
}

class _LiveLessonPageState extends ConsumerState<LiveLessonPage> {
  Room? room;
  bool connecting = true;
  String? connectionError;
  bool cameraEnabled = true;
  bool microphoneEnabled = true;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    // Fetch a LiveKit token from your backend

    try {
        final token = await LiveKitService.getToken(widget.lessonId);

        debugPrint('TOKEN TYPE: ${token.runtimeType}');
        debugPrint('Token value: $token');

        final newRoom = Room(
          roomOptions: const RoomOptions(
            adaptiveStream: true,
            dynacast: true,
          ),
        );
        await newRoom.connect(
          'wss://zimax-qwon77cp.livekit.cloud',
          token,
        );

           // Automatically publish tracks if lecturer
        if (newRoom.localParticipant?.permissions.canPublish ?? false) {
          try {
            final videoTrack = await LocalVideoTrack.createCameraTrack();
            final audioTrack = await LocalAudioTrack.create();
            await newRoom.localParticipant?.publishVideoTrack(videoTrack);
            await newRoom.localParticipant?.publishAudioTrack(audioTrack);
          } catch (trackError) {
            debugPrint('Error publishing tracks: $trackError');
          }
        }

        if (mounted) {
          setState(() {
            room = newRoom;
            connecting = false;
            connectionError = null;
          });
        }
    } on FunctionException catch (e) {
      debugPrint('Edge function error: ${e.details}');
      if (mounted) {
        setState(() {
          connecting = false;
          connectionError = 'Function Error: ${e.details}';
        });
      }
    } catch (e) {
      debugPrint('Unexpected error: $e');
      if (mounted) {
        setState(() {
          connecting = false;
          connectionError = 'Connection Error: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    room?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (connectionError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to Connect',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  connectionError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    connecting = true;
                    connectionError = null;
                  });
                  _connect();
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      );
    }

    if (connecting || room == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isLecturer = room!.localParticipant?.permissions.canPublish ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Main video (lecturer or pinned participant)
          Expanded(
              child: ParticipantView(
              participant: isLecturer
                  ? room!.localParticipant!
                  : room!.remoteParticipants.values.where((p) => p.sid != room!.localParticipant!.sid).isNotEmpty
                      ? room!.remoteParticipants.values.where((p) => p.sid != room!.localParticipant!.sid).first
                      : room!.localParticipant!,
              mirror: isLecturer,
            ),
          ),

          // Students thumbnails
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: room!.remoteParticipants.values
                  .where((p) => p.sid != room!.localParticipant!.sid)
                  .map((p) => Container(
                        width: 100,
                        margin: const EdgeInsets.all(4),
                        child: ParticipantView(participant: p),
                      ))
                  .toList(),
            ),
          ),

          // Live comments
          Expanded(
            child: _CommentsSection(
              lessonId: widget.lessonId,
            ),
          ),

          // Controls
          _ControlsBar(room: room!, isLecturer: isLecturer),
        ],
      ),
    );
  }
}

class ParticipantView extends StatelessWidget {
  final Participant participant;
  final bool mirror;

  const ParticipantView({super.key, required this.participant, this.mirror = false});

  @override
  Widget build(BuildContext context) {
    // Check if participant has video enabled by looking at their tracks
    final hasVideo = participant.trackPublications.values
        .any((pub) => pub.kind == TrackType.VIDEO && pub.subscribed);

    return Container(
      color: Colors.black,
      child: Center(
        child: hasVideo
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  color: Colors.grey.shade900,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 56,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        participant.name.isEmpty
                            ? participant.identity
                            : participant.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Video Feed',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    participant.name.isEmpty
                        ? participant.identity
                        : participant.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Camera off',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ControlsBar extends StatelessWidget {
  final Room room;
  final bool isLecturer;

  const _ControlsBar({required this.room, required this.isLecturer});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLecturer) ...[
            // Microphone Toggle
            IconButton(
              icon: Icon(
                room.localParticipant!.isMicrophoneEnabled()
                    ? Icons.mic
                    : Icons.mic_off,
                color: room.localParticipant!.isMicrophoneEnabled() ? Colors.white : Colors.orange,
              ),
              onPressed: () {
                room.localParticipant!.setMicrophoneEnabled(
                  !room.localParticipant!.isMicrophoneEnabled(),
                );
              },
              tooltip: 'Toggle Microphone',
            ),
            const SizedBox(width: 16),
          ],
          // Leave/End Session Button
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('End Session'),
                  content: Text(isLecturer 
                      ? 'Ending the session will disconnect all participants.' 
                      : 'Are you sure you want to leave this session?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        room.disconnect();
                        Navigator.pop(context);
                      },
                      child: const Text('Leave', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Leave Session',
          ),
        ],
      ),
    );
  }
}

class _CommentsSection extends ConsumerStatefulWidget {
  final String lessonId;

  const _CommentsSection({required this.lessonId});

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final commentsStream = ref.watch(
      lessonMessagesProvider(widget.lessonId),
    );

    return Container(
      height: 200, // Fixed height for comments section
      padding: const EdgeInsets.all(8),
      color: Colors.black87,
      child: Column(
        children: [
          // Messages
          Expanded(
            child: commentsStream.when(
              data: (rows) => ListView(
                reverse: true,
                children: rows.map((e) {
                  final isMe = e['user_id'] == Supabase.instance.client.auth.currentUser!.id;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMe ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey.shade800,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: Radius.circular(isMe ? 12 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 12),
                        ),
                      ),
                      child: Text(
                        e['content'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
              error: (_, __) => const Center(child: Text("Failed to load comments", style: TextStyle(color: Colors.white))),
            ),
          ),

          // Input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward, color: Color.fromARGB(255, 0, 0, 0)),
                  onPressed: () async {
                    final content = _controller.text.trim();
                    if (content.isEmpty) return;

                    await Supabase.instance.client.from('lesson_messages').insert({
                      'lesson_id': widget.lessonId,
                      'sender_id': Supabase.instance.client.auth.currentUser!.id,
                      'type': 'text',          // since it's a normal text message
                      'message': content,      // actual message content
                    });

                    _controller.clear();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

