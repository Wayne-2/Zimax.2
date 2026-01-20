import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:zimax/src/components/publicprofile.dart';

class PostOptionsMenu extends StatelessWidget {
  final String? postId;
  final String? userId;

  const PostOptionsMenu({super.key, this.postId, this.userId});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PostMenuAction>(
      padding: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      onSelected: (action) async {
        switch (action) {
          case _PostMenuAction.follow:
            break;
          case _PostMenuAction.profile:
            // Navigator.push(context, MaterialPageRoute(builder: (context)=> Publicprofile()));
            break;
          case _PostMenuAction.report:
            break;
          case _PostMenuAction.block:
            break;
          case _PostMenuAction.delete:
            if (postId != null && userId != null) {
              _deletePost(context, postId!, userId!);
            }
            break;
        }
      },
      itemBuilder: (context) {
        final supabase = Supabase.instance.client;
        final currentUser = supabase.auth.currentUser?.id;
        final isOwner = currentUser == userId;

        return [
          _buildItem('Follow', _PostMenuAction.follow),
          _buildItem(
            'View profile',
            _PostMenuAction.profile,
          ),
          _buildItem(
            'Report user',
            _PostMenuAction.report,
          ),
          const PopupMenuDivider(),
          if (isOwner)
            _buildItem(
              'Delete',
              _PostMenuAction.delete,
              isDestructive: true,
            ),
          _buildItem(
            'Block',
            _PostMenuAction.block,
            isDestructive: true,
          ),
        ];
      },
    );
  }

  void _deletePost(BuildContext context, String postId, String postUserId) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              try {
                final supabase = Supabase.instance.client;
                await supabase.from('media_posts').delete().eq('id', postId);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post deleted'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
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

  PopupMenuItem<_PostMenuAction> _buildItem(
    String text,
    _PostMenuAction action, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: isDestructive ? Colors.red : const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PostMenuAction { follow, profile, report, block, delete }
