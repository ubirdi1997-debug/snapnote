import 'package:hive/hive.dart';

class Note extends HiveObject {
  String id;
  String content;
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    final map = {
      'id': reader.readString(),
      'content': reader.readString(),
      'createdAt': reader.readString(),
      'updatedAt': reader.readString(),
    };
    return Note.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    final map = obj.toMap();
    writer.writeString(map['id'] as String);
    writer.writeString(map['content'] as String);
    writer.writeString(map['createdAt'] as String);
    writer.writeString(map['updatedAt'] as String);
  }
}

