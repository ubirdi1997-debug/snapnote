import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/voice_service.dart';
import 'camera_screen.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;

  const NoteEditorScreen({super.key, this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _textController = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  String _listeningText = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVoice();
    _loadNote();
  }

  Future<void> _initializeVoice() async {
    final initialized = await _voiceService.initialize();
    setState(() {
      _isInitialized = initialized;
    });
  }

  void _loadNote() {
    if (widget.noteId != null) {
      final note = context.read<NotesProvider>().getNoteById(widget.noteId!);
      if (note != null) {
        _textController.text = note.content;
      }
    }
  }

  Future<void> _startVoiceInput() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice notes'),
          ),
        );
      }
      return;
    }

    if (!_isInitialized) {
      await _initializeVoice();
    }

    if (!_voiceService.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
      _listeningText = '';
    });

    await _voiceService.startListening(
      onResult: (text) {
        setState(() {
          _listeningText = text;
        });
      },
      onDone: () {
        setState(() {
          _isListening = false;
          if (_listeningText.isNotEmpty) {
            final currentText = _textController.text;
            _textController.text = currentText.isEmpty
                ? _listeningText
                : '$currentText\n$_listeningText';
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          }
          _listeningText = '';
        });
      },
    );
  }

  Future<void> _stopVoiceInput() async {
    await _voiceService.stopListening();
    setState(() {
      _isListening = false;
      if (_listeningText.isNotEmpty) {
        final currentText = _textController.text;
        _textController.text = currentText.isEmpty
            ? _listeningText
            : '$currentText\n$_listeningText';
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
      _listeningText = '';
    });
  }

  Future<void> _openCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required for text scanning'),
        ),
      );
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );

    if (result != null && result is String && result.isNotEmpty) {
      final currentText = _textController.text;
      _textController.text = currentText.isEmpty
          ? result
          : '$currentText\n$result';
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
  }

  Future<void> _saveNote() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final now = DateTime.now();
    final note = widget.noteId != null
        ? context.read<NotesProvider>().getNoteById(widget.noteId!)
        : null;

    final noteToSave = note?.copyWith(
          content: content,
          updatedAt: now,
        ) ??
        Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: content,
          createdAt: now,
          updatedAt: now,
        );

    await context.read<NotesProvider>().saveNote(noteToSave);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _voiceService.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.mic,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _listeningText.isEmpty ? 'Listening...' : _listeningText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: _stopVoiceInput,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Start typing or use voice/camera...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: null,
              expands: true,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.mic,
                label: 'Voice',
                onPressed: _isListening ? _stopVoiceInput : _startVoiceInput,
                isActive: _isListening,
              ),
              _ActionButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onPressed: _openCamera,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

