class Task {
  final int? id;
  final String title;
  final String? description;
  final DateTime deadLine;
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
    DateTime? deadLine,
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
}
