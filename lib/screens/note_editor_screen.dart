import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/note.dart';
import '../models/todo_item.dart';
import '../providers/notes_provider.dart';
import '../services/voice_service.dart';
import '../utils/colors.dart';
import 'camera_screen.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  final String? initialBody;
  final String? initialTitle;

  const NoteEditorScreen({super.key, this.noteId, this.initialBody, this.initialTitle});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  String _listeningText = '';
  bool _isInitialized = false;
  
  // Undo/Redo
  final List<Map<String, String>> _undoStack = [];
  final List<Map<String, String>> _redoStack = [];
  bool _isUndoRedoOperation = false;
  
  // Lock
  bool _isLocked = false;
  DateTime? _lockedAt;
  
  // New features
  bool _isPinned = false;
  List<String> _tags = [];
  int _colorValue = 0xFFFFFFFF;
  List<String> _imagePaths = [];
  List<TodoItem> _todoItems = [];
  final TextEditingController _tagController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeVoice();
    _loadNote();
    _setupUndoRedo();
    if (widget.initialBody != null) {
      _bodyController.text = widget.initialBody!;
    }
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
  }

  void _setupUndoRedo() {
    _titleController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
    _saveState();
  }

  void _onTextChanged() {
    if (!_isUndoRedoOperation) {
      _saveState();
    }
  }

  void _saveState() {
    _undoStack.add({
      'title': _titleController.text,
      'body': _bodyController.text,
    });
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.length > 1) {
      _isUndoRedoOperation = true;
      _redoStack.add(_undoStack.removeLast());
      final state = _undoStack.last;
      _titleController.text = state['title'] ?? '';
      _bodyController.text = state['body'] ?? '';
      _isUndoRedoOperation = false;
      HapticFeedback.lightImpact();
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _isUndoRedoOperation = true;
      final state = _redoStack.removeLast();
      _undoStack.add(state);
      _titleController.text = state['title'] ?? '';
      _bodyController.text = state['body'] ?? '';
      _isUndoRedoOperation = false;
      HapticFeedback.lightImpact();
    }
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
        _titleController.text = note.title;
        _bodyController.text = note.body;
        setState(() {
          _isLocked = note.isLocked;
          _lockedAt = note.lockedAt;
          _isPinned = note.isPinned;
          _tags = List.from(note.tags);
          _colorValue = note.colorValue;
          _imagePaths = List.from(note.imagePaths);
          _todoItems = List.from(note.todoItems);
        });
      }
    }
  }

  Future<void> _startVoiceInput() async {
    HapticFeedback.mediumImpact();
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for voice notes'),
        ),
      );
      return;
    }

    if (!_isInitialized) {
      await _initializeVoice();
    }

    if (!_voiceService.isAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available'),
        ),
      );
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
            final currentBody = _bodyController.text;
            _bodyController.text = currentBody.isEmpty
                ? _listeningText
                : '$currentBody\n$_listeningText';
            _bodyController.selection = TextSelection.fromPosition(
              TextPosition(offset: _bodyController.text.length),
            );
          }
          _listeningText = '';
        });
        HapticFeedback.mediumImpact();
      },
    );
  }

  Future<void> _stopVoiceInput() async {
    await _voiceService.stopListening();
    setState(() {
      _isListening = false;
      if (_listeningText.isNotEmpty) {
        final currentBody = _bodyController.text;
        _bodyController.text = currentBody.isEmpty
            ? _listeningText
            : '$currentBody\n$_listeningText';
        _bodyController.selection = TextSelection.fromPosition(
          TextPosition(offset: _bodyController.text.length),
        );
      }
      _listeningText = '';
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _openCamera() async {
    HapticFeedback.mediumImpact();
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
      final currentBody = _bodyController.text;
      _bodyController.text = currentBody.isEmpty
          ? result
          : '$currentBody\n$result';
      _bodyController.selection = TextSelection.fromPosition(
        TextPosition(offset: _bodyController.text.length),
      );
      HapticFeedback.mediumImpact();
    }
  }

  void _toggleLock() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLocked = !_isLocked;
      _lockedAt = _isLocked ? DateTime.now() : null;
    });
  }

  void _togglePin() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isPinned = !_isPinned;
    });
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
      });
      _tagController.clear();
      HapticFeedback.lightImpact();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    HapticFeedback.lightImpact();
  }

  void _changeColor(Color color) {
    setState(() {
      _colorValue = color.value;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _pickImageFromGallery() async {
    HapticFeedback.mediumImpact();
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imagePaths.add(image.path);
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  void _addTodoItem() {
    setState(() {
      _todoItems.add(TodoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '',
        isCompleted: false,
        order: _todoItems.length,
      ));
    });
    HapticFeedback.lightImpact();
  }

  void _updateTodoItem(int index, String text) {
    setState(() {
      _todoItems[index] = _todoItems[index].copyWith(text: text);
    });
  }

  void _toggleTodoItem(int index) {
    setState(() {
      _todoItems[index] = _todoItems[index].copyWith(
        isCompleted: !_todoItems[index].isCompleted,
      );
    });
    HapticFeedback.lightImpact();
  }

  void _removeTodoItem(int index) {
    setState(() {
      _todoItems.removeAt(index);
      // Reorder remaining items
      for (int i = 0; i < _todoItems.length; i++) {
        _todoItems[i] = _todoItems[i].copyWith(order: i);
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _shareNote() async {
    HapticFeedback.mediumImpact();
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    
    if (title.isEmpty && body.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note is empty')),
      );
      return;
    }

    final content = title.isEmpty 
        ? body 
        : body.isEmpty 
            ? title 
            : '$title\n\n$body';

    await Share.share(content);
  }

  int _getWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  int _getCharacterCount(String text) {
    return text.length;
  }

  Future<void> _saveNote() async {
    HapticFeedback.mediumImpact();
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    
    if (title.isEmpty && body.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final now = DateTime.now();
    final note = widget.noteId != null
        ? context.read<NotesProvider>().getNoteById(widget.noteId!)
        : null;

    final noteToSave = note?.copyWith(
          title: title,
          body: body,
          updatedAt: now,
          isLocked: _isLocked,
          lockedAt: _lockedAt,
          isPinned: _isPinned,
          tags: _tags,
          colorValue: _colorValue,
          imagePaths: _imagePaths,
          todoItems: _todoItems,
        ) ??
        Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          body: body,
          createdAt: now,
          updatedAt: now,
          isLocked: _isLocked,
          lockedAt: _lockedAt,
          isPinned: _isPinned,
          tags: _tags,
          colorValue: _colorValue,
          imagePaths: _imagePaths,
          todoItems: _todoItems,
        );

    await context.read<NotesProvider>().saveNote(noteToSave);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    _voiceService.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalText = '${_titleController.text} ${_bodyController.text}';
    final wordCount = _getWordCount(totalText);
    final charCount = _getCharacterCount(totalText);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(_colorValue),
        title: Text(widget.noteId == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: _togglePin,
            tooltip: _isPinned ? 'Unpin note' : 'Pin note',
            color: _isPinned ? Theme.of(context).colorScheme.primary : null,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.palette),
            tooltip: 'Change color',
            itemBuilder: (context) => NoteColors.presetColors.map((color) {
              return PopupMenuItem(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _colorValue == color.value
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      width: _colorValue == color.value ? 3 : 1,
                    ),
                  ),
                ),
                onTap: () => _changeColor(color),
              );
            }).toList(),
          ),
          if (_undoStack.length > 1)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undo,
              tooltip: 'Undo',
            ),
          if (_redoStack.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: _redo,
              tooltip: 'Redo',
            ),
          IconButton(
            icon: Icon(_isLocked ? Icons.lock : Icons.lock_open),
            onPressed: _toggleLock,
            tooltip: _isLocked ? 'Unlock note' : 'Lock note',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareNote,
            tooltip: 'Share note',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
            tooltip: 'Save',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_isLocked,
                  ),
                  const SizedBox(height: 8),
                  // Tags
                  if (_tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          onDeleted: _isLocked ? null : () => _removeTag(tag),
                          deleteIcon: const Icon(Icons.close, size: 18),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Add tag input
                  if (!_isLocked)
                    TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'Add tag (press Enter)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.tag),
                        suffixIcon: _tagController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _addTag(_tagController.text),
                              )
                            : null,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) => _addTag(value),
                      onChanged: (value) => setState(() {}),
                    ),
                  if (!_isLocked) const SizedBox(height: 16),
                  // Todo items
                  if (_todoItems.isNotEmpty) ...[
                    const Text(
                      'To-do List',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_todoItems.length, (index) {
                      final item = _todoItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: item.isCompleted,
                              onChanged: _isLocked
                                  ? null
                                  : (value) => _toggleTodoItem(index),
                            ),
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(text: item.text)
                                  ..selection = TextSelection.collapsed(
                                    offset: item.text.length,
                                  ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'To-do item',
                                ),
                                enabled: !_isLocked,
                                onChanged: (value) => _updateTodoItem(index, value),
                                style: TextStyle(
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (!_isLocked)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _removeTodoItem(index),
                              ),
                          ],
                        ),
                      );
                    }),
                    if (!_isLocked)
                      TextButton.icon(
                        onPressed: _addTodoItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add to-do item'),
                      ),
                    const SizedBox(height: 16),
                  ] else if (!_isLocked) ...[
                    TextButton.icon(
                      onPressed: _addTodoItem,
                      icon: const Icon(Icons.check_box_outlined),
                      label: const Text('Add to-do list'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Images
                  if (_imagePaths.isNotEmpty) ...[
                    const Text(
                      'Images',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePaths.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_imagePaths[index]),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (!_isLocked)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        iconSize: 16,
                                        icon: const Icon(Icons.close, color: Colors.white),
                                        onPressed: () => _removeImage(index),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Body text
                  TextField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      hintText: 'Start typing or use voice/camera...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    expands: false,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_isLocked,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Words: $wordCount | Characters: $charCount',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_isLocked && _lockedAt != null)
                  Text(
                    'Locked ${_formatLockTime(_lockedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
                  _ActionButton(
                    icon: Icons.image,
                    label: 'Gallery',
                    onPressed: _pickImageFromGallery,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLockTime(DateTime lockedAt) {
    final now = DateTime.now();
    final difference = now.difference(lockedAt);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
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
