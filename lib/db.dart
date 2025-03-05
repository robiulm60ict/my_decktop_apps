// import 'package:flutter/material.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:path/path.dart';
// import 'dart:io';
//
// class User {
//   int? id;
//   String name;
//   int age;
//
//   User({this.id, required this.name, required this.age});
//
//   Map<String, dynamic> toMap() {
//     return {'id': id, 'name': name, 'age': age};
//   }
//
//   static User fromMap(Map<String, dynamic> map) {
//     return User(id: map['id'], name: map['name'], age: map['age']);
//   }
// }
//
// class DatabaseHelper {
//   static final DatabaseHelper instance = DatabaseHelper._init();
//   static Database? _database;
//
//   DatabaseHelper._init();
//
//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     sqfliteFfiInit(); // Initialize for desktop
//     databaseFactory = databaseFactoryFfi;
//     _database = await _initDB();
//     return _database!;
//   }
//   Future<Database> _initDB() async {
//     try {
//       final dbPath = await getDatabasesPath(); // This gives a path to a writable directory.
//       final path = join(dbPath, 'users.db');
//
//       return await databaseFactory.openDatabase(path,
//           options: OpenDatabaseOptions(
//             version: 1,
//             onCreate: (db, version) async {
//               await db.execute('''
//             CREATE TABLE users (
//               id INTEGER PRIMARY KEY AUTOINCREMENT,
//               name TEXT NOT NULL,
//               age INTEGER NOT NULL
//             )
//             ''');
//
//               // Insert 5 initial users
//               for (int i = 1; i <= 5; i++) {
//                 await db.insert('users', {
//                   'name': 'User $i',
//                   'age': 20 + i,
//                 });
//               }
//
//             },
//           ));
//     } catch (e) {
//
//       print("Database error: $e");
//       rethrow;
//     }
//   }
//
//
//
//   Future<int> addUser(User user) async {
//     final db = await database;
//     return await db.insert('users', user.toMap());
//   }
//
//   Future<List<User>> getAllUsers() async {
//     final db = await database;
//     final result = await db.query('users');
//     return result.map((json) => User.fromMap(json)).toList();
//   }
//
//   Future<int> updateUser(User user) async {
//     final db = await database;
//     return await db.update('users', user.toMap(),
//         where: 'id = ?', whereArgs: [user.id]);
//   }
//
//   Future<int> deleteUser(int id) async {
//     final db = await database;
//     return await db.delete('users', where: 'id = ?', whereArgs: [id]);
//   }
// }
