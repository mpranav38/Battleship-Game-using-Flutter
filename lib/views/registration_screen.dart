// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print, unused_local_variable

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Create an Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _handleRegistration(context);
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegistration(BuildContext context) async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    // Username and password empty check
    if (username.isEmpty || password.isEmpty) {
      _showSnackbar(
          context, 'Username and password cannot be empty.', Colors.red);
      return;
    }

    try {
      // Attempt to register the user
      bool success = await registerUser(username, password);

      if (success) {
        // Registration successful, navigate to login screen
        Navigator.pop(context); // Go back to the login screen
        _showSnackbar(context, 'Registration successful! You can now log in.',
            Colors.green);
      } else {
        // Show a generic error message for registration failure
        _showSnackbar(context,
            'Registration failed. An unexpected error occurred.', Colors.red);
      }
    } catch (e) {
      // Show a generic error message for other registration failures
      _showSnackbar(context,
          'Registration failed. An unexpected error occurred.', Colors.red);
    }
  }

  Future<bool> registerUser(String username, String password) async {
    final Uri uri = Uri.parse('http://165.227.117.48/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Perform any other necessary actions after successful registration
      return true;
    } else if (response.statusCode == 400) {
      // Registration failed due to validation error
      return false;
    } else {
      // Handle other registration errors
      print('Registration failed. ${response.statusCode}: ${response.body}');
      return false;
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
