import 'dart:async';
import 'package:flutter/material.dart';
import '../services/study_session_service.dart';

class StudyTimerScreen extends StatefulWidget {
  final String groupId;
  final String userId;

  const StudyTimerScreen({
    super.key,
    required this.groupId,
    required this.userId,
  });

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen> {
  final StudySessionService _service = StudySessionService();

  bool _isRunning = false;
  String? _currentSessionId;
  DateTime? _startTime;
  int _elapsedSeconds = 0;
  Timer? _ticker;

  void _startTimer() async {
    final sessionId = await _service.startSession(
      groupId: widget.groupId,
      userId: widget.userId,
    );
    setState(() {
      _isRunning = true;
      _currentSessionId = sessionId;
      _startTime = DateTime.now();
      _elapsedSeconds = 0;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  void _stopTimer() async {
    _ticker?.cancel();
    if (_currentSessionId != null && _startTime != null) {
      await _service.stopSession(_currentSessionId!, _startTime!);
    }
    setState(() {
      _isRunning = false;
      _currentSessionId = null;
      _startTime = null;
      _elapsedSeconds = 0;
    });
  }

  String _format(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Timer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              _format(_elapsedSeconds),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRunning ? _stopTimer : _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRunning ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: Text(
                _isRunning ? 'Stop Studying' : 'Start Studying',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 10),
            StreamBuilder<int>(
              stream: _service.watchTodayTotalSeconds(widget.groupId, widget.userId),
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0;
                return Text('Today: ${_format(total)}', style: const TextStyle(fontSize: 16));
              },
            ),
            const SizedBox(height: 8),
            StreamBuilder<int>(
              stream: _service.watchWeekTotalSeconds(widget.groupId, widget.userId),
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0;
                return Text('This week: ${_format(total)}', style: const TextStyle(fontSize: 16));
              },
            ),
            const SizedBox(height: 8),
            StreamBuilder<int>(
              stream: _service.watchCurrentStreak(widget.groupId, widget.userId),
              builder: (context, snapshot) {
                final streak = snapshot.data ?? 0;
                return Text(
                  streak > 0 ? '🔥 $streak day streak' : 'No streak yet — start today!',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}