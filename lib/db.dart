import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'main.dart';

class DatabaseHelper {
  late final Database db;

  Future<void> initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'my_database.db');
    print("Database Path: $dbPath");

    // Open the database file
    db = sqlite3.open(dbPath);

    // Create the 'users' table
    db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        age INTEGER
      );
    ''');

    // Create the 'orders' table with a price column and order_date column
    db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        order_details TEXT,
        price REAL,
        order_date TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      );
    ''');
  }

  // Method to insert a new user
  Future<void> insertUser(User user) async {
    db.execute(
      'INSERT INTO users (name, age) VALUES (?, ?)',
      [user.name, user.age],
    );
  }

  // Define insertOrder to add an order for a user with a price
  Future<void> insertOrder(int userId, String orderDetails, double price) async {
    db.execute(
      'INSERT INTO orders (user_id, order_details, price, order_date) VALUES (?, ?, ?, ?)',
      [userId, orderDetails, price, DateTime.now().toIso8601String()],
    );
  }

  // Define getUsersWithOrders to retrieve users with their orders using a JOIN query
  Future<List<Map<String, dynamic>>> getUsersWithOrders() async {
    final ResultSet resultSet = db.select('''
      SELECT 
        users.id AS user_id, 
        users.name, 
        users.age, 
        orders.id AS order_id, 
        orders.order_details, 
        orders.price, 
        orders.order_date
      FROM users
      LEFT JOIN orders ON users.id = orders.user_id
    ''');

    return resultSet.map((row) => row).toList();
  }

  Future<void> close() async {
    db.dispose();
  }
}
