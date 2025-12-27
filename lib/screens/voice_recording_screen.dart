import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/voice_service.dart';
import 'note_editor_screen.dart';

class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  final VoiceService _voiceService = VoiceService();
  final TextEditingController _titleController = TextEditingController(text: 'New voice note');
  bool _isRecording = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  List<double> _waveformData = [];
  int _currentPosition = 0;

  @override
  void initState() {
    super.initState();
    _initializeVoice();
    _generateWaveform();
  }

  void _generateWaveform() {
    // Generate sample waveform data
    _waveformData = List.generate(100, (index) {
      return (20 + (index % 10) * 5).toDouble();
    });
  }

  Future<void> _initializeVoice() async {
    final initialized = await _voiceService.initialize();
    setState(() {
      _isInitialized = initialized;
    });
  }

  void _startRecording() {
    if (!_isInitialized) return;

    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
      _currentPosition = 40; // Start at 40:00 as shown in image
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        _currentPosition++;
        // Generate random waveform data
        _waveformData = List.generate(100, (index) {
          return (15 + (index % 15) * 3 + (timer.tick % 10)).toDouble();
        });
      });
    });

    _voiceService.startListening(
      onResult: (text) {
        setState(() {
          _recognizedText = text;
        });
      },
      onDone: () {
        _stopRecording();
      },
    );
  }

  void _stopRecording() {
    _timer?.cancel();
    _voiceService.stopListening();
    setState(() {
      _isRecording = false;
    });
  }

  void _saveRecording() {
    HapticFeedback.mediumImpact();
    if (_recognizedText.isNotEmpty || _recordingDuration.inSeconds > 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NoteEditorScreen(
            initialBody: _recognizedText,
            initialTitle: _titleController.text,
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _voiceService.cancel();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B4E), // Dark purple background
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _saveRecording,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'New voice note',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                // Waveform
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    children: [
                      // Baseline
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 60,
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE0B0FF), // Light purple
                        ),
                      ),
                      // Waveform bars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(_waveformData.length, (index) {
                          final height = _waveformData[index];
                          final isActive = (index - _currentPosition).abs() < 5;
                          return Container(
                            width: 2,
                            height: height,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF6B46C1) // Dark purple
                                  : const Color(0xFF6B46C1).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          );
                        }),
                      ),
                      // Position indicator
                      Positioned(
                        left: MediaQuery.of(context).size.width / 2 - 1,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: Colors.red,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Timeline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        '39:00',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                      Text(
                        '40:00',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                      Text(
                        '41:00',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Timer
                Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, size: 32),
                        onPressed: () {},
                        color: Colors.black,
                      ),
                      GestureDetector(
                        onTap: _isRecording ? _stopRecording : _startRecording,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B46C1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isRecording ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10, size: 32),
                        onPressed: () {},
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

