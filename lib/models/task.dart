class Task {
  final int? id;
  final String title;
  final String? description;
  final String deadLine;
  final bool isDone;

  const Task({
    this.id,
    required this.title,
    this.description,
    required this.deadLine,
    this.isDone = false,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? deadLine,
    bool? isDone,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadLine: deadLine ?? this.deadLine,
      isDone: isDone ?? this.isDone,
    );
  }

  factory Task.fromMap(Map<String, Object?> map) {
    return Task(
      id: map["id"] as int,
      title: map["title"] as String,
      description: map["description"] as String?,
      deadLine: map["deadline"] as String,
      isDone: (map["is_done"] as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      "id": id,
      "title": title,
      "description": description,
      "deadline": deadLine,
      "is_done": isDone ? 1 : 0,
    };
  }
}
