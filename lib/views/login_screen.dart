// ignore_for_file: avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'game_list.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _handleLogin(context);
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // Navigate to the registration screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistrationScreen(),
                  ),
                );
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    // Username and password empty check
    if (username.isEmpty || password.isEmpty) {
      _showSnackbar(
          context, 'Username and password cannot be empty.', Colors.red);
      return;
    }

    try {
      // Fetch the access token
      String? accessToken = await getAccessToken(username, password);

      // Null check for access token
      if (accessToken != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('username', username);
        prefs.setString('access_token', accessToken);

        // Navigate to the GameList page after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GameList()),
        );

        // Show success snackbar
        _showSnackbar(context, 'Login Successful!', Colors.green);
      } else {
        // Show error snackbar
        _showSnackbar(context, 'Invalid username or password.', Colors.red);
      }
    } catch (e) {
      // Show error snackbar
      _showSnackbar(context, 'An unexpected error occurred.', Colors.red);
    }
  }

  Future<String?> getAccessToken(String username, String password) async {
    final Uri uri = Uri.parse('http://165.227.117.48/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['access_token'];
    } else if (response.statusCode == 401) {
      // Login failed due to invalid credentials
      return null;
    } else {
      // Handle other login errors
      print('Login failed. ${response.statusCode}: ${response.body}');
      return null;
    }
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
