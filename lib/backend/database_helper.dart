import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._instance();
  static Database? _db;

  DatabaseHelper._instance();

  String studentTable = 'student_table';
  String colId = 'id';
  String colStudentId = 'student_id';
  String colStudentName = 'student_name';
  String colGuardianName = 'guardian_name';
  String colClass = 'class';
  String colImage = 'image';
  String colDefaulter = 'defaulter';
  String colSync = 'sync';

  Future<Database?> get db async {
    if (_db == null) {
      _db = await _initDb();
    }
    return _db;
  }

  Future<Database> _initDb() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = join(dir.path, 'student.db');
    final studentDb = await openDatabase(path, version: 1, onCreate: _createDb);
    return studentDb;
  }

  void _createDb(Database db, int version) async {
    await db.execute(
      'CREATE TABLE $studentTable($colId INTEGER AUTO_INCREMENT, '
      '$colStudentId TEXT PRIMARY KEY, $colStudentName TEXT, $colGuardianName TEXT, '
      '$colClass TEXT, $colImage TEXT, $colDefaulter REAL, $colSync TEXT)',
    );
  }

  Future<int> insertStudent(Map<String, dynamic> student) async {
    Database? db = await this.db;
    final int result = await db!.insert(studentTable, student);
    return result;
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    Database? db = await this.db;
    final List<Map<String, dynamic>> result = await db!.query(studentTable);
    return result;
  }

  Future<Map<String, dynamic>?> getStudentById(String studentId) async {
    Database? db = await this.db;
    List<Map<String, dynamic>> result = await db!.query(
      studentTable,
      where: '$colStudentId = ?',
      whereArgs: [studentId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateStudent(Map<String, dynamic>? student) async {
    Database? db = await this.db;
    final int result = await db!.update(
      studentTable,
      student!,
      where: '$colStudentId = ?',
      whereArgs: [student[colStudentId]],
    );
    return result;
  }
}
