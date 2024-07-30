// ignore_for_file: library_private_types_in_public_api, no_leading_underscores_for_local_identifiers, avoid_print, use_build_context_synchronously

import 'package:battleships/model/game_model.dart';
import 'package:battleships/views/game_list.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserGameBoard extends StatefulWidget {
  final bool isHumanVsHuman;
  final String accessToken;
  final Game game; // Accept the entire Game object

  const UserGameBoard({
    Key? key,
    required this.isHumanVsHuman,
    required this.accessToken,
    required this.game, // Accept the entire Game object
  }) : super(key: key);

  @override
  _UserGameBoardState createState() => _UserGameBoardState();
}

class _UserGameBoardState extends State<UserGameBoard> {
  static const int empty = 0;
  static const int userShip = 1;
  static const int userBomb = 7;
  static const int userHit = 8;

  List<List<int>> userShipMatrix =
      List.generate(5, (_) => List.filled(5, empty));
  List<List<int>> gameBoardMatrix =
      List.generate(5, (_) => List.filled(5, empty));
  List<List<bool>> userBombsPlaced =
      List.generate(5, (_) => List.filled(5, false));

  List<int> userShipLocations = List.filled(5, -1);

  bool isShipPlacementPhase = true;
  bool isUserTurn = true;
  bool isUserButtonEnabled = true;
  int shipsPlacedByUser = 0;
  int userPoints = 0;
  bool isGameReset = false;

  @override
  Widget build(BuildContext context) {
    Widget _buildTile(int row, int col) {
      IconData? iconData;
      Color tileColor = Colors.white;
      String imagePath = '';

      switch (gameBoardMatrix[row][col]) {
        case userShip:
          iconData = null;
          tileColor = Colors.white;
          imagePath = 'assets/imgs/user-ship.png';
          break;
        case userBomb:
          iconData = null;
          tileColor = Colors.yellow;
          imagePath = 'assets/imgs/bomb.png';
          break;
        case userHit:
          iconData = null;
          tileColor = const Color.fromARGB(255, 244, 225, 54);
          imagePath = 'assets/imgs/wreck.png';
          break;
        default:
          iconData = null;
          tileColor = Colors.white;
      }

      return GestureDetector(
        onTap: () {
          if (isShipPlacementPhase) {
            _placeShip(row, col);
          }
        },
        child: Container(
          color: tileColor,
          child: Center(
            child: iconData != null
                ? Icon(iconData, color: Colors.black)
                : (imagePath.isNotEmpty
                    ? Image.asset(
                        imagePath,
                        width: 40, // Adjust the width as needed
                        height: 40, // Adjust the height as needed
                      )
                    : const Text('')),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Ships'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: 25,
            itemBuilder: (context, index) {
              int row = index ~/ 5;
              int col = index % 5;
              return _buildTile(row, col);
            },
          ),
          ElevatedButton(
            onPressed: () {
              if (isShipPlacementPhase) {
                if (shipsPlacedByUser == 5) {
                  _submitUserShips();
                } else {
                  _showSnackbar("Please place the remaining ships.");
                }
              }
            },
            child: const Text(
              'Submit Ships',
            ),
          ),
        ],
      ),
    );
  }

  void _placeShip(int row, int col) {
    if (gameBoardMatrix[row][col] == userShip) {
      setState(() {
        gameBoardMatrix[row][col] = empty;
        shipsPlacedByUser--;
        userShipLocations.remove(row * 5 + col); // Remove the ship location
      });
    } else if (gameBoardMatrix[row][col] == empty && shipsPlacedByUser < 5) {
      setState(() {
        gameBoardMatrix[row][col] = userShip;
        userShipMatrix[row][col] = userShip;
        shipsPlacedByUser++;
        userShipLocations[shipsPlacedByUser - 1] =
            row * 5 + col; // Update ship location
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitUserShips() async {
    // Convert the list of integers to the required format
    List<String> ships = userShipLocations.map((location) {
      int row = location ~/ 5 + 'A'.codeUnitAt(0);
      int col = location % 5 + 1;
      return String.fromCharCode(row) + col.toString();
    }).toList();

    try {
      await _startNewGame(widget.accessToken, ships);
    } catch (e) {
      print('Error submitting ships: $e');
      _showSnackbar("Error submitting ships. Please try again.");
      return;
    }

    setState(() {
      isShipPlacementPhase = false;
      isUserButtonEnabled = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const GameList()),
    );
  }

  Future<void> _startNewGame(String accessToken, List<String> ships) async {
    final Uri uri = Uri.parse('http://165.227.117.48/games');
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'ships': ships}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        int gameId = responseData['id'];
        int playerPosition = responseData['player'];
        bool matched = responseData['matched'];

        print(
            'Game ID: $gameId, Player Position: $playerPosition, Matched: $matched');
      } else if (response.statusCode == 401) {
        _handleTokenExpired();
      } else {
        print(
            'Failed to start a new game. ${response.statusCode}: ${response.body}');
        throw Exception('Failed to start a new game');
      }
    } catch (e) {
      print('Error submitting ships: $e');
      throw Exception('Failed to start a new game');
    }
  }

  Future<void> _handleTokenExpired() async {
    // Clear the saved access token
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('username');
    prefs.remove('access_token');

    // Navigate back to the login screen
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
