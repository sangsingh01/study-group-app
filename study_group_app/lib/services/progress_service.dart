// lib/services/progress_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/study_models.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressService extends WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  Timer? _studyTimer;
  bool _isTracking = false;

  ProgressService({required this.userId});

  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void stopTracking() {
    _studyTimer?.cancel();
    _isTracking = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  void _startTimer() {
    _studyTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      updateStudyTime(1);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _studyTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startTimer();
    }
  }

  Future<void> updateStudyTime(int minutes) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final docRef = _firestore.collection('progress').doc(userId).collection('daily').doc(today);
      
      await docRef.set({
        'studyMinutes': FieldValue.increment(minutes),
        'date': today,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error writing engine parameters: $e');
    }
  }

  Future<void> logTaskCompletion() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _firestore.collection('progress').doc(userId).collection('daily').doc(today).set({
      'tasksCompleted': FieldValue.increment(1),
    }, SetOptions(merge: true));
    await addXP(20, "Completed Task");
  }

  Future<void> addXP(int xp, String reason) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userRef = _firestore.collection('users').doc(userId);
    
    await _firestore.runTransaction((tx) async {
      tx.update(userRef, {'xpPoints': FieldValue.increment(xp)});
    });
    
    await _firestore.collection('progress').doc(userId).collection('daily').doc(today).set({
      'xpEarned': FieldValue.increment(xp),
    }, SetOptions(merge: true));

    XpPopupOverlay.show(xp);
  }

  Stream<List<ProgressModel>> getWeeklyProgress() {
    final dates = List.generate(7, (i) => DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: i))));
    return _firestore
        .collection('progress')
        .doc(userId)
        .collection('daily')
        .where('date', whereIn: dates)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ProgressModel.fromMap(doc.data())).toList());
  }
}

class XpPopupOverlay {
  static void show(int xp) {
    final overlayState = Overlay.of((WidgetsBinding.instance.rootElement!));
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _XpPopupAnimation(
        xp: xp,
        onAnimationComplete: () => overlayEntry.remove(),
      ),
    );
    overlayState.insert(overlayEntry);
  }
}

class _XpPopupAnimation extends StatefulWidget {
  final int xp;
  final VoidCallback onAnimationComplete;
  const _XpPopupAnimation({required this.xp, required this.onAnimationComplete});

  @override
  State<_XpPopupAnimation> createState() => _XpPopupAnimationState();
}

class _XpPopupAnimationState extends State<_XpPopupAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _slide = Tween<double>(begin: 100.0, end: -50.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward().then((_) => widget.onAnimationComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.3 + _slide.value,
      left: MediaQuery.of(context).size.width * 0.5 - 60,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _opacity.value,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text('+${widget.xp} XP', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}