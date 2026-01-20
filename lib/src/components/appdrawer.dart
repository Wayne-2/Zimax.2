import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/appbar/notification.dart';
import 'package:zimax/src/appbar/profile.dart';
import 'package:zimax/src/auth/signin.dart';
import 'package:zimax/src/components/svgicon.dart';
import 'package:zimax/src/pages/extrapage.dart/settings_page.dart';
import 'package:zimax/src/services/riverpod.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    // Ensure user is not null or handle it gracefully
    if (user == null) return const SizedBox.shrink();

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 0, // Twitter/IG style is flat
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Straight edge looks more "modern app"
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2), // Outer ring
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade100, width: 1),
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: CachedNetworkImageProvider(user.pfp),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _getStatusIcon(user.status, isBadge: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullname,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    user.email,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ---- Menu Items ----
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildMenuItem(
                    icon: 'assets/appbaricon/profile.svg',
                    label: "Profile",
                    onTap: () => _navigate(context, Profilepage()),
                  ),
                  _buildMenuItem(
                    icon: 'assets/appbaricon/notification.svg',
                    label: "Notifications",
                    onTap: () => _navigate(context, NotificationsPage()),
                  ),
                  _buildMenuItem(
                    icon: 'assets/appbaricon/bookmark.svg',
                    label: "Saved Items",
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: 'assets/appbaricon/settings.svg',
                    label: "Settings and Privacy",
                    onTap: () => _navigate(context, SettingsPage()),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Divider(thickness: 0.5),
                  ),
                  _buildMenuItem(
                    icon: 'assets/appbaricon/info.svg',
                    label: "Help Center",
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // ---- Footer / Log Out ----
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: InkWell(
                onTap: () => _handleLogout(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Log Out',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
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

  void _navigate(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer first
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Future<void> _handleLogout(BuildContext context) async {
    if (!mounted) return;
    
    // Save context before async operation
    final navigator = Navigator.of(context);
    
    await Supabase.instance.client.auth.signOut();
    
    if (mounted) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Signin()),
        (route) => false,
      );
    }
  }

  Widget _buildMenuItem({
    required String icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: SvgIcon(icon, color: Colors.black87, size: 24),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }
}

// Modernized Status Icon as a Badge
Widget _getStatusIcon(String status, {bool isBadge = false}) {
  Color color;
  IconData icon;

  switch (status) {
    case "Admin":
      color = const Color.fromARGB(255, 238, 0, 0); 
      icon = Icons.verified;
      break;
    case "Academic Staff":
      color = Colors.amber.shade700;
      icon = Icons.stars;
      break;
    default:
      color = const Color.fromARGB(255, 0, 75, 225);
      icon = Icons.school;
  }

  if (isBadge) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: color),
    );
  }
  return Icon(icon, size: 18, color: color);
}