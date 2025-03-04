import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db.dart';
Future<void> _insertInitialUsers() async {
  final db = await DatabaseHelper.instance.database;

  // Insert 5 users again (even if the database exists)
  for (int i = 1; i <= 5; i++) {
    await db.insert('users', {
      'name': 'User $i',
      'age': 20 + i,
    });
  }
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database; // Ensures database is initialized
  await _insertInitialUsers(); // Insert 5 users at app launch
  // Ensure FFI is initialized before database access
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Desktop CRUD Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: UserListPage(),
    );
  }
}

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late Future<List<User>> users;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      users = DatabaseHelper.instance.getAllUsers();
    });
  }

  void _addUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add User'),
        content: AddUserForm(onSubmit: (name, age) async {
          final user = User(name: name, age: age);
          await DatabaseHelper.instance.addUser(user);
          _refreshUsers();
          Navigator.pop(context);
        }),
      ),
    );
  }

  void _deleteUser(int id) async {
    await DatabaseHelper.instance.deleteUser(id);
    _refreshUsers();
  }

  void _updateUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update User'),
        content: AddUserForm(
          initialName: user.name,
          initialAge: user.age,
          onSubmit: (name, age) async {
            final updatedUser = User(id: user.id, name: name, age: age);
            await DatabaseHelper.instance.updateUser(updatedUser);
            _refreshUsers();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Users CRUD"),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _addUser,
          ),
        ],
      ),
      body: FutureBuilder<List<User>>(
        future: users,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final userList = snapshot.data ?? [];
          return ListView.builder(
            itemCount: userList.length,
            itemBuilder: (context, index) {
              final user = userList[index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text('Age: ${user.age}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _updateUser(user),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteUser(user.id!),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddUserForm extends StatefulWidget {
  final String? initialName;
  final int? initialAge;
  final Function(String, int) onSubmit;

  AddUserForm({this.initialName, this.initialAge, required this.onSubmit});

  @override
  _AddUserFormState createState() => _AddUserFormState();
}

class _AddUserFormState extends State<AddUserForm> {
  late TextEditingController nameController;
  late TextEditingController ageController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName ?? '');
    ageController = TextEditingController(text: widget.initialAge?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: "Name"),
        ),
        TextField(
          controller: ageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "Age"),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text;
            final age = int.tryParse(ageController.text) ?? 0;
            if (name.isNotEmpty && age > 0) {
              widget.onSubmit(name, age);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid input')));
            }
          },
          child: Text('Submit'),
        ),
      ],
    );
  }
}
