import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:work_planner/screens/CreateTask.dart';
import 'package:work_planner/screens/Dashboard.dart';
import 'package:work_planner/screens/Tasks.dart';
import 'package:work_planner/screens/Team.dart';
import 'package:work_planner/screens/TimeSheets.dart';
import 'package:work_planner/screens/login.dart';
import 'package:work_planner/helpers/Users.dart'; // Import the custom user class

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final User user; // Using the custom User class

  const HomePage({
    required this.toggleTheme,
    required this.isDarkMode,
    required this.user,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  int _selectedIndex = 0;

  Future<void> _logout() async {
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  Future<void> _confirmLogout() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to logout?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.of(context).pop(); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: widget.isDarkMode
              ? Colors.blueGrey[900]
              : Colors.blueGrey[100], // Sidebar background color
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: Text(
                  widget.user.name,
                  style: const TextStyle(
                    color: Colors.white, // Text color
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(widget.user.email),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Image.network(
                      widget.user.image, // Replace with your profile image path
                      fit: BoxFit.cover,
                      width: 90,
                      height: 90,
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? Colors.blueGrey[700]
                      : Colors.blueGrey[300], // Header background color
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.white),
                title: const Text(
                  'Dashboard',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => _onItemTapped(0),
              ),
              ListTile(
                leading: const Icon(Icons.task, color: Colors.white),
                title: const Text(
                  'Tasks',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => _onItemTapped(1),
              ),
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.white),
                title: const Text(
                  'Timesheets',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => _onItemTapped(2),
              ),
              ListTile(
                leading: const Icon(Icons.group, color: Colors.white),
                title: const Text(
                  'Team',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => _onItemTapped(3),
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.create, color: Colors.white),
                title: const Text(
                  'Create Task',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => _onItemTapped(4),
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: _confirmLogout,
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const <Widget>[
          Dashboard(),
          Tasks(),
          Timesheets(),
          Team(),
          Createtask(),
        ],
      ),
    );
  }
}
