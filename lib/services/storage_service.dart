import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';

class StorageService {
  static const String _notesBoxName = 'notes';
  Box<Note>? _notesBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(NoteAdapter());
    _notesBox = await Hive.openBox<Note>(_notesBoxName);
  }

  Future<void> saveNote(Note note) async {
    await _notesBox?.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await _notesBox?.delete(id);
  }

  List<Note> getAllNotes() {
    return _notesBox?.values.toList() ?? [];
  }

  Note? getNote(String id) {
    return _notesBox?.get(id);
  }

  Future<void> clearAllNotes() async {
    await _notesBox?.clear();
  }
}

