import 'package:flutter/material.dart';
import '../models//task.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<Task> tasks = <Task>[
    Task(id: 1, title: 'Kupić mleko', deadLine: DateTime(2025, 08, 15, 19)),
    Task(
      id: 2,
      title: 'Napisać kod w Flutterze',
      deadLine: DateTime(2025, 08, 15, 19),
      isDone: true,
    ),
  ];

  final TextEditingController _titleCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Twoje zadania")),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, i) {
          final task = tasks[i];
          return CheckboxListTile(
            value: task.isDone,
            onChanged: (_) {
              setState(() {
                tasks[i] = task.copyWith(isDone: !task.isDone);
              });
            },
            title: Text(
              task.title,
              style: task.isDone
                  ? const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _addTask(String title) {
    final taskTitle = title.trim();
    if (taskTitle.isEmpty) return;
    setState(() {
      tasks.add(
        Task(
          id: DateTime.now().millisecondsSinceEpoch,
          title: taskTitle,
          deadLine: DateTime.fromMillisecondsSinceEpoch(
            DateTime.now().millisecondsSinceEpoch + 360000,
          ),
          isDone: false,
        ),
      );
    });
  }

  Future<void> _openAddDialog() async {
    _titleCtrl.clear();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nowe zadanie"),
          content: TextField(
            controller: _titleCtrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Wpisz tytuł"),
            onSubmitted: (_) {
              Navigator.of(context).pop();
              _addTask(_titleCtrl.text);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Anuluj"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addTask(_titleCtrl.text);
              },
              child: const Text("Dodaj"),
            ),
          ],
        );
      },
    );
  }
}
