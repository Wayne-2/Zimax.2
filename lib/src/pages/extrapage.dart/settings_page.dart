import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zimax/src/pages/extrapage.dart/edit_profile_page.dart';
import 'package:zimax/src/services/riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkMode = false;
  bool _webVisualEffects = false;
  String _selectedLanguage = 'English';
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
    // Load persisted settings (fallbacks to current defaults if null)
    _notificationsEnabled = _settingsBox.get('notificationsEnabled', defaultValue: true) as bool;
    _emailNotifications = _settingsBox.get('emailNotifications', defaultValue: true) as bool;
    _pushNotifications = _settingsBox.get('pushNotifications', defaultValue: true) as bool;
    _darkMode = _settingsBox.get('darkMode', defaultValue: false) as bool;
    _webVisualEffects = _settingsBox.get('webVisualEffects', defaultValue: false) as bool;
    _selectedLanguage = _settingsBox.get('language', defaultValue: 'English') as String;
    
    // Sync web visual effects to provider
    Future.microtask(() {
      ref.read(enableWebVisualEffectsProvider.notifier).state = _webVisualEffects;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  Future<void> _syncSettingsToServer() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await supabase.from('profiles').update({
        'notifications_enabled': _notificationsEnabled,
        'email_notifications': _emailNotifications,
        'push_notifications': _pushNotifications,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Settings sync skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Update your profile information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: () {
              _showChangePasswordDialog();
            },
          ),
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: user?.email ?? 'No email',
            trailing: const SizedBox.shrink(),
          ),

          const SizedBox(height: 20),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Enable Notifications',
            subtitle: 'Receive app notifications',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveSetting('notificationsEnabled', value);
              _syncSettingsToServer();
            },
          ),
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: 'Email Notifications',
            subtitle: 'Receive updates via email',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
              _saveSetting('emailNotifications', value);
              _syncSettingsToServer();
            },
          ),
          _buildSwitchTile(
            icon: Icons.push_pin_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive push notifications',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
              _saveSetting('pushNotifications', value);
              _syncSettingsToServer();
            },
          ),

          const SizedBox(height: 20),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Enable dark theme',
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dark mode will be available in next update'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildSwitchTile(
            icon: Icons.auto_awesome_outlined,
            title: 'Web Visual Effects',
            subtitle: 'Enable blur, shadows & animations on web',
            value: _webVisualEffects,
            onChanged: (value) {
              setState(() {
                _webVisualEffects = value;
              });
              _saveSetting('webVisualEffects', value);
              ref.read(enableWebVisualEffectsProvider.notifier).state = value;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value ? 'Visual effects enabled' : 'Visual effects disabled for better performance'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: _selectedLanguage,
            onTap: () {
              _showLanguageDialog();
            },
          ),

          const SizedBox(height: 20),

          // Privacy & Security Section
          _buildSectionHeader('Privacy & Security'),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy Policy page coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.shield_outlined,
            title: 'Terms of Service',
            subtitle: 'View terms and conditions',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms of Service page coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.block_outlined,
            title: 'Blocked Users',
            subtitle: 'Manage blocked users',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Blocked users list coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Get help and support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Help Center coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Share your thoughts',
            onTap: () {
              _showFeedbackDialog();
            },
          ),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About Zimax',
            subtitle: 'Version 1.0.0',
            onTap: () {
              _showAboutDialog();
            },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeTrackColor: Colors.black87,
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: newPasswordController.text),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Password updated successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
            child: Text('Update', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Language',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('French'),
            _buildLanguageOption('Spanish'),
            _buildLanguageOption('German'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(
        language,
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      trailing: _selectedLanguage == language
          ? const Icon(Icons.check, color: Colors.black87)
          : null,
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Send Feedback',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: feedbackController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Share your thoughts...',
            hintStyle: GoogleFonts.poppins(fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
            child: Text('Send', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'About Zimax',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Zimax Live',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Version 1.0.0',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Communication and Information dispersal at its finest. Connect, learn, and collaborate in real-time.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
