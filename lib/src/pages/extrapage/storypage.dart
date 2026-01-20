import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/models/story.dart';
import 'package:zimax/src/components/publicprofile.dart';
import 'package:zimax/src/pages/chat.dart';

class StoryPage extends StatefulWidget {
  final List<StoryItem> stories;
  final int initialIndex;

  const StoryPage({super.key, required this.stories, this.initialIndex = 0});

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int currentIndex = 0;
  final TextEditingController _replyController = TextEditingController();
  bool showReplyField = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        nextStory();
      }
    });

    _progressController.forward();
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward();
  }

  void nextStory() {
    if (currentIndex < widget.stories.length - 1) {
      setState(() => currentIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgress();
      setState(() => showReplyField = false);
    } else {
      Navigator.pop(context);
    }
  }

  void previousStory() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgress();
      setState(() => showReplyField = false);
    }
  }

  Future<void> _deleteStory() async {
    final supabase = Supabase.instance.client;
    final storyId = widget.stories[currentIndex].id;
    final storyUserId = widget.stories[currentIndex].userId;
    final userId = supabase.auth.currentUser?.id;

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Story'),
        content: const Text('Are you sure you want to delete this story?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // Capture context helpers before async work
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              try {
                // Check if user is the story creator
                if (storyUserId != userId) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('You can only delete your own stories'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Delete from Supabase
                await supabase
                    .from('media_posts')
                    .delete()
                    .eq('id', storyId);

                if (!mounted) return;

                // Remove from list, adjust index, and route appropriately
                setState(() {
                  widget.stories.removeAt(currentIndex);

                  if (widget.stories.isNotEmpty) {
                    if (currentIndex >= widget.stories.length) {
                      currentIndex = widget.stories.length - 1;
                    }
                  }
                });

                if (!mounted) return;

                if (widget.stories.isEmpty) {
                  // If no stories remain, navigate to Chats page (fallback)
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const Chat()),
                    (route) => false,
                  );
                  return;
                }

                // Only proceed if still mounted
                if (!mounted) return;

                try {
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(currentIndex);
                  }

                  // Restart progress for the newly visible story
                  if (mounted) {
                    _startProgress();
                    setState(() => showReplyField = false);
                  }
                } catch (pageError) {
                  debugPrint('Error updating page: $pageError');
                }

                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Story deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      // Defensive: if no stories remain, exit gracefully.
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.shrink(),
      );
    }

    // final story = widget.stories[currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Stories PageView
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.stories.length,
          itemBuilder: (_, index) {
            final s = widget.stories[index];
          
            if (s.isText || (s.imageUrl == null && s.text != null)) {
              // Text-only story
              return Container(
                color: Colors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      s.text ?? '',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            } else if (s.imageUrl != null) {
              // Image or image + text story
              return Stack(
                children: [
                  Center(
                    child: CachedNetworkImage(
                      imageUrl: s.imageUrl!,
                      width: double.infinity,
                      placeholder: (_, _) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade700,
                        highlightColor: Colors.grey.shade500,
                        child: Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.grey,
                        ),
                      ),
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.error, color: Colors.white),
                    ),
                  ),
                  if (s.text != null)
                    Positioned(
                      bottom: 40,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          s.text!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            } else {
              // Fallback empty container if both image and text are null
              return Container(color: Colors.black);
            }
          },

          ),

          // Top progress bars + user info + back button
          Positioned(
            top: 30,
            left: 10,
            right: 10,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (_, _) {
                    return Row(
                      children: widget.stories
                          .asMap()
                          .map((i, e) {
                            return MapEntry(
                              i,
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: LinearProgressIndicator(
                                    value: i == currentIndex
                                        ? _progressController.value
                                        : (i < currentIndex ? 1 : 0),
                                    backgroundColor: Colors.white24,
                                    color: Colors.white,
                                    minHeight: 2,
                                  ),
                                ),
                              ),
                            );
                          })
                          .values
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigate to user profile
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Publicprofile(
                              userId: widget.stories[currentIndex].userId,
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(
                          widget.stories[currentIndex].avatar ?? '',
                        ),
                        radius: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to user profile
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Publicprofile(
                                userId: widget.stories[currentIndex].userId,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          widget.stories[currentIndex].name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Three dots menu - show delete for own stories, mute/block for others
                    Builder(
                      builder: (context) {
                        final currentStory = widget.stories[currentIndex];
                        final supabase = Supabase.instance.client;
                        final userId = supabase.auth.currentUser?.id;
                        final isOwnStory = currentStory.userId == userId;
                        
                        if (isOwnStory) {
                          return PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'delete') {
                                _deleteStory();
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                          );
                        } else {
                          return PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'mute') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User muted'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else if (value == 'block') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User blocked'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                value: 'mute',
                                child: Text('Mute'),
                              ),
                              const PopupMenuItem(
                                value: 'block',
                                child: Text('Block'),
                              ),
                            ],
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                          );
                        }
                      },
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tap to navigate + swipe up
          Positioned(
            top: 90, // Start below the header to avoid conflicting with close button and profile
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTapDown: (details) {
                final width = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < width / 2) {
                  previousStory();
                } else {
                  nextStory();
                }
              },
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < -150) {
                  setState(() => showReplyField = true);
                }
              },
            ),
          ),

          // Reply text field
          if (showReplyField)
            Positioned(
              bottom: 20,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: TextField(
                        controller: _replyController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Send reply...",
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (val) {
                          if (val.isNotEmpty) _replyController.clear();
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_replyController.text.isNotEmpty) _replyController.clear();
                    },
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
