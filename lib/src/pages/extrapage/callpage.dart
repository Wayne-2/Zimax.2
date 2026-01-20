import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:zimax/src/services/callservice.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class CallPage extends StatefulWidget {
  final String callId;
  final bool isCaller;
  final bool isVideo;
  final String userId;
  final String friendName;

  const CallPage({
    super.key,
    required this.callId,
    required this.isCaller,
    required this.isVideo,
    required this.userId,
    required this.friendName,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  Room? room;
  LocalAudioTrack? audioTrack;
  LocalVideoTrack? videoTrack;

  bool connecting = true;
  bool micEnabled = true;
  bool cameraEnabled = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> requestMobilePermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      throw Exception('Camera and microphone permissions are required to join the call.');
    }
  }

  Future<void> _initCall() async {
    try {
      // Ask for permissions first (only on mobile platforms)
      if (Platform.isAndroid || Platform.isIOS) {
        await requestMobilePermissions();
      }
      
      // Then connect to LiveKit
      await _connect();
    } catch (e) {
      if (mounted) {
        setState(() {
          connecting = false;
          error = e.toString();
        });
      }
    }
  }

  Future<void> _connect() async {
    try {
      final token = await CallService.getToken(callId: widget.callId);

      final r = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );

      await r.connect('wss://zimax-qwon77cp.livekit.cloud', token);

      // Only the caller publishes initially
      if (widget.isCaller) {
        // Audio
        audioTrack = await LocalAudioTrack.create();
        await r.localParticipant?.publishAudioTrack(audioTrack!);

        // Video if enabled
        if (widget.isVideo) {
          videoTrack = await LocalVideoTrack.createCameraTrack();
          await r.localParticipant?.publishVideoTrack(videoTrack!);
        }
      }

      if (!mounted) return;
      setState(() {
        room = r;
        connecting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          connecting = false;
          error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    room?.disconnect();
    super.dispose();
  }

  // Toggle mic
  void toggleMic() {
    if (room == null) return;
    micEnabled = !micEnabled;
    room!.localParticipant?.setMicrophoneEnabled(micEnabled);
    setState(() {});
  }

  // Toggle camera
  void toggleCamera() {
    if (room == null) return;
    cameraEnabled = !cameraEnabled;
    room!.localParticipant?.setCameraEnabled(cameraEnabled);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (connecting) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            error!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final local = room!.localParticipant!;
    final remote = room!.remoteParticipants.values.isNotEmpty
        ? room!.remoteParticipants.values.first
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Local video
          Expanded(
            child: ParticipantView(participant: local, mirror: true),
          ),

          // Remote video if exists
          if (remote != null)
            Expanded(
              child: ParticipantView(participant: remote, mirror: false),
            ),

          // Call controls
          CallControls(
            micEnabled: micEnabled,
            cameraEnabled: cameraEnabled,
            showCamera: widget.isVideo,
            onToggleMic: toggleMic,
            onToggleCamera: toggleCamera,
            onEnd: () {
              room?.disconnect();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

/// Participant Video Widget
class ParticipantView extends StatelessWidget {
  final Participant participant;
  final bool mirror;

  const ParticipantView({
    super.key,
    required this.participant,
    required this.mirror,
  });

  @override
  Widget build(BuildContext context) {
    VideoTrack? videoTrack;

    // Pick first subscribed video track
    for (final pub in participant.videoTrackPublications) {
      if (pub.subscribed && pub.track != null) {
        videoTrack = pub.track as VideoTrack;
        break;
      }
    }

    if (videoTrack == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 48, color: Colors.white),
          ),
        ),
      );
    }

    // Mirror local video using Transform
    return Container(
      color: Colors.black,
      child: Center(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(mirror ? -1.0 : 1.0, 1.0, 1.0),
          child: VideoTrackRenderer(videoTrack),
        ),
      ),
    );
  }
}

/// Call Controls
class CallControls extends StatelessWidget {
  final bool micEnabled;
  final bool cameraEnabled;
  final bool showCamera;

  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onEnd;

  const CallControls({
    super.key,
    required this.micEnabled,
    required this.cameraEnabled,
    required this.showCamera,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(micEnabled ? Icons.mic : Icons.mic_off, color: Colors.white),
            onPressed: onToggleMic,
          ),
          if (showCamera) ...[
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(cameraEnabled ? Icons.videocam : Icons.videocam_off, color: Colors.white),
              onPressed: onToggleCamera,
            ),
          ],
          const SizedBox(width: 16),
          IconButton(icon: const Icon(Icons.call_end, color: Colors.red), onPressed: onEnd),
        ],
      ),
    );
  }
}