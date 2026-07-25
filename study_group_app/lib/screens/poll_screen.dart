import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../models/poll_model.dart';
import '../services/poll_service.dart';
import '../services/database_service.dart';
import 'poll_screen.dart';
 
// ============================================================
// 1. LIST SCREEN — shows all polls in a group
// ============================================================
class GroupPollListScreen extends StatefulWidget {
  final GroupModel group;
  final AppUser currentUser;
 
  const GroupPollListScreen({
    super.key,
    required this.group,
    required this.currentUser,
  });
 
  @override
  State<GroupPollListScreen> createState() => _GroupPollListScreenState();
}
 
class _GroupPollListScreenState extends State<GroupPollListScreen> {
  final PollService _pollService = PollService();
 
  Widget _buildPollCard(PollModel poll) {
    final counts = poll.voteCounts;
    final totalSelections = counts.fold<int>(0, (a, b) => a + b);
    final userVoted = poll.hasVoted(widget.currentUser.uid);
 
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PollDetailScreen(
              groupId: widget.group.id,
              pollId: poll.id,
              currentUser: widget.currentUser,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6584).withAlpha(36),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.poll_rounded,
                    color: Color(0xFFFF6584),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    poll.question,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                if (poll.isClosed)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B7280).withAlpha(36),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Closed',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  userVoted ? Icons.check_circle_rounded : Icons.how_to_vote_rounded,
                  size: 15,
                  color: userVoted
                      ? const Color(0xFF43E97B)
                      : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  userVoted
                      ? 'You voted'
                      : '${poll.totalVoters} response${poll.totalVoters == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${poll.options.length} options · $totalSelections selections',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'by ${poll.createdByName}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        title: Text(
          'Polls',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF6584),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreatePollScreen(
                group: widget.group,
                currentUser: widget.currentUser,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Poll',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<List<PollModel>>(
        stream: _pollService.pollsStream(widget.group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final polls = snapshot.data ?? [];
          if (polls.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No polls yet. Tap "New Poll" to ask the group something.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            itemCount: polls.length,
            itemBuilder: (context, index) => _buildPollCard(polls[index]),
          );
        },
      ),
    );
  }
}
 
// ============================================================
// 2. CREATE SCREEN — question + dynamic options + multi-choice toggle
// ============================================================
class CreatePollScreen extends StatefulWidget {
  final GroupModel group;
  final AppUser currentUser;
 
  const CreatePollScreen({
    super.key,
    required this.group,
    required this.currentUser,
  });
 
  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}
 
class _CreatePollScreenState extends State<CreatePollScreen> {
  final PollService _pollService = PollService();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _allowMultipleChoice = false;
  bool _isSaving = false;
 
  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }
 
  void _addOption() {
    if (_optionControllers.length >= 8) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }
 
  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }
 
  Future<void> _submit() async {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
 
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question.')),
      );
      return;
    }
    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 options.')),
      );
      return;
    }
 
    setState(() => _isSaving = true);
    try {
      await _pollService.createPoll(
        groupId: widget.group.id,
        question: question,
        options: options,
        createdBy: widget.currentUser.uid,
        createdByName: widget.currentUser.username,
        allowMultipleChoice: _allowMultipleChoice,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create poll: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
 
  Widget _buildFieldContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        title: Text(
          'New Poll',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            _buildFieldContainer(
              child: TextField(
                controller: _questionController,
                maxLines: 2,
                style: GoogleFonts.poppins(fontSize: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'e.g. When should we meet for revision?',
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Options',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(_optionControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFieldContainer(
                        child: TextField(
                          controller: _optionControllers[index],
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Option ${index + 1}',
                          ),
                        ),
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF6B7280), size: 20),
                        onPressed: () => _removeOption(index),
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add, color: Color(0xFF6C63FF)),
              label: Text(
                'Add option',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF6C63FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFF6C63FF),
                title: Text(
                  'Allow multiple answers',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Members can pick more than one option',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                value: _allowMultipleChoice,
                onChanged: (v) => setState(() => _allowMultipleChoice = v),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6584),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(
                        'Create Poll',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ============================================================
// 3. DETAIL SCREEN — voting + live results + voter names
// ============================================================
class PollDetailScreen extends StatefulWidget {
  final String groupId;
  final String pollId;
  final AppUser currentUser;
 
  const PollDetailScreen({
    super.key,
    required this.groupId,
    required this.pollId,
    required this.currentUser,
  });
 
  @override
  State<PollDetailScreen> createState() => _PollDetailScreenState();
}
 
class _PollDetailScreenState extends State<PollDetailScreen> {
  final PollService _pollService = PollService();
  final DatabaseService _databaseService = DatabaseService();
 
  int? _expandedOption;
 
  Future<void> _vote(PollModel poll, int index) async {
    if (poll.isClosed) return;
    await _pollService.vote(
      groupId: widget.groupId,
      pollId: widget.pollId,
      uid: widget.currentUser.uid,
      optionIndex: index,
      allowMultipleChoice: poll.allowMultipleChoice,
    );
  }
 
  Widget _buildOptionTile(PollModel poll, int index) {
    final counts = poll.voteCounts;
    final total = counts.fold<int>(0, (a, b) => a + b);
    final voteCount = counts[index];
    final percent = total == 0 ? 0.0 : voteCount / total;
    final selected = poll.selectionsFor(widget.currentUser.uid).contains(index);
    final voters = poll.votersForOption(index);
    final expanded = _expandedOption == index;
 
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? const Color(0xFF6C63FF) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _vote(poll, index),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        poll.allowMultipleChoice
                            ? (selected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded)
                            : (selected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded),
                        color: selected
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          poll.options[index],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      Text(
                        '$voteCount',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF0F0F5),
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (voters.isNotEmpty)
            InkWell(
              onTap: () => setState(
                () => _expandedOption = expanded ? null : index,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      expanded ? 'Hide voters' : 'See who voted',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: const Color(0xFF6C63FF),
                    ),
                  ],
                ),
              ),
            ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
              child: FutureBuilder<List<AppUser>>(
                future: _databaseService.getUsersByIds(voters),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  final names = snapshot.data!.map((u) => u.username).join(', ');
                  return Text(
                    names,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        title: Text(
          'Poll',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: StreamBuilder<PollModel>(
        stream: _pollService.pollStream(widget.groupId, widget.pollId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final poll = snapshot.data!;
          final isCreator = poll.createdBy == widget.currentUser.uid;
 
          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  poll.question,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${poll.totalVoters} response${poll.totalVoters == 1 ? '' : 's'} · '
                  '${poll.allowMultipleChoice ? 'Multiple choice' : 'Single choice'}'
                  '${poll.isClosed ? ' · Closed' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(
                  poll.options.length,
                  (i) => _buildOptionTile(poll, i),
                ),
                if (isCreator) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        if (poll.isClosed) {
                          await _pollService.reopenPoll(
                              widget.groupId, widget.pollId);
                        } else {
                          await _pollService.closePoll(
                              widget.groupId, widget.pollId);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6C63FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        poll.isClosed ? 'Reopen Poll' : 'Close Poll',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
 