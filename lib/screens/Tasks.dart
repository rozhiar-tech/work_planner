import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:work_planner/helpers/Users.dart' as custom_user;

class Tasks extends StatefulWidget {
  const Tasks({super.key});

  @override
  State<Tasks> createState() => _TasksState();
}

class _TasksState extends State<Tasks> {
  String? _userName;
  List<Map<String, dynamic>> _tasks = [];
  String _selectedPriority = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
  }

  Future<void> _fetchCurrentUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        custom_user.User currentUser = custom_user.User.fromFirestore(
            userDoc.data() as Map<String, dynamic>, userDoc.id);
        setState(() {
          _userName = currentUser.name;
        });
        _fetchTasks(currentUser.name);
      }
    }
  }

  Future<void> _fetchTasks(String userName) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('assignee', isEqualTo: userName)
        .get();
    List<Map<String, dynamic>> tasks = snapshot.docs
        .map(
            (doc) => {'id': doc.id, 'data': doc.data() as Map<String, dynamic>})
        .toList();

    // Sort tasks by priority
    tasks.sort((a, b) => _priorityValue(a['data']['priority'])
        .compareTo(_priorityValue(b['data']['priority'])));

    setState(() {
      _tasks = tasks;
    });
  }

  int _priorityValue(String? priority) {
    switch (priority) {
      case 'High':
        return 1;
      case 'Medium':
        return 2;
      case 'Low':
      default:
        return 3;
    }
  }

  Future<void> _completeTask(String taskId) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(taskId)
        .update({'status': 'Completed'});
    _fetchTasks(_userName!); // Refresh the tasks after updating
  }

  Future<void> _openFile(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  List<Map<String, dynamic>> get _filteredTasks {
    List<Map<String, dynamic>> filteredTasks = _tasks;
    if (_selectedPriority != 'All') {
      filteredTasks = filteredTasks
          .where((task) => task['data']['priority'] == _selectedPriority)
          .toList();
    }
    if (_selectedStatus != 'All') {
      filteredTasks = filteredTasks
          .where((task) => task['data']['status'] == _selectedStatus)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) {
        return (task['data']['title'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (task['data']['description'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }
    return filteredTasks;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_userName != null) {
                _fetchTasks(_userName!);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: _selectedPriority,
              icon: const Icon(Icons.filter_list, color: Colors.white),
              dropdownColor: Theme.of(context).primaryColor,
              style: const TextStyle(color: Colors.white),
              underline: Container(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPriority = newValue!;
                });
              },
              items: <String>['All', 'High', 'Medium', 'Low']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: _selectedStatus,
              icon: const Icon(Icons.filter_list, color: Colors.white),
              dropdownColor: Theme.of(context).primaryColor,
              style: const TextStyle(color: Colors.white),
              underline: Container(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedStatus = newValue!;
                });
              },
              items: <String>['All', 'Completed', 'Pending']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search by title or description',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _userName == null
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                    ? const Center(child: Text('No tasks assigned to you'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = _filteredTasks[index]['data'];
                          final taskId = _filteredTasks[index]['id'];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              title: Text(
                                task['title'] ?? 'No title',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.blueGrey[900],
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    task['description'] ?? 'No description',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white54
                                          : Colors.blueGrey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Priority: ${task['priority'] ?? 'No priority'}',
                                    style: TextStyle(
                                      color:
                                          _getPriorityColor(task['priority']),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Deadline: ${task['deadline'] != null ? (task['deadline'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : 'No deadline'}',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white54
                                          : Colors.blueGrey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Status: ${task['status'] ?? 'No status'}',
                                    style: TextStyle(
                                      color: task['status'] == 'Completed'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  if (task['files'] != null)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Files:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        ...task['files']
                                            .map<Widget>((fileUrl) => InkWell(
                                                  onTap: () =>
                                                      _openFile(fileUrl),
                                                  child: Text(
                                                    fileUrl,
                                                    style: const TextStyle(
                                                      color: Colors.blue,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: task['status'] == 'Completed'
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _completeTask(taskId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                      ),
                                      child: const Text('Complete'),
                                    ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
      default:
        return Colors.green;
    }
  }
}
