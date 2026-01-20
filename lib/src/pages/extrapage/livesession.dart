// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:zimax/src/components/svgicon.dart';

class LiveStreamScreen extends StatefulWidget {
  final String url = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> with TickerProviderStateMixin {
  late FlickManager flickManager;
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late AnimationController _pulseController;
  int participantCount = 24;
  bool showParticipants = false;

  final List<Map<String, dynamic>> messages = [
    {"name": "Ahmed Olamide", "message": "Good morning, sir", "time": "09:01", "avatar": "AO"},
    {"name": "Chioma Nwosu", "message": "Can you explain that concept again?", "time": "09:03", "avatar": "CN"},
    {"name": "Tunde Bakare", "message": "I have a question about slide 5", "time": "09:05", "avatar": "TB"},
    {"name": "Fatima Hassan", "message": "Thank you for the explanation!", "time": "09:07", "avatar": "FH"},
    {"name": "Emeka Okafor", "message": "This is very helpful", "time": "09:08", "avatar": "EO"},
  ];

  final List<Map<String, dynamic>> participants = [
    {"name": "Dr. Adebayo (Host)", "isHost": true, "isMuted": false, "isVideoOn": true, "avatar": "DA"},
    {"name": "Ahmed Olamide", "isHost": false, "isMuted": true, "isVideoOn": false, "avatar": "AO"},
    {"name": "Chioma Nwosu", "isHost": false, "isMuted": true, "isVideoOn": true, "avatar": "CN"},
    {"name": "Tunde Bakare", "isHost": false, "isMuted": true, "isVideoOn": false, "avatar": "TB"},
    {"name": "Fatima Hassan", "isHost": false, "isMuted": true, "isVideoOn": true, "avatar": "FH"},
    {"name": "Emeka Okafor", "isHost": false, "isMuted": true, "isVideoOn": false, "avatar": "EO"},
    {"name": "Grace Adeyemi", "isHost": false, "isMuted": true, "isVideoOn": true, "avatar": "GA"},
    {"name": "Ibrahim Musa", "isHost": false, "isMuted": true, "isVideoOn": false, "avatar": "IM"},
    {"name": "Jennifer Okoro", "isHost": false, "isMuted": true, "isVideoOn": true, "avatar": "JO"},
    {"name": "Kunle Ajayi", "isHost": false, "isMuted": true, "isVideoOn": false, "avatar": "KA"},
  ];

  @override
  void initState() {
    super.initState();
    flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      ),
      autoPlay: true,
      autoInitialize: true,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    flickManager.dispose();
    controller.dispose();
    scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "name": "You",
        "message": controller.text.trim(),
        "time": TimeOfDay.now().format(context),
        "avatar": "YO",
      });
      controller.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// Header
            _buildHeader(),

            /// Video Player Section
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  FlickVideoPlayer(flickManager: flickManager),

                  // Gradient overlay for better visibility
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Live Badge
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _buildLiveBadge(),
                  ),

                  // Participant count
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _buildParticipantCount(),
                  ),
                ],
              ),
            ),

            /// Class Info
            _buildClassInfo(),

            /// Tab Switcher (Chat / Participants)
            _buildTabSwitcher(),

            /// Content Area (Chat or Participants)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showParticipants
                    ? _buildParticipantsList()
                    : _buildChatSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 10,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CSC 301 - Data Structures',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.video_camera_front, color: Colors.black87, size: 22),
            onPressed: () {},
          ),
          SizedBox(width: 10,),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3 + (0.7 * _pulseController.value)),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            participantCount.toString(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            child: Text(
              'DA',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. Adebayo',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Lecturer • Computer Science Dept.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Colors.green[700]),
                const SizedBox(width: 6),
                Text(
                  'Active',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => showParticipants = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: !showParticipants ? const Color.fromARGB(255, 0, 0, 0) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgIcon('assets/icons/livechat.svg', color: !showParticipants ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey[600],size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: !showParticipants ? FontWeight.w600 : FontWeight.w400,
                        color: !showParticipants ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey[600],
                      ),
                    ),
                    if (!showParticipants && messages.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          messages.length.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => showParticipants = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: showParticipants ? const Color.fromARGB(255, 0, 0, 0) : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 18,
                      color: showParticipants ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Participants',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: showParticipants ? FontWeight.w600 : FontWeight.w400,
                        color: showParticipants ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: showParticipants ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        participantCount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: showParticipants ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      key: const ValueKey('chat'),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Chat Messages
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to say something!',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      return _buildChatMessage(
                        msg["name"]!,
                        msg["message"]!,
                        msg["time"]!,
                        msg["avatar"]!,
                      );
                    },
                  ),
          ),

          // Chat Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: controller,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type a comment...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 0, 0, 0),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(String name, String message, String time, String avatar) {
    final isYou = name == "You";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isYou ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey[300],
            child: Text(
              avatar,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isYou ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList() {
    return Container(
      key: const ValueKey('participants'),
      color: Colors.grey[50],
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: participants.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final participant = participants[index];
          return _buildParticipantItem(
            participant["name"]!,
            participant["avatar"]!,
            participant["isHost"]!,
            participant["isMuted"]!,
            participant["isVideoOn"]!,
          );
        },
      ),
    );
  }

  Widget _buildParticipantItem(
    String name,
    String avatar,
    bool isHost,
    bool isMuted,
    bool isVideoOn,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isHost ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey[300],
            child: Text(
              avatar,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isHost ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (isHost)
                  Text(
                    'Host',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color.fromARGB(255, 8, 160, 15),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMuted ? Icons.mic_off : Icons.mic,
                size: 18,
                color: isMuted ? Colors.grey[400] : const Color.fromARGB(255, 0, 0, 0),
              ),
              const SizedBox(width: 12),
              Icon(
                isVideoOn ? Icons.videocam : Icons.videocam_off,
                size: 20,
                color: isVideoOn ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey[400],
              ),
            ],
          ),
        ],
      ),
    );
  }
}