import 'package:flutter/material.dart';
import '../models/task.dart';
import '../db/tasks_db.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> _tasks = <Task>[];
  bool _loading = true;

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Twoje zadania")),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_tasks.isEmpty
                ? const Center(
                    child: Text("Brak zadań. Kliknij +, by dodać pierwsze"),
                  )
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, i) {
                      final task = _tasks[i];
                      return CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        value: task.isDone,
                        onChanged: (_) async {
                          setState(() {
                            _tasks[i] = task.copyWith(isDone: !task.isDone);
                          });
                          try {
                            await TasksDb.instance.updateTask(_tasks[i]);
                          } catch (e) {
                            debugPrint("Error when updating task: $e");
                          }
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if ((task.description ?? "").isNotEmpty)
                              Text(
                                task.description!,
                                style: task.isDone
                                    ? const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      )
                                    : const TextStyle(color: Colors.black54),
                              ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDeadline(task.deadLine),
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        secondary: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.grey,
                          ),
                          splashRadius: 18,
                          tooltip: 'Edytuj',
                          onPressed: () => _openEditDialog(task),
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

  Future<void> _addTask(String title, String description) async {
    final taskTitle = title.trim();
    final taskDescription = description.trim();
    if (taskTitle.isEmpty) return;

    final task = Task(
      title: taskTitle,
      description: taskDescription,
      deadLine: (DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch + 360000,
      )).toIso8601String(),
      isDone: false,
    );

    await TasksDb.instance.insertTask(task);

    setState(() {
      _tasks.add(task);
    });
  }

  Future<void> _openTaskDialog(
    Task? currentTask,
    String dialogTitle,
    String confirmLabel,
  ) async {
    _titleCtrl.clear();
    _descCtrl.clear();
    if (currentTask != null) {
      _titleCtrl.text = currentTask.title;
      _descCtrl.text = currentTask.description ?? "";
    }
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(hintText: "Wpisz tytuł"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  hintText: "Dodaj opis (opcjonalnie)",
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Anuluj"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addTask(_titleCtrl.text, _descCtrl.text);
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCreateDialog() async {
    await _openTaskDialog(null, "Nowe zadanie", "Dodaj");
  }

  Future<void> _openEditDialog(Task task) async {
    await _openTaskDialog(task, "Edytuj zadanie", "Zapisz");
  }

  Future<void> _loadTasks() async {
    try {
      final loaded = await TasksDb.instance.getAllTasks();
      setState(() {
        _tasks = loaded;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error when loading tasks: $e");
      setState(() => _loading = false);
    }
  }

  String _formatDeadline(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final local = dt.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return 'Termin: ${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
    } catch (_) {
      return 'Termin: $iso';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }
}
