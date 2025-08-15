import 'package:flutter/material.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<String> tasks = ["Skończyć taska", "Kupić mleko"];
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
        itemBuilder: (context, i) => ListTile(title: Text(tasks[i])),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _addTask(String title) {
    final task = title.trim();
    if (task.isEmpty) return;
    setState(() => tasks.add(task));
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
