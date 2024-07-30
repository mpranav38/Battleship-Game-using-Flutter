// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, avoid_print

import 'package:battleships/views/continuationgame_board.dart';
import 'package:battleships/views/usergame_board.dart';
import 'package:battleships/views/randomgame_board.dart';
import 'package:battleships/views/perfectgame_board.dart';
import 'package:battleships/views/oneshipgame_board.dart';
import 'package:flutter/material.dart';
import 'package:battleships/model/game_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GameList extends StatefulWidget {
  const GameList({Key? key}) : super(key: key);

  @override
  _GameListState createState() => _GameListState();
}

class _GameListState extends State<GameList> {
  List<Game> activeGames = [];
  List<Game> completedGames = [];
  bool showCompletedGames = false;
  late String accessToken;

  @override
  void initState() {
    super.initState();
    _getGames();
  }

  Future<void> _getGames() async {
    const String baseUrl = 'http://165.227.117.48';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('access_token') ?? '';

    if (accessToken.isEmpty) {
      print('Access token is empty. Handle this case.');
      // Handle the case where the access token is empty
      return;
    }

    try {
      final Uri uri = Uri.parse('$baseUrl/games');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        dynamic jsonResponse = json.decode(response.body);

        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('games')) {
          var gamesList = jsonResponse['games'];
          if (gamesList != null && gamesList is List) {
            setState(() {
              activeGames = gamesList
                  .where((gameJson) => gameJson['status'] == 3)
                  .map((gameJson) => Game.fromJson(gameJson))
                  .toList();

              completedGames = gamesList
                  .where((gameJson) =>
                      gameJson['status'] == 1 || gameJson['status'] == 2)
                  .map((gameJson) => Game.fromJson(gameJson))
                  .toList();
            });
          } else {
            print('Invalid response format: "games" key is not a List');
          }
        } else {
          print('Invalid response format: Missing "games" key');
        }
      } else if (response.statusCode == 401) {
        print('Unauthorized request. Redirect to login.');
        // Handle unauthorized request, for example, redirect to login
        // You may want to implement a method like _handleUnauthorized();
        _handleUnauthorized();
      } else {
        print("Failed to retrieve games: ${response.statusCode}");
        // Handle other error cases...
      }
    } catch (e, stackTrace) {
      print("Error decoding JSON: $e");
      print("StackTrace: $stackTrace");
      // Handle other error cases...
    }
  }

  void _handleUnauthorized() {
    // Handle the unauthorized request, for example, redirect to login screen
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('username');
      prefs.remove('access_token');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    });
  }

  Future<Game> _getGameDetails(int gameId) async {
    try {
      const String baseUrl = 'http://165.227.117.48';

      final Uri uri = Uri.parse('$baseUrl/games/$gameId');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        dynamic jsonResponse = json.decode(response.body);

        if (jsonResponse is Map<String, dynamic>) {
          // Handle the detailed game information here
          print('Detailed Game Info: $jsonResponse');
          return Game.fromJson(jsonResponse); // Return the Game object
        } else {
          print('Invalid response format for game details');
        }
      } else {
        print("Failed to retrieve game details: ${response.statusCode}");
      }

      // Return a default or empty Game object if there's an error
      return Game(
        id: 0,
        player1: '',
        player2: '',
        status: '',
        hasStarted: false,
        position: 0,
        turn: 0,
        board: [],
        ships: [],
        wrecks: [],
      );
    } catch (e, stackTrace) {
      print("Error getting game details: $e");
      print("StackTrace: $stackTrace");
      // Return a default or empty Game object if there's an error
      return Game(
        id: 0,
        player1: '',
        player2: '',
        status: '',
        hasStarted: false,
        position: 0,
        turn: 0,
        board: [],
        ships: [],
        wrecks: [],
      );
    }
  }

  Future<void> _toggleShowCompletedGames() async {
    setState(() {
      showCompletedGames = !showCompletedGames;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Game> displayedGames =
        showCompletedGames ? completedGames : activeGames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battleships'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getGames,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('New Game'),
              onTap: () async {
                // Retrieve the detailed game information
                Game gameDetails = await _getGameDetails(0);

                // Navigate to the UserGameBoard screen and pass the game details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return UserGameBoard(
                        isHumanVsHuman: true,
                        accessToken: accessToken,
                        game: gameDetails, // Pass the entire Game object
                      );
                    },
                  ),
                );
              },
            ),
            ExpansionTile(
              title: const Text('New Game (AI)'),
              children: [
                ListTile(
                  title: const Text('Random AI'),
                  onTap: () async => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const RandomGameBoard(
                            isHumanVsHuman: false,
                          );
                        },
                      ),
                    )
                  },
                ),
                ListTile(
                  title: const Text('Perfect AI'),
                  onTap: () async => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const PerfectGameBoard(
                            isHumanVsHuman: false,
                          );
                        },
                      ),
                    )
                  },
                ),
                ListTile(
                  title: const Text('One-Ship AI'),
                  onTap: () async => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const OneShipGameBoard(
                            isHumanVsHuman: false,
                          );
                        },
                      ),
                    )
                  },
                ),
              ],
            ),
            SwitchListTile(
              title: Text(showCompletedGames
                  ? 'Show Active Games'
                  : 'Show Completed Games'),
              onChanged: (value) {
                _toggleShowCompletedGames();
              },
              value: showCompletedGames,
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: displayedGames.length,
        itemBuilder: (context, index) {
          Game game = displayedGames[index];
          return Dismissible(
            key: Key(game.id.toString()),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _deleteGame(game.id),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              onTap: () async {
                // Retrieve the detailed game information
                Game gameDetails = await _getGameDetails(game.id);

                // Navigate to the UserGameBoard screen and pass the game details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ContinuationGameBoard(
                        isHumanVsHuman: true,
                        accessToken: accessToken,
                        game: gameDetails, // Pass the entire Game object
                      );
                    },
                  ),
                );
              },
              title: Text('Game ID: ${game.id}'),
              subtitle: Text(_getGameSubtitle(game)),
            ),
          );
        },
      ),
    );
  }

  String _getGameSubtitle(Game game) {
    return 'Players: ${game.player1} vs ${game.player2}\n';
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('username');
    prefs.remove('access_token');
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _deleteGame(int gameId) async {
    try {
      const String baseUrl = 'http://165.227.117.48';

      final Uri uri = Uri.parse('$baseUrl/games/$gameId');
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        // Handle successful deletion
        _showSnackbar('Game canceled or forfeited successfully.');
        // Refresh the game list
        _getGames();
      } else if (response.statusCode == 401) {
        print('Unauthorized request. Redirect to login.');
        _handleUnauthorized();
      } else {
        print("Failed to delete game: ${response.statusCode}");
        // Handle other error cases...
        _showSnackbar('Failed to cancel or forfeit the game.');
      }
    } catch (e, stackTrace) {
      print("Error deleting game: $e");
      print("StackTrace: $stackTrace");
      // Handle other error cases...
      _showSnackbar('Error occurred while canceling or forfeiting the game.');
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
}
