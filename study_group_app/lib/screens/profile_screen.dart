import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'login_screen.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser? currentUser;
  const ProfileScreen({super.key, this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _bio = 'Lifelong learner, study buddy, and note organizer.';
  bool _isLogoutPressed = false;

  void _editBio() {
    final controller = TextEditingController(text: _bio);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Bio',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Write something about yourself...',
            hintStyle: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFF2A2A3D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _bio = controller.text.trim().isEmpty
                    ? 'Lifelong learner, study buddy, and note organizer.'
                    : controller.text.trim();
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    Navigator.of(context).pop();
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    await GoogleSignIn().disconnect();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showLogoutSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: const Color(0xFF1E1E2C),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF3A1E28),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF4757),
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Logout?',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out of your account?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2A2A3D)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: _performLogout,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4757).withAlpha(76),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER SECTION ---
              _buildHeader(user),

              const SizedBox(height: 20),

              // --- STATS OVERVIEW ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<GroupModel>>(
                        stream: user != null
                            ? _databaseService.getMyGroups(user.uid)
                            : Stream<List<GroupModel>>.value([]),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length ?? 0;
                          return _buildStatTile(
                            icon: Icons.groups_rounded,
                            color: const Color(0xFF6C63FF),
                            value: '$count',
                            label: 'Groups',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatTile(
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFFFF6584),
                        value: '${user?.friends.length ?? 0}',
                        label: 'Friends',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- BIO & DETAILS CARD ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'About Me',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: _editBio,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF).withAlpha(40),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Edit Bio',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8E7DFF),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _bio,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFFD1D5DB),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- ACTIVE GROUPS SUMMARY CARD ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<List<GroupModel>>(
                  stream: user != null
                      ? _databaseService.getMyGroups(user.uid)
                      : Stream<List<GroupModel>>.value([]),
                  builder: (context, snapshot) {
                    final groupCount = snapshot.data?.length ?? 0;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withAlpha(40),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.auto_stories_rounded,
                              color: Color(0xFF8E7DFF),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Study Groups',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$groupCount active group${groupCount == 1 ? '' : 's'} joined',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // --- LOGOUT BUTTON ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: AnimatedScale(
                  scale: _isLogoutPressed ? 0.96 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isLogoutPressed = true),
                    onTapUp: (_) {
                      setState(() => _isLogoutPressed = false);
                      _showLogoutSheet();
                    },
                    onTapCancel: () =>
                        setState(() => _isLogoutPressed = false),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B).withAlpha(90),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER WIDGET ---
  Widget _buildHeader(AppUser? user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        gradient: LinearGradient(
          colors: [Color(0xFF5B52E0), Color(0xFF7C6CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Profile',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundImage: user?.profileImage != null
                      ? NetworkImage(user!.profileImage!)
                      : null,
                  child: user?.profileImage == null
                      ? Text(
                          user?.initials ?? 'U',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E2C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Color(0xFF8E7DFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user?.username ?? 'Learning Buddy',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user?.email ?? 'you@example.com',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withAlpha(217),
            ),
          ),
        ],
      ),
    );
  }

  // --- STAT TILE WIDGET ---
  Widget _buildStatTile({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}