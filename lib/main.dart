// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:battleships/views/login_screen.dart'; // Import your login screen
import 'package:battleships/views/game_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battleships Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/home', // Set initial route
      routes: {
        '/home': (context) => const MyHomePage(),
        '/login': (context) => const LoginScreen(),
        '/game': (context) => const GameList(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    // Check if the access token exists in shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    if (accessToken != null && accessToken.isNotEmpty) {
      // If token exists, navigate to the game list screen
      Navigator.pushReplacementNamed(context, '/game');
    } else {
      // If token doesn't exist, navigate to the login screen
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child:
            CircularProgressIndicator(), // You can customize this loading indicator
      ),
    );
  }
}
