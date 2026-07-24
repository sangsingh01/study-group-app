// lib/screens/quiz_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/design_system.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../models/study_models.dart';

/// ---------- QUIZ LIST (per-group) ----------
class GroupQuizListScreen extends StatelessWidget {
  final GroupModel group;
  final AppUser currentUser;
  const GroupQuizListScreen({
    super.key,
    required this.group,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CipherColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CipherColors.greenPrimary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateQuizScreen(group: group, currentUser: currentUser),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('New Quiz', style: CipherTextStyles.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildQuizStream()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 64, bottom: 24, left: 16, right: 16),
      decoration: const BoxDecoration(
        gradient: CipherColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${group.name} Quizzes',
                    style: CipherTextStyles.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Create quizzes or test your knowledge',
                    style: CipherTextStyles.poppins(fontSize: 13, color: Colors.white, alpha: 0.8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quizzes')
          .where('groupId', isEqualTo: group.id)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: CipherColors.greenPrimary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load quizzes.', style: CipherTextStyles.poppins(color: Colors.grey)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No quizzes yet — tap "New Quiz" to create one.',
                style: CipherTextStyles.poppins(color: Colors.grey), textAlign: TextAlign.center),
          );
        }

        final quizzes = snapshot.data!.docs
            .map((d) => QuizModel.fromMap(d.data() as Map<String, dynamic>))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: quizzes.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, idx) {
            final quiz = quizzes[idx];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: CipherColors.quizBg, borderRadius: BorderRadius.circular(6)),
                        child: Text('Available',
                            style: CipherTextStyles.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: CipherColors.quizText)),
                      ),
                      Text('${quiz.timeLimitMinutes} mins',
                          style: CipherTextStyles.poppins(fontSize: 11, color: Colors.grey[600]!)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(quiz.title, style: CipherTextStyles.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${quiz.questions.length} Questions',
                      style: CipherTextStyles.poppins(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => QuizTakingScreen(quiz: quiz)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CipherColors.greenPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text('Start Quiz',
                            style: CipherTextStyles.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// ---------- CREATE QUIZ ----------
class CreateQuizScreen extends StatefulWidget {
  final GroupModel group;
  final AppUser currentUser;
  const CreateQuizScreen({super.key, required this.group, required this.currentUser});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _QuestionDraft {
  final TextEditingController questionCtrl = TextEditingController();
  final List<TextEditingController> optionCtrls =
      List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;

  void dispose() {
    questionCtrl.dispose();
    for (final c in optionCtrls) {
      c.dispose();
    }
  }
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _titleCtrl = TextEditingController();
  final _timeLimitCtrl = TextEditingController(text: '10');
  final List<_QuestionDraft> _questions = [_QuestionDraft()];
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timeLimitCtrl.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() => setState(() => _questions.add(_QuestionDraft()));

  void _removeQuestion(int idx) {
    if (_questions.length == 1) return;
    setState(() {
      _questions[idx].dispose();
      _questions.removeAt(idx);
    });
  }

  Future<void> _saveQuiz() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _showError('Please enter a quiz title.');
      return;
    }
    for (final q in _questions) {
      if (q.questionCtrl.text.trim().isEmpty) {
        _showError('Every question needs question text.');
        return;
      }
      for (final o in q.optionCtrls) {
        if (o.text.trim().isEmpty) {
          _showError('Every option must be filled in.');
          return;
        }
      }
    }

    setState(() => _saving = true);
    try {
      final docRef = FirebaseFirestore.instance.collection('quizzes').doc();
      final questions = _questions.asMap().entries.map((entry) {
        final i = entry.key;
        final q = entry.value;
        return QuestionModel(
          id: '${docRef.id}_q$i',
          questionText: q.questionCtrl.text.trim(),
          options: q.optionCtrls.map((c) => c.text.trim()).toList(),
          correctOptionIndex: q.correctIndex,
        );
      }).toList();

      final quiz = QuizModel(
        id: docRef.id,
        groupId: widget.group.id,
        title: title,
        createdBy: widget.currentUser.username,
        createdAt: DateTime.now(),
        timeLimitMinutes: int.tryParse(_timeLimitCtrl.text.trim()) ?? 10,
        questions: questions,
      );

      await docRef.set(quiz.toMap());

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to save quiz: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CipherColors.background,
      appBar: AppBar(
        backgroundColor: CipherColors.greenPrimary,
        elevation: 0,
        title: Text('Create Quiz', style: CipherTextStyles.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'Quiz Title',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _timeLimitCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Time Limit (minutes)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          ..._questions.asMap().entries.map((entry) => _buildQuestionCard(entry.key, entry.value)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add_rounded, color: CipherColors.greenPrimary),
            label: Text('Add Question', style: CipherTextStyles.poppins(color: CipherColors.greenPrimary, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CipherColors.greenPrimary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: CipherColors.greenPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Save Quiz', style: CipherTextStyles.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int idx, _QuestionDraft q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${idx + 1}', style: CipherTextStyles.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
              if (_questions.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  onPressed: () => _removeQuestion(idx),
                ),
            ],
          ),
          TextField(
            controller: q.questionCtrl,
            decoration: InputDecoration(
              hintText: 'Enter question text',
              filled: true,
              fillColor: CipherColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(4, (optIdx) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Radio<int>(
                    value: optIdx,
                    groupValue: q.correctIndex,
                    activeColor: CipherColors.greenPrimary,
                    onChanged: (v) => setState(() => q.correctIndex = v!),
                  ),
                  Expanded(
                    child: TextField(
                      controller: q.optionCtrls[optIdx],
                      decoration: InputDecoration(
                        hintText: 'Option ${optIdx + 1}',
                        isDense: true,
                        filled: true,
                        fillColor: CipherColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Text('Tap the circle next to the correct answer',
              style: CipherTextStyles.poppins(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

/// ---------- TAKE QUIZ ----------
class QuizTakingScreen extends StatefulWidget {
  final QuizModel quiz;
  const QuizTakingScreen({super.key, required this.quiz});

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int currentIdx = 0;
  int? selectedAnswerIndex;
  int score = 0;
  late int secondsRemaining;

  @override
  void initState() {
    super.initState();
    secondsRemaining = widget.quiz.timeLimitMinutes * 60;
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Quiz Complete!', style: CipherTextStyles.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'You scored $score out of ${widget.quiz.questions.length}',
          style: CipherTextStyles.poppins(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CipherColors.greenPrimary),
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // leave quiz
            },
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _next() {
    final question = widget.quiz.questions[currentIdx];
    if (selectedAnswerIndex == question.correctOptionIndex) {
      score++;
    }
    if (currentIdx < widget.quiz.questions.length - 1) {
      setState(() {
        currentIdx++;
        selectedAnswerIndex = null;
      });
    } else {
      _showResultDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[currentIdx];
    return Scaffold(
      backgroundColor: CipherColors.background,
      appBar: AppBar(
        title: Text(widget.quiz.title, style: CipherTextStyles.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: CipherColors.greenPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question ${currentIdx + 1}/${widget.quiz.questions.length}',
                style: CipherTextStyles.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]!)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Text(question.questionText,
                  style: CipherTextStyles.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: question.options.length,
                itemBuilder: (context, idx) {
                  final isSelected = selectedAnswerIndex == idx;
                  return GestureDetector(
                    onTap: () => setState(() => selectedAnswerIndex = idx),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? CipherColors.quizBg : Colors.white,
                        border: Border.all(
                          color: isSelected ? CipherColors.greenPrimary : Colors.grey[200]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: isSelected ? CipherColors.greenPrimary : Colors.grey,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(question.options[idx],
                                style: CipherTextStyles.poppins(fontSize: 14, color: Colors.black87)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedAnswerIndex == null ? null : _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CipherColors.greenPrimary,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  currentIdx < widget.quiz.questions.length - 1 ? 'Next Question' : 'Submit Test',
                  style: CipherTextStyles.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}