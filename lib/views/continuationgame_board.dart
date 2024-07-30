// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, no_leading_underscores_for_local_identifiers, avoid_print

import 'dart:convert';

import 'package:battleships/model/game_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ContinuationGameBoard extends StatefulWidget {
  final bool isHumanVsHuman;
  final String accessToken;
  final Game game;

  const ContinuationGameBoard({
    Key? key,
    required this.isHumanVsHuman,
    required this.accessToken,
    required this.game, // Accept the entire Game object
  }) : super(key: key);

  @override
  _ContinuationGameBoardState createState() => _ContinuationGameBoardState();
}

class _ContinuationGameBoardState extends State<ContinuationGameBoard> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const int empty = 0;
  static const int userShip = 1;
  static const int userBomb = 7;
  static const int userHit = 8;
  static const int userMiss = 9;

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
  bool isBombPlaced = false;
  String bombLocations = '';

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
          iconData = Icons.check; // Display userHit icon for hits
          tileColor = const Color.fromARGB(255, 244, 225, 54);
          imagePath = 'assets/imgs/wreck.png';
          break;
        case userMiss: // Display userMiss icon for misses
          iconData = Icons.clear;
          tileColor = Colors.blue; // Customize color as needed
          break;
        default:
          iconData = null;
          tileColor = Colors.white;
      }

      return GestureDetector(
        onTap: () {
          if (!isShipPlacementPhase || (isUserTurn && isUserButtonEnabled)) {
            _placeBomb(row, col);
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
                        width: 40,
                        height: 40,
                      )
                    : const Text('')),
          ),
        ),
      );
    }

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Play Game - ${widget.game.id}'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _getGameStatusText(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                      onPressed: isUserTurn && isUserButtonEnabled
                          ? () => _submitBombPlacement()
                          : null,
                      child: const Text('Submit Bomb Placement'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _placeBomb(int row, int col) {
    if (!isUserTurn || !isUserButtonEnabled) {
      _showSnackbar("It's not your turn. Please wait for your opponent.");
      return;
    }

    setState(() {
      if (!isBombPlaced) {
        userBombsPlaced[row][col] = true;
        gameBoardMatrix[row][col] = userBomb;
        isBombPlaced = true;

        // Update bombLocations as a comma-separated string
        bombLocations +=
            ',${String.fromCharCode('A'.codeUnitAt(0) + row)}${col + 1}';
      } else if (userBombsPlaced[row][col]) {
        userBombsPlaced[row][col] = false;
        gameBoardMatrix[row][col] = empty;
        isBombPlaced = false;

        // Update bombLocations by removing the bomb location
        bombLocations = bombLocations
            .replaceAll(
              String.fromCharCode('A'.codeUnitAt(0) + row) +
                  (col + 1).toString(),
              '',
            )
            .replaceAll(',,', ',')
            .trim();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  void _submitBombPlacement() {
    if (isBombPlaced) {
      // Remove leading comma, if any
      bombLocations = bombLocations.startsWith(',')
          ? bombLocations.substring(1)
          : bombLocations;

      // Directly pass bombLocations string to the server
      _sendBombPlacementToServer(
          widget.accessToken, widget.game.id, bombLocations);

      // Disable the user's button until it's their turn again
      setState(() {
        isUserButtonEnabled = false;
      });
    } else {
      _showSnackbar("Please place a bomb before submitting.");
    }
  }

  String _getGameStatusText() {
    String player1Name = widget.game.player1;
    String player2Name = widget.game.player2;

    String currentPlayerName = isUserTurn ? player1Name : player2Name;
    String opponentPlayerName = isUserTurn ? player2Name : player1Name;

    String turnText = isUserTurn ? "Your Turn" : "$opponentPlayerName's Turn";
    String pointsText = "Points: $userPoints";

    return "$currentPlayerName is playing against $opponentPlayerName Turn: $turnText Your Points: $pointsText ";
  }

  void _sendBombPlacementToServer(
      String accessToken, int gameId, String bombLocation) async {
    final Uri uri = Uri.parse('http://165.227.117.48/games/$gameId');
    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'shot': bombLocation}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        bool sunkShip = responseData['sunk_ship'];
        print(sunkShip);
        bool won = responseData['won'];

        if (sunkShip) {
          _showSnackbar("User hit and sunk an Opponent's ship!");
          _handleUserHit(responseData); // Handle the hit scenario
          userPoints++; // Increase userPoints when a ship is sunk
        } else {
          _showSnackbar("User missed!");
          _handleUserMiss(responseData); // Handle the miss scenario
        }

        if (won) {
          _showSnackbar("Congratulations! You won the game!");
        } else {
          _endUserTurn();
        }
      } else if (response.statusCode == 401) {
        _handleTokenExpired();
      } else {
        print(
            'Failed to submit bomb placement. ${response.statusCode}: ${response.body}');
        throw Exception('Failed to submit bomb placement');
      }
    } catch (e, stackTrace) {
      print('Error submitting bomb placement: $e');
      print('Stack trace: $stackTrace');
      _showSnackbar('Failed to submit bomb placement. $e');
    }
  }

  void _handleUserMiss(Map<String, dynamic>? responseData) {
    if (responseData != null) {
      int? row = responseData['row'] as int?;
      int? col = responseData['col'] as int?;

      if (row != null && col != null) {
        setState(() {
          gameBoardMatrix[row][col] = userMiss;
        });
      }
    }
  }

  void _handleUserHit(Map<String, dynamic> responseData) {
    int? row = responseData['row'] as int?;
    int? col = responseData['col'] as int?;

    if (row != null && col != null) {
      setState(() {
        gameBoardMatrix[row][col] = userHit;
      });
    }
  }

  void _endUserTurn() {
    setState(() {
      isUserTurn = false;
      isUserButtonEnabled = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  void _initializeGame() async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    if (isShipPlacementPhase) {
      List<List<String>> serverShips = widget.game.ships;
      _placeUserShipsFromServer(serverShips);
      _handleTurn();
    } else {
      // Check if the token is expired before proceeding
      if (await _isTokenExpired()) {
        _handleTokenExpired();
        return;
      }

      if (widget.game.turn == 1) {
        _showSnackbar("Player 1's Turn!");
        setState(() {
          isUserButtonEnabled = true;
        });
      } else {
        _showSnackbar("Player 2's Turn!");
        // Handle AI or other logic for player 2's turn
      }
    }
  }

  Future<bool> _isTokenExpired() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    // Check if the access token is null or expired
    return accessToken == null || _isExpired(accessToken);
  }

  bool _isExpired(String accessToken) {
    return _getExpiration(accessToken) < DateTime.now().millisecondsSinceEpoch;
  }

  int _getExpiration(String accessToken) {
    // Dummy function to extract expiration time from a JWT token
    // You should replace this with your own logic or use a library
    // that can parse JWT tokens
    Map<String, dynamic> decodedToken = json.decode(
      ascii.decode(base64.decode(base64.normalize(accessToken.split('.')[1]))),
    );

    return (decodedToken['exp'] ?? 0) * 1000;
  }

  void _handleTokenExpired() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('username');
      prefs.remove('access_token');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    });
  }

  void _placeUserShipsFromServer(List<List<String>> serverShips) {
    setState(() {
      gameBoardMatrix = List.generate(5, (_) => List.filled(5, empty));
      List<String> flattenedShips = serverShips.expand((list) => list).toList();

      for (String shipCoordinate in flattenedShips) {
        int row = shipCoordinate.codeUnitAt(0) - 'A'.codeUnitAt(0);
        int col = int.parse(shipCoordinate.substring(1)) - 1;
        gameBoardMatrix[row][col] = userShip;
      }
    });
  }

  void _handleTurn() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    if (isUserTurn) {
      _showSnackbar("User's Turn!");
      setState(() {
        isUserButtonEnabled = true;
      });
    }
  }

  void _showSnackbar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
