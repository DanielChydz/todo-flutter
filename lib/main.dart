import 'package:flutter/material.dart';
import 'package:todo_flutter/screens/tasks_screen.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: "Todo app", home: TasksScreen());
  }
}
