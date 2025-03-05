import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart' as material;
// import 'package:sqlite3/sqlite3.dart' as sqlite3;


void main() {
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SQLite CRUD Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UserListScreen(),
    );
  }
}


// ----------------------
// User Model
// ----------------------
class User {
  final int? id;
  final String name;
  final int age;


  User({this.id, required this.name, required this.age});


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }


  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      name: map['name'] as String,
      age: map['age'] as int,
    );
  }
}


// ----------------------
// Database Helper Class
// ----------------------
class DatabaseHelper {
  late final Database db;


  // Initialize the database using a file-based DB.
  Future<void> initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'my_database.db');
    print("Database Path: $path");  // Print to debug

    db = sqlite3.open(path);


    // Create the users table if it doesn't exist
    db.execute('''
     CREATE TABLE IF NOT EXISTS users (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       name TEXT,
       age INTEGER
     );
   ''');
  }


  Future<void> insertUser(User user) async {
    db.execute(
      'INSERT INTO users (name, age) VALUES (?, ?)',
      [user.name, user.age],
    );
  }


  Future<List<User>> getUsers() async {
    final ResultSet resultSet = db.select('SELECT * FROM users');
    return resultSet.map((row) => User.fromMap(row)).toList();
  }


  Future<void> updateUser(User user) async {
    db.execute(
      'UPDATE users SET name = ?, age = ? WHERE id = ?',
      [user.name, user.age, user.id],
    );
  }


  Future<void> deleteUser(int id) async {
    db.execute('DELETE FROM users WHERE id = ?', [id]);
  }


  Future<void> close() async {
    db.dispose();
  }
}


// ----------------------
// User List Screen
// ----------------------
class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}


class _UserListScreenState extends State<UserListScreen> {
  late DatabaseHelper dbHelper;
  List<User>? users;


  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    dbHelper.initDatabase().then((_) {
      _refreshUsers();
    });
  }


  Future<void> _refreshUsers() async {
    final fetchedUsers = await dbHelper.getUsers();
    setState(() {
      users = fetchedUsers;
    });
  }


  @override
  void dispose() {
    dbHelper.close();
    super.dispose();
  }
  void _addUser(BuildContext context) async {
    final nameController = TextEditingController();
    final ageController = TextEditingController();


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add User'),
          content: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(hintText: 'Enter name')),
              TextField(controller: ageController, decoration: InputDecoration(hintText: 'Enter age'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Add'),
              onPressed: () {
                final newUser = User(name: nameController.text, age: int.parse(ageController.text.toString()??"0"));
                dbHelper.insertUser(newUser);
                _refreshUsers();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  // Add a new user (for demo, a new user with current timestamp in the name)
  // void _addUser() async {
  //   final newUser =
  //   User(name: 'User ${DateTime.now().millisecondsSinceEpoch}', age: 20);
  //   await dbHelper.insertUser(newUser);
  //   _refreshUsers();
  // }


  // Update an existing user (for demo, update name and increase age by 1)
  // void _updateUser(User user) async {
  //   final updatedUser =
  //   User(id: user.id, name: 'Updated ${user.name}', age: user.age + 1);
  //   await dbHelper.updateUser(updatedUser);
  //   _refreshUsers();
  // }
  void _updateUser(User user,BuildContext context) async {
    final nameController = TextEditingController(text: user.name);
    final ageController = TextEditingController(text: user.age.toString());


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update User'),
          content: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(hintText: 'Enter name')),
              TextField(controller: ageController, decoration: InputDecoration(hintText: 'Enter age'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Update'),
              onPressed: () {
                final updatedUser = User(id: user.id, name: nameController.text, age: int.parse(ageController.text));
                dbHelper.updateUser(updatedUser);
                _refreshUsers();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void _deleteUser(int id,BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                dbHelper.deleteUser(id);
                _refreshUsers();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  // // Delete a user by id
  // void _deleteUser(int id) async {
  //   await dbHelper.deleteUser(id);
  //   _refreshUsers();
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter SQLite CRUD Demo'),
      ),
      body: users == null
          ? Center(child: CircularProgressIndicator())
          : users!.isEmpty
          ? Center(child: Text('No users found.'))
          : ListView.builder(
        itemCount: users!.length,
        itemBuilder: (context, index) {
          final user = users![index];
          return ListTile(
            title: Text('Name: ${user.name}'),
            subtitle: Text('Age: ${user.age}'),
            trailing: material.Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _updateUser(user,context),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    if (user.id != null) {
                      _deleteUser(user.id!,context);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed:(){
          _addUser(context);
        },
      ),
    );
  }
}
