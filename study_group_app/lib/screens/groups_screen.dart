import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../screens/group_details_screen.dart';
import '../services/database_service.dart';
 
// Same family as the palette used on the home tab — indigo as the single
// brand color, plus a small rotating accent set for group identity. Kept
// local to this file for now; worth promoting to design_system.dart once
// it's settled across the app.
class _Palette {
  static const paper = Color(0xFFF6F5F2);
  static const ink = Color(0xFF232338);
  static const inkSoft = Color(0xFF74748C);
  static const card = Color(0xFFFFFFFF);
  static const hairline = Color(0xFFE7E6EF);
 
  static const indigo = Color(0xFF4E4AC7);
  static const indigoDeep = Color(0xFF3A3798);
  static const amber = Color(0xFFF2A33D);
  static const amberSoft = Color(0xFFFBE7C6);
  static const teal = Color(0xFF1FA98C);
  static const tealSoft = Color(0xFFD3EEE7);
  static const coral = Color(0xFFEB6F5C);
  static const coralSoft = Color(0xFFFBE0DA);
  static const plum = Color(0xFFB4519C);
  static const plumSoft = Color(0xFFF1DCEC);
 
  static const accents = [indigo, teal, coral, plum, amber];
  static const accentsSoft = [Color(0xFFE4E3F7), tealSoft, coralSoft, plumSoft, amberSoft];
}
 
class GroupsScreen extends StatefulWidget {
  final AppUser? currentUser;
  final User user;
 
  const GroupsScreen({
    super.key,
    required this.currentUser,
    required this.user,
  });
 
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}
 
class _GroupsScreenState extends State<GroupsScreen> {
  final DatabaseService _databaseService = DatabaseService();
 
  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return const Center(
        child: CircularProgressIndicator(color: _Palette.indigo),
      );
    }
 
    return DefaultTabController(
      length: 2,
      child: Container(
        color: _Palette.paper,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Groups',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _Palette.ink,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Manage your study circles and discover new classes.',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: _Palette.inkSoft,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _Palette.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Palette.hairline),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: _Palette.indigo,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: _Palette.inkSoft,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(height: 38, text: 'My Groups'),
                    
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [_buildMyGroupsTab(), _buildDiscoverTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildMyGroupsTab() {
    return StreamBuilder<List<GroupModel>>(
      stream: _databaseService.getGroupsForUser(widget.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _Palette.indigo),
          );
        }
 
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: _buildEmptyState(
              icon: Icons.groups_rounded,
              title: 'No groups joined yet',
              body: 'Your study groups will appear here once you join or create one.',
              buttonLabel: 'Browse groups',
              onTap: () => DefaultTabController.of(context).animateTo(1),
            ),
          );
        }
 
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: groups.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            return _buildGroupCard(groups[index], index, true);
          },
        );
      },
    );
  }
 
  Widget _buildDiscoverTab() {
    return StreamBuilder<List<GroupModel>>(
      stream: _databaseService.getGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _Palette.indigo),
          );
        }
 
        final groups = snapshot.data ?? [];
        final availableGroups = groups
            .where((group) => !group.members.contains(widget.currentUser!.uid))
            .toList();
 
        if (availableGroups.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: _buildEmptyState(
              icon: Icons.travel_explore_rounded,
              title: 'Nothing new to discover',
              body: "All available study groups are already part of your collection, or your search is too narrow.",
            ),
          );
        }
 
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: availableGroups.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            return _buildGroupCard(availableGroups[index], index, false);
          },
        );
      },
    );
  }
 
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String body,
    String? buttonLabel,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.hairline),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _Palette.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _Palette.indigo, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: _Palette.ink),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.poppins(fontSize: 13.5, color: _Palette.inkSoft, height: 1.6),
          ),
          if (buttonLabel != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Palette.indigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  buttonLabel,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
 
  Widget _buildGroupCard(GroupModel group, int index, bool isMemberTab) {
    final accent = _Palette.accents[index % _Palette.accents.length];
    final accentSoft = _Palette.accentsSoft[index % _Palette.accentsSoft.length];
    final bool isMember = group.members.contains(widget.currentUser!.uid);
 
    return Container(
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.hairline),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupDetailsScreen(
                  group: group,
                  currentUser: widget.currentUser!,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(13)),
                      child: Center(
                        child: Text(
                          group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: GoogleFonts.poppins(fontSize: 16.5, fontWeight: FontWeight.w800, color: _Palette.ink),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: accentSoft, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              group.subject.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  group.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _Palette.inkSoft,
                    height: 1.55,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: _Palette.hairline),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.people_alt_rounded, size: 15, color: _Palette.inkSoft),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${group.members.length} members',
                        style: GoogleFonts.poppins(color: _Palette.inkSoft, fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (isMember)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: _Palette.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 14, color: _Palette.teal),
                            const SizedBox(width: 5),
                            Text(
                              'Joined',
                              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _Palette.teal),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () async {
                          await _databaseService.joinGroup(group.id, widget.user.uid);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(
                          'Join',
                          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 