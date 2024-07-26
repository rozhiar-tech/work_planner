import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:work_planner/screens/home.dart';
import 'package:work_planner/screens/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:work_planner/helpers/Users.dart' as custom_user;

class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const SplashScreen(
      {required this.toggleTheme, required this.isDarkMode, super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplashScreen();
  }

  Future<void> _startSplashScreen() async {
    await Future.delayed(const Duration(seconds: 3)); // Wait for 3 seconds

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId != null) {
      // Fetch user information from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        custom_user.User user = custom_user.User.fromFirestore(
            userDoc.data() as Map<String, dynamic>, userDoc.id);

        if (mounted) {
          // Navigate to home page with user information
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                toggleTheme: widget.toggleTheme,
                isDarkMode: widget.isDarkMode,
                user: user,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          // Navigate to login page if no valid user found
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPage(),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        // Navigate to login page if no valid user found
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Lottie.asset('assets/logo.json',
                width: 200, height: 200, repeat: true),
            const SizedBox(height: 20),
            const Text(
              'Work Planner',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
