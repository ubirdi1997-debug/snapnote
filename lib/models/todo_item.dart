class TodoItem {
  String id;
  String text;
  bool isCompleted;
  int order;

  TodoItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
    required this.order,
  });

  TodoItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
    int? order,
  }) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isCompleted': isCompleted,
      'order': order,
    };
  }

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as String,
      text: map['text'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
      order: map['order'] as int? ?? 0,
    );
  }
}

