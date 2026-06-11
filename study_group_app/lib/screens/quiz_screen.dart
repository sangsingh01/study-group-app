// lib/screens/quiz_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/design_system.dart';
import '../models/study_models.dart';

class QuizListScreen extends StatelessWidget {
  final String currentUid;
  const QuizListScreen({super.key, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CipherColors.background,
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
        gradient: CipherColors.headerGradient, // Matches the global standard header style
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
                Text('Active Quizzes', style: CipherTextStyles.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Test your knowledge and claim XP awards', style: CipherTextStyles.poppins(fontSize: 13, color: Colors.white, alpha: 0.8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: CipherColors.greenPrimary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No active tests found at this time.', style: CipherTextStyles.poppins(color: Colors.grey)),
          );
        }
        
        final quizzes = snapshot.data!.docs.map((d) => QuizModel.fromMap(d.data() as Map<String, dynamic>)).toList();

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
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: CipherColors.quizBg, 
                          borderRadius: BorderRadius.circular(6)
                        ),
                        child: Text(
                          "Available", 
                          style: CipherTextStyles.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: CipherColors.quizText)
                        ),
                      ),
                      Text(
                        '${quiz.timeLimitMinutes} mins', 
                        style: CipherTextStyles.poppins(fontSize: 11, color: Colors.grey[600]!)
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(quiz.title, style: CipherTextStyles.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${quiz.questions.length} Questions structured', style: CipherTextStyles.poppins(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('XP Reward: 200 pts', style: CipherTextStyles.poppins(fontSize: 11, color: Colors.grey[600]!, fontWeight: FontWeight.w500)),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizTakingScreen(quiz: quiz))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CipherColors.greenPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text('Start Quiz', style: CipherTextStyles.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
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

class QuizTakingScreen extends StatefulWidget {
  final QuizModel quiz;
  const QuizTakingScreen({super.key, required this.quiz});

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int currentIdx = 0;
  int? selectedAnswerIndex;
  bool isAnswerRevealed = false;
  int secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    secondsRemaining = widget.quiz.timeLimitMinutes * 60;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
      } else {
        _timer?.cancel();
        _evaluateAndExit();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _evaluateAndExit() {
    Navigator.pop(context);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${currentIdx + 1}/${widget.quiz.questions.length}', 
                  style: CipherTextStyles.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]!)
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_rounded, color: Colors.red, size: 14),
                      const SizedBox(width: 4),
                      Text('$secondsRemaining s', style: CipherTextStyles.poppins(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
              ),
              child: Text(
                question.questionText, 
                style: CipherTextStyles.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)
              ),
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
                  onTap: isAnswerRevealed ? null : () => setState(() => selectedAnswerIndex = idx),
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
                      boxShadow: isSelected ? [BoxShadow(color: CipherColors.greenPrimary.withValues(alpha: 0.15), blurRadius: 4)] : null
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? CipherColors.greenPrimary : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            question.options[idx], 
                            style: CipherTextStyles.poppins(
                              fontSize: 14, 
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? CipherColors.quizText : Colors.black87
                            )
                          ),
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
                onPressed: selectedAnswerIndex == null ? null : () {
                  if (currentIdx < widget.quiz.questions.length - 1) {
                    setState(() {
                      currentIdx++;
                      selectedAnswerIndex = null;
                    });
                  } else {
                    _evaluateAndExit();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CipherColors.greenPrimary,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  currentIdx < widget.quiz.questions.length - 1 ? "Next Question" : "Submit Test", 
                  style: CipherTextStyles.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}