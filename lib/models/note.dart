import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'todo_item.dart';

class Note extends HiveObject {
  String id;
  String title;
  String body;
  DateTime createdAt;
  DateTime updatedAt;
  bool isLocked;
  DateTime? lockedAt;
  bool isPinned;
  List<String> tags;
  int colorValue; // Color value as int
  List<String> imagePaths; // Paths to images
  List<TodoItem> todoItems;

  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.isLocked = false,
    this.lockedAt,
    this.isPinned = false,
    this.tags = const [],
    this.colorValue = 0xFFFFFFFF, // Default white
    this.imagePaths = const [],
    this.todoItems = const [],
  });

  // Legacy support: get content (title + body)
  String get content => title.isEmpty ? body : '$title\n$body';
  
  // Get Color from colorValue
  Color get color => Color(colorValue);

  Note copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLocked,
    DateTime? lockedAt,
    bool? isPinned,
    List<String>? tags,
    int? colorValue,
    List<String>? imagePaths,
    List<TodoItem>? todoItems,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLocked: isLocked ?? this.isLocked,
      lockedAt: lockedAt ?? this.lockedAt,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      colorValue: colorValue ?? this.colorValue,
      imagePaths: imagePaths ?? this.imagePaths,
      todoItems: todoItems ?? this.todoItems,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isLocked': isLocked,
      'lockedAt': lockedAt?.toIso8601String(),
      'isPinned': isPinned,
      'tags': tags,
      'colorValue': colorValue,
      'imagePaths': imagePaths,
      'todoItems': todoItems.map((item) => item.toMap()).toList(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    // Legacy support: if content exists but title/body don't
    String title = map['title'] as String? ?? '';
    String body = map['body'] as String? ?? '';
    
    if (title.isEmpty && body.isEmpty && map['content'] != null) {
      final content = map['content'] as String;
      final lines = content.split('\n');
      if (lines.isNotEmpty) {
        title = lines[0];
        body = lines.length > 1 ? lines.sublist(1).join('\n') : '';
      }
    }
    
    return Note(
      id: map['id'] as String,
      title: title,
      body: body,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isLocked: map['isLocked'] as bool? ?? false,
      lockedAt: map['lockedAt'] != null 
          ? DateTime.parse(map['lockedAt'] as String)
          : null,
      isPinned: map['isPinned'] as bool? ?? false,
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      colorValue: map['colorValue'] as int? ?? 0xFFFFFFFF,
      imagePaths: (map['imagePaths'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      todoItems: (map['todoItems'] as List<dynamic>?)?.map((e) => TodoItem.fromMap(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    try {
      // Try new format
      final id = reader.readString();
      final title = reader.readString();
      final body = reader.readString();
      final createdAt = reader.readString();
      final updatedAt = reader.readString();
      final isLocked = reader.readBool();
      final hasLockedAt = reader.readBool();
      final lockedAt = hasLockedAt ? reader.readString() : null;
      final isPinned = reader.readBool();
      final tagsCount = reader.readInt();
      final tags = List<String>.generate(tagsCount, (_) => reader.readString());
      final colorValue = reader.readInt();
      final imagePathsCount = reader.readInt();
      final imagePaths = List<String>.generate(imagePathsCount, (_) => reader.readString());
      final todoItemsCount = reader.readInt();
      final todoItems = List<TodoItem>.generate(todoItemsCount, (_) {
        final itemId = reader.readString();
        final itemText = reader.readString();
        final itemCompleted = reader.readBool();
        final itemOrder = reader.readInt();
        return TodoItem(id: itemId, text: itemText, isCompleted: itemCompleted, order: itemOrder);
      });
      
      return Note(
        id: id,
        title: title,
        body: body,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        isLocked: isLocked,
        lockedAt: lockedAt != null ? DateTime.parse(lockedAt) : null,
        isPinned: isPinned,
        tags: tags,
        colorValue: colorValue,
        imagePaths: imagePaths,
        todoItems: todoItems,
      );
    } catch (e) {
      // Legacy format support - try reading old format
      try {
        final id = reader.readString();
        final title = reader.readString();
        final body = reader.readString();
        final createdAt = reader.readString();
        final updatedAt = reader.readString();
        final isLocked = reader.readBool();
        final hasLockedAt = reader.readBool();
        final lockedAt = hasLockedAt ? reader.readString() : null;
        
        return Note(
          id: id,
          title: title,
          body: body,
          createdAt: DateTime.parse(createdAt),
          updatedAt: DateTime.parse(updatedAt),
          isLocked: isLocked,
          lockedAt: lockedAt != null ? DateTime.parse(lockedAt) : null,
          isPinned: false,
          tags: [],
          colorValue: 0xFFFFFFFF,
          imagePaths: [],
          todoItems: [],
        );
      } catch (e2) {
        // Very old format with content field
        final id = reader.readString();
        final content = reader.readString();
        final createdAt = reader.readString();
        final updatedAt = reader.readString();
        
        final lines = content.split('\n');
        final title = lines.isNotEmpty ? lines[0] : '';
        final body = lines.length > 1 ? lines.sublist(1).join('\n') : '';
        
        return Note(
          id: id,
          title: title,
          body: body,
          createdAt: DateTime.parse(createdAt),
          updatedAt: DateTime.parse(updatedAt),
          isLocked: false,
          lockedAt: null,
          isPinned: false,
          tags: [],
          colorValue: 0xFFFFFFFF,
          imagePaths: [],
          todoItems: [],
        );
      }
    }
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.body);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
    writer.writeBool(obj.isLocked);
    writer.writeBool(obj.lockedAt != null);
    if (obj.lockedAt != null) {
      writer.writeString(obj.lockedAt!.toIso8601String());
    }
    writer.writeBool(obj.isPinned);
    writer.writeInt(obj.tags.length);
    for (final tag in obj.tags) {
      writer.writeString(tag);
    }
    writer.writeInt(obj.colorValue);
    writer.writeInt(obj.imagePaths.length);
    for (final path in obj.imagePaths) {
      writer.writeString(path);
    }
    writer.writeInt(obj.todoItems.length);
    for (final item in obj.todoItems) {
      writer.writeString(item.id);
      writer.writeString(item.text);
      writer.writeBool(item.isCompleted);
      writer.writeInt(item.order);
    }
  }
}
