import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/voice_service.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';
import 'camera_screen.dart';
import 'voice_recording_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  bool _isVoiceInitialized = false;
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    final initialized = await _voiceService.initialize();
    setState(() {
      _isVoiceInitialized = initialized;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _voiceService.cancel();
    super.dispose();
  }

  Future<void> _refreshNotes() async {
    HapticFeedback.lightImpact();
    context.read<NotesProvider>().loadNotes();
  }

  Future<void> _quickVoiceNote() async {
    HapticFeedback.mediumImpact();
    final status = await Permission.microphone.request();
    if (!status.isGranted || !_isVoiceInitialized) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VoiceRecordingScreen()),
    );
  }

  Future<void> _quickCameraNote() async {
    HapticFeedback.mediumImpact();
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission required')),
      );
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );

    if (result != null && result is String && result.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoteEditorScreen(initialBody: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0D2E), // Dark purple background
      appBar: AppBar(
        title: const Text('SnapNote Voice'),
        backgroundColor: const Color(0xFF1A0D2E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF9D7CE8),
          labelColor: const Color(0xFF9D7CE8),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Notes'),
            Tab(text: 'Lists'),
            Tab(text: 'Recordings'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF9D7CE8).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search note',
                  hintStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  context.read<NotesProvider>().setSearchQuery(value);
                },
              ),
            ),
          ),
          // Content based on tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotesTab(),
                _buildListsTab(),
                _buildRecordingsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "voice",
            onPressed: _quickVoiceNote,
            backgroundColor: const Color(0xFF9D7CE8),
            child: const Icon(Icons.mic, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "camera",
            onPressed: _quickCameraNote,
            backgroundColor: const Color(0xFF6B46C1),
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "add",
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NoteEditorScreen(),
                ),
              );
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.add, color: Color(0xFF1A0D2E)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        final notes = provider.notes.where((note) => note.todoItems.isEmpty).toList();

        if (notes.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshNotes,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_add_outlined,
                        size: 64,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.searchQuery.isEmpty
                            ? 'No notes yet\nTap + to create your first note'
                            : 'No notes found',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshNotes,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteTile(note: note);
            },
          ),
        );
      },
    );
  }

  Widget _buildListsTab() {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        final lists = provider.notes.where((note) => note.todoItems.isNotEmpty).toList();

        if (lists.isEmpty) {
          return Center(
            child: Text(
              'No lists yet',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshNotes,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final note = lists[index];
              return _NoteTile(note: note);
            },
          ),
        );
      },
    );
  }

  Widget _buildRecordingsTab() {
    return Center(
      child: Text(
        'Recordings will appear here',
        style: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final Note note;

  const _NoteTile({required this.note});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  String _getPreview() {
    if (note.body.isEmpty) {
      return note.title.isEmpty ? '' : '';
    }
    
    final lines = note.body.split('\n');
    if (lines.length <= 2) {
      return note.body;
    }
    
    return lines.take(2).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = note.title.isNotEmpty ? note.title : 'Untitled';
    final preview = _getPreview();
    final noteColor = note.color;

    return Card(
      elevation: 0,
      color: noteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteEditorScreen(noteId: note.id),
            ),
          );
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF2D1B4E),
              title: const Text('Delete Note', style: TextStyle(color: Colors.white)),
              content: const Text('Are you sure you want to delete this note?', style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.read<NotesProvider>().deleteNote(note.id);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isPinned)
                    const Icon(
                      Icons.push_pin,
                      size: 16,
                      color: Colors.black54,
                    ),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    preview,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: note.tags.take(2).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const Spacer(),
              if (note.todoItems.isNotEmpty)
                Text(
                  '${note.todoItems.where((item) => item.isCompleted).length}/${note.todoItems.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
