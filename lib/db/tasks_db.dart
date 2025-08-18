import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/task.dart';

class TasksDb {
  TasksDb._();
  static final TasksDb instance = TasksDb._();

  static const _dbName = "tasks.db";
  static const _dbVersion = 1;

  static const tableName = "tasks";
  static const colId = "id";
  static const colTitle = "title";
  static const colDeadLine = "deadline";
  static const colDescription = "description";
  static const colIsDone = "is_done";

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute("""
          CREATE TABLE $tableName (
          $colId INTEGER PRIMARY KEY AUTOINCREMENT,
          $colTitle TEXT NOT NULL,
          $colDescription TEXT,
          $colDeadLine TEXT NOT NULL,
          $colIsDone BIT NOT NULL DEFAULT 0);
          """);
      },
    );
  }

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert(
      tableName,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tableName,
      orderBy: "$colIsDone ASC, $colTitle COLLATE NOCASE ASC",
    );
    return rows.map((m) => Task.fromMap(m)).toList();
  }

  Future<int> updateTask(Task task) async {
    if (task.id == null) {
      throw ArgumentError("updateTask: task.id == null");
    }
    final db = await database;

    final data = Map<String, Object?>.from(task.toMap());
    data.remove("id");

    return await db.update(
      "tasks",
      data,
      where: "id = ?",
      whereArgs: [task.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;

    return await db.delete("tasks", where: "id = ?", whereArgs: [id]);
  }
}
