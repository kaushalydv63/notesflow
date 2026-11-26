import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:notesflow/models/note_model.dart';

class NoteService {
  NoteService._();
  static final NoteService instance = NoteService._();

  static Database? _db;
  static bool _ffiReady = false;
  final Uuid _uuid = const Uuid();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      if (!_ffiReady) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _ffiReady = true;
      }
    }

    final baseDir = await getDatabasesPath();
    final dbPath = p.join(baseDir, 'notesflow.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<NoteModel>> getNotes() async {
    final db = await database;
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map((row) => NoteModel.fromMap(row)).toList();
  }

  Future<void> addNote(String title, String content) async {
    final db = await database;
    final note = NoteModel(
      id: _uuid.v4(),
      title: title.trim().isEmpty ? 'Untitled' : title.trim(),
      content: content.trim(),
      updatedAt: DateTime.now(),
    );
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(NoteModel note) async {
    final db = await database;
    final updated = NoteModel(
      id: note.id,
      title: note.title.trim().isEmpty ? 'Untitled' : note.title.trim(),
      content: note.content.trim(),
      updatedAt: DateTime.now(),
    );
    await db.update(
      'notes',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}