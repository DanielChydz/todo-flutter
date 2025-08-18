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
          $colIsDone BIT NOT NULL);
          """);
      },
    );
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
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
}
