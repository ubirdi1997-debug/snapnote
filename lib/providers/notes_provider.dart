import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/storage_service.dart';

class NotesProvider with ChangeNotifier {
  final StorageService _storageService;
  List<Note> _notes = [];
  String _searchQuery = '';

  NotesProvider(this._storageService) {
    loadNotes();
  }

  List<Note> get notes {
    if (_searchQuery.isEmpty) {
      return _notes;
    }
    return _notes
        .where((note) =>
            note.content.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void loadNotes() {
    _notes = _storageService.getAllNotes();
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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

