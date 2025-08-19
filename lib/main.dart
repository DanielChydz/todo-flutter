import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:todo_flutter/screens/tasks_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart' as ftz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // linux test setup
  if (!kIsWeb && Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  tz.initializeTimeZones();
  final String deviceTz = await ftz.FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(deviceTz));

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: "Todo app", home: TasksScreen());
  }
}
