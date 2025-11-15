import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/category.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        completed INTEGER NOT NULL,
        priority TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        dueDate TEXT,
        categoryId TEXT,
        reminderDateTime TEXT,
        photoPath TEXT,
        completedAt TEXT,
        completedBy TEXT,
        latitude REAL,
        longitude REAL,
        locationName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        icon INTEGER NOT NULL
      )
    ''');

    // Inserir categorias padrão
    await _insertDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN dueDate TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE tasks ADD COLUMN categoryId TEXT');
      await db.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color INTEGER NOT NULL,
          icon INTEGER NOT NULL
        )
      ''');
      await _insertDefaultCategories(db);
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE tasks ADD COLUMN reminderDateTime TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE tasks ADD COLUMN photoPath TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN completedAt TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN completedBy TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE tasks ADD COLUMN longitude REAL');
      await db.execute('ALTER TABLE tasks ADD COLUMN locationName TEXT');
    }
  }

  Future<void> _insertDefaultCategories(DatabaseExecutor db) async {
    final defaultCategories = [
      Category(
        id: 'work',
        name: 'Trabalho',
        color: Colors.blue,
        icon: Icons.business_center,
      ),
      Category(
        id: 'personal',
        name: 'Pessoal',
        color: Colors.green,
        icon: Icons.person,
      ),
      Category(
        id: 'shopping',
        name: 'Compras',
        color: Colors.orange,
        icon: Icons.shopping_cart,
      ),
      Category(
        id: 'health',
        name: 'Saúde',
        color: Colors.red,
        icon: Icons.health_and_safety,
      ),
      Category(
        id: 'education',
        name: 'Educação',
        color: Colors.purple,
        icon: Icons.school,
      ),
    ];

    for (final category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  Future<Task> create(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    return task;
  }

  Future<Task?> read(String id) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Task>> readAll() async {
    final db = await database;
    const orderBy = 'createdAt DESC';
    final result = await db.query('tasks', orderBy: orderBy);
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> update(Task task) async {
    final db = await database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> replaceAllTasks(List<Task> tasks) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tasks');
      for (final task in tasks) {
        await txn.insert(
          'tasks',
          task.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Categories CRUD
  Future<Category> createCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
    return category;
  }

  Future<Category?> readCategory(String id) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Category>> readAllCategories() async {
    final db = await database;
    const orderBy = 'name ASC';
    final result = await db.query('categories', orderBy: orderBy);
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> replaceAllCategories(List<Category> categories) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('categories');
      if (categories.isEmpty) {
        await _insertDefaultCategories(txn);
        return;
      }
      for (final category in categories) {
        await txn.insert(
          'categories',
          category.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
