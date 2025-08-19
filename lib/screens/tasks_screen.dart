import 'package:flutter/material.dart';
import '../models/task.dart';
import '../db/tasks_db.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final notifications = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  await notifications.initialize(
    const InitializationSettings(android: androidInit),
  );

  // Android 13+
  final android = notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  await android?.requestNotificationsPermission();
}

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

  int _doneCount = 0;
  final Map<int, int> _doneByDay = {};

  @override
  Widget build(BuildContext context) {
    final tasksTodo = _tasks.where((t) => !t.isDone).toList();
    final tasksDone = _tasks.where((t) => t.isDone).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Twoje zadania"), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    "Wykonane zadania: $_doneCount\n"
                    "Najproduktywniejszy dzień: $_productiveDay",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    "Do zrobienia",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: tasksTodo.isEmpty
                      ? const Center(child: Text("Brak zadań do zrobienia"))
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: tasksTodo.length,
                          itemBuilder: (context, i) {
                            final task = tasksTodo[i];
                            final originalIndex = _tasks.indexOf(task);
                            return _buildTaskTile(task, originalIndex);
                          },
                        ),
                ),

                const Divider(height: 1),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    "Zrobione",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: tasksDone.isEmpty
                      ? const Center(child: Text("Brak wykonanych zadań"))
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: tasksDone.length,
                          itemBuilder: (context, i) {
                            final task = tasksDone[i];
                            final originalIndex = _tasks.indexOf(task);
                            return _buildTaskTile(task, originalIndex);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTaskTile(Task task, int i) {
    return Dismissible(
      key: ValueKey(task.id ?? '${task.title}-$i'),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteTaskAfterSwipe(task, i),
      child: CheckboxListTile(
        controlAffinity: ListTileControlAffinity.leading,
        value: task.isDone,
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.green;
          }
          return null;
        }),
        onChanged: (_) async {
          setState(() {
            _tasks[i] = task.copyWith(isDone: !task.isDone);
          });
          _toggleTask(task, i);
          await cancelDeadlineReminder(task.id!);
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
                const Icon(Icons.schedule, size: 14, color: Colors.grey),
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
          icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
          splashRadius: 18,
          tooltip: 'Edytuj',
          onPressed: () => _openEditDialog(task),
        ),
      ),
    );
  }

  Future<void> _deleteTaskAfterSwipe(Task task, int index) async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _tasks.removeAt(index);
    });

    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text('Usunięto zadanie: ${task.title}'),
        action: SnackBarAction(
          label: 'Cofnij',
          onPressed: () {
            setState(() {
              _tasks.insert(index, task);
            });
          },
        ),
        duration: const Duration(seconds: 7),
      ),
    );

    await controller.closed;
    final stillThere = _tasks.any((t) => t.id == task.id);
    if (!stillThere && task.id != null) {
      try {
        await TasksDb.instance.deleteTask(task.id!);
      } catch (e) {
        // revert in case of failure
        setState(() {
          _tasks.insert(index, task);
        });
        messenger.showSnackBar(SnackBar(content: Text('Błąd usuwania: $e')));
      }
    }
    await cancelDeadlineReminder(task.id!);
  }

  Future<void> _insertOrUpdateTask(Task task) async {
    late Task savedTask;

    if (task.id == null) {
      // insert
      final id = await TasksDb.instance.insertTask(task);
      savedTask = task.copyWith(id: id);
      setState(() {
        _tasks.add(task.copyWith(id: id));
      });
      await scheduleDeadlineReminder(
        id: savedTask.id!,
        title: task.title,
        deadline: DateTime.parse(task.deadLine),
      );
    } else {
      // update
      await TasksDb.instance.updateTask(task);
      savedTask = task;
      setState(() {
        final i = _tasks.indexWhere((t) => t.id == task.id);
        if (i != -1) _tasks[i] = task;
      });
      await cancelDeadlineReminder(task.id!);
      await scheduleDeadlineReminder(
        id: savedTask.id!,
        title: task.title,
        deadline: DateTime.parse(task.deadLine),
      );
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

  void _toggleTask(Task task, int index) async {
    setState(() {
      final nowDone = !task.isDone;
      _tasks[index] = task.copyWith(isDone: nowDone);

      if (nowDone) {
        _doneCount++;
        final today = DateTime.now().weekday;
        _doneByDay[today] = (_doneByDay[today] ?? 0) + 1;
      } else {
        _doneCount--;
        final today = DateTime.now().weekday;
        if ((_doneByDay[today] ?? 0) > 0) {
          _doneByDay[today] = _doneByDay[today]! - 1;
        }
      }
    });
  }

  String get _productiveDay {
    if (_doneByDay.isEmpty) return "Brak danych";
    final best = _doneByDay.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return _dayOfTheWeek(best.key);
  }

  String _dayOfTheWeek(int day) {
    switch (day) {
      case DateTime.monday:
        return "Poniedziałek";
      case DateTime.tuesday:
        return "Wtorek";
      case DateTime.wednesday:
        return "Środa";
      case DateTime.thursday:
        return "Czwartek";
      case DateTime.friday:
        return "Piątek";
      case DateTime.saturday:
        return "Sobota";
      case DateTime.sunday:
        return "Niedziela";
      default:
        return "-";
    }
  }

  Future<void> scheduleDeadlineReminder({
    required int id,
    required String title,
    required DateTime deadline,
  }) async {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    if (diff.isNegative) return;

    final reminderTime = now.add(diff * 0.8);

    if (reminderTime.isBefore(now)) return;

    const android = AndroidNotificationDetails(
      'deadlines',
      'Task deadlines',
      channelDescription: 'Przypomnienia o terminach zadań',
      importance: Importance.high,
      priority: Priority.high,
    );

    await notifications.zonedSchedule(
      id,
      'Zbliża się termin zadania: $title',
      'Zostało Ci 20% zaplanowanego czasu',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(android: android),
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  Future<void> cancelDeadlineReminder(int id) async {
    await notifications.cancel(id);
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initNotifications();
    });
  }
}
