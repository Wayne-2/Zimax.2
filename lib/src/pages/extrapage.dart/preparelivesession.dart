
// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/pages/extrapage.dart/live_lessons_page.dart';

class LiveClassSetupScreen extends StatefulWidget {
  const LiveClassSetupScreen({super.key});

  @override
  State<LiveClassSetupScreen> createState() => _LiveClassSetupScreenState();
}

class _LiveClassSetupScreenState extends State<LiveClassSetupScreen> {
  final TextEditingController classNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  
  String meetingCode = 'zimax.app/ade-xyz';
  bool isVideoOn = true;
  bool isAudioOn = true;
  bool allowStudentVideo = true;
  bool allowStudentAudio = false;
  
  final List<Map<String, dynamic>> invitedStudents = [
    {"name": "Ahmed Olamide", "email": "ahmed.o@university.edu", "status": "pending"},
    {"name": "Chioma Nwosu", "email": "chioma.n@university.edu", "status": "joined"},
    {"name": "Tunde Bakare", "email": "tunde.b@university.edu", "status": "pending"},
  ];

  @override
  void initState() {
    super.initState();
    _generateMeetingCode();
  }


void _generateMeetingCode() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random.secure();

  String randomPart(int length) {
    return List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  setState(() {
    meetingCode =
        'zimax.app/${randomPart(3)}-${randomPart(3)}';
  });
}


  void _copyMeetingCode() {
    Clipboard.setData(ClipboardData(text: meetingCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Meeting code copied to clipboard',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addStudent() {
    if (emailController.text.trim().isEmpty) return;
    
    setState(() {
      invitedStudents.add({
        "name": emailController.text.split('@')[0],
        "email": emailController.text.trim(),
        "status": "pending",
      });
      emailController.clear();
    });
  }

  void _removeStudent(int index) {
    setState(() {
      invitedStudents.removeAt(index);
    });
  }

  void _startClass() async {
    if (classNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a class name',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // Create a live lesson in Supabase
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) throw Exception('User not authenticated');

      final lessonData = await supabase.from('lessons').insert({
        'title': classNameController.text.trim(),
        'description': descriptionController.text.trim(),
        'instructor_id': userId,
        'meeting_code': meetingCode,
        'is_active': true,
        'allow_student_video': allowStudentVideo,
        'allow_student_audio': allowStudentAudio,
      }).select().single();

      final lessonId = lessonData['id'] as String;

      // Navigate to LiveLessonPage
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveLessonPage(lessonId: lessonId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error starting class: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Setup Live Session',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Class Details Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Details',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Class Name Input
                  TextField(
                    controller: classNameController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Session name',
                      hintText: 'e.g., CSC 301 - Data Structures',
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Theme.of(context).dividerColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.8,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Description Input
                  TextField(
                    controller: descriptionController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Add details about the class session...',
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Theme.of(context).dividerColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.8,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            /// Meeting Code Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Meeting Code',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _generateMeetingCode,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(
                          'Generate New',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromARGB(255, 31, 31, 31),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(26, 0, 0, 0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black38),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Students can join using this code',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                meetingCode,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _copyMeetingCode,
                          icon: const Icon(Icons.copy, size: 20),
                          color: const Color.fromARGB(255, 0, 0, 0),
                          tooltip: 'Copy code',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            /// Settings Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Host Settings
                  _buildSettingTile(
                    icon: Icons.videocam,
                    title: 'Start with video on',
                    subtitle: 'Your camera will be on when joining',
                    value: isVideoOn,
                    onChanged: (val) => setState(() => isVideoOn = val),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingTile(
                    icon: Icons.mic,
                    title: 'Start with audio on',
                    subtitle: 'Your microphone will be on when joining',
                    value: isAudioOn,
                    onChanged: (val) => setState(() => isAudioOn = val),
                  ),
                  
                  const Divider(height: 32),
                  
                  // Student Permissions
                  Text(
                    'Student Permissions',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingTile(
                    icon: Icons.videocam_outlined,
                    title: 'Allow students to use video',
                    subtitle: 'Students can turn on their cameras',
                    value: allowStudentVideo,
                    onChanged: (val) => setState(() => allowStudentVideo = val),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingTile(
                    icon: Icons.mic_outlined,
                    title: 'Allow students to unmute',
                    subtitle: 'Students can unmute their microphones',
                    value: allowStudentAudio,
                    onChanged: (val) => setState(() => allowStudentAudio = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            /// Invited Students Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invited Students',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${invitedStudents.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Add Student Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter student email',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).dividerColor.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.8,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          ),
                          onSubmitted: (_) => _addStudent(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 0, 0, 0),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _addStudent,
                          icon: const Icon(Icons.add, color: Colors.white),
                          tooltip: 'Add student',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Student List
                  if (invitedStudents.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'No students invited yet',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...invitedStudents.asMap().entries.map((entry) {
                      final index = entry.key;
                      final student = entry.value;
                      return _buildStudentItem(
                        student["name"]!,
                        student["email"]!,
                        student["status"]!,
                        index,
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Start Button (Bottom)
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _startClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Start Live Class',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? Colors.black12 : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 22,
              color: value ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color.fromARGB(255, 0, 2, 5),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentItem(String name, String email, String status, int index) {
    final isJoined = status == "joined";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isJoined ? Colors.green[200]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isJoined ? Colors.green[100] : Colors.grey[300],
            child: Text(
              name[0].toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isJoined ? Colors.green[800] : Colors.grey[700],
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
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isJoined)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Joined',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            )
          else
            IconButton(
              onPressed: () => _removeStudent(index),
              icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    classNameController.dispose();
    descriptionController.dispose();
    emailController.dispose();
    super.dispose();
  }
}