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
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.green;
                          }
                        }),
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

  Future<void> _insertOrUpdateTask(Task task) async {
    if (task.id == null) {
      // insert
      final id = await TasksDb.instance.insertTask(task);
      setState(() {
        _tasks.add(task.copyWith(id: id));
      });
    } else {
      // update
      await TasksDb.instance.updateTask(task);
      setState(() {
        final i = _tasks.indexWhere((t) => t.id == task.id);
        if (i != -1) _tasks[i] = task;
      });
    }
    _sortTasksByDeadline();
  }

  Future<void> _saveTask({
    Task? currentTask, // null = new, passed = edit
    required String title,
    required String description,
    required DateTime deadLine,
  }) async {
    final t =
        (currentTask ??
                Task(
                  id: null,
                  title: "",
                  description: null,
                  deadLine: "",
                  isDone: false,
                ))
            .copyWith(
              title: title.trim(),
              description: description.trim().isEmpty
                  ? null
                  : description.trim(),
              deadLine: deadLine.toIso8601String(),
              isDone: currentTask?.isDone ?? false,
            );

    await _insertOrUpdateTask(t);
  }

  Future<void> _openTaskDialog(
    Task? currentTask,
    String dialogTitle,
    String confirmLabel,
  ) async {
    _titleCtrl.clear();
    _descCtrl.clear();

    DateTime? selectedDeadline =
        (currentTask?.deadLine != null && currentTask!.deadLine.isNotEmpty)
        ? DateTime.tryParse(currentTask.deadLine)
        : null;

    if (currentTask != null) {
      _titleCtrl.text = currentTask.title;
      _descCtrl.text = currentTask.description ?? "";
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickDeadline() async {
              final initial = selectedDeadline ?? DateTime.now();

              final pickedDate = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (pickedDate == null) return;

              final TimeOfDay? pickedTime = await showTimePicker(
                // dev note: warning acknowledged, guarded with a "mounted" check
                context: context,
                initialTime: TimeOfDay.fromDateTime(initial),
                builder: (context, child) => child ?? const SizedBox.shrink(),
              );
              if (!mounted || pickedTime == null) return;

              DateTime combined = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              );
              if (combined.isBefore(DateTime.now())) {
                combined = DateTime.now().add(Duration(minutes: 5));
              }
              setStateDialog(() => selectedDeadline = combined);
            }

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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: selectedDeadline == null
                            ? const Text("Brak terminu")
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    MaterialLocalizations.of(
                                      context,
                                    ).formatFullDate(selectedDeadline!),
                                  ),
                                  Text(
                                    MaterialLocalizations.of(
                                      context,
                                    ).formatTimeOfDay(
                                      TimeOfDay.fromDateTime(selectedDeadline!),
                                      alwaysUse24HourFormat: true,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await pickDeadline();
                        },
                        icon: const Icon(Icons.event),
                        label: const Text("Ustaw"),
                      ),
                    ],
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
                    _saveTask(
                      currentTask: currentTask,
                      title: _titleCtrl.text,
                      description: _descCtrl.text,
                      deadLine: selectedDeadline!,
                    );
                  },
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
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
      _sortTasksByDeadline();
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

  void _sortTasksByDeadline() {
    _tasks.sort((a, b) {
      final aDate = DateTime.tryParse(a.deadLine);
      final bDate = DateTime.tryParse(b.deadLine);

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }
}
