import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/storage_service.dart';

class NotesProvider with ChangeNotifier {
  final StorageService _storageService;
  List<Note> _notes = [];
  String _searchQuery = '';
  String? _selectedTag;

  NotesProvider(this._storageService) {
    loadNotes();
  }

  List<Note> get notes {
    var filteredNotes = _notes;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredNotes = filteredNotes
          .where((note) =>
              note.title.toLowerCase().contains(query) ||
              note.body.toLowerCase().contains(query))
          .toList();
    }

    // Apply tag filter
    if (_selectedTag != null) {
      filteredNotes = filteredNotes
          .where((note) => note.tags.contains(_selectedTag))
          .toList();
    }

    return filteredNotes;
  }

  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;

  List<String> get allTags {
    final tags = <String>{};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  void loadNotes() {
    _notes = _storageService.getAllNotes();
    // Sort: pinned first, then by updated date
    _notes.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    notifyListeners();
  }

  Future<void> saveNote(Note note) async {
    await _storageService.saveNote(note);
    loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _storageService.deleteNote(id);
    loadNotes();
  }

  Note? getNoteById(String id) {
    return _storageService.getNote(id);
  }
}

