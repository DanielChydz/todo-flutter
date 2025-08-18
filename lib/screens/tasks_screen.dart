import 'package:flutter/material.dart';
import '../models/task.dart';
import '../db/tasks_db.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> tasks = <Task>[];
  bool _loading = true;

  final TextEditingController _titleCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Twoje zadania")),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (tasks.isEmpty
                ? const Center(
                    child: Text("Brak zadań. Kliknij +, by dodać pierwsze"),
                  )
                : ListView.builder(
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
                  )),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _addTask(String title) async {
    final taskTitle = title.trim();
    if (taskTitle.isEmpty) return;

    final task = Task(
      title: taskTitle,
      deadLine: (DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch + 360000,
      )).toIso8601String(),
      isDone: false,
    );

    await TasksDb.instance.insertTask(task);

    setState(() {
      tasks.add(task);
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

  Future<void> _loadTasks() async {
    try {
      final loaded = await TasksDb.instance.getAllTasks();
      setState(() {
        tasks = loaded;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error when loading tasks: $e");
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }
}
