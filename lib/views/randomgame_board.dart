// ignore_for_file: library_private_types_in_public_api, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'dart:math';

class RandomGameBoard extends StatefulWidget {
  final bool isHumanVsHuman;

  const RandomGameBoard({Key? key, required this.isHumanVsHuman})
      : super(key: key);

  @override
  _RandomGameBoardState createState() => _RandomGameBoardState();
}

class _RandomGameBoardState extends State<RandomGameBoard> {
  static const int empty = 0;
  static const int userShip = 1;
  static const int aiShip = 4;
  static const int aiHit = 5;
  static const int aiMiss = 6;
  static const int userBomb = 7;
  static const int userHit = 8;

  // Variables to store the state before resetting the game
  late List<List<int>> prevUserShipMatrix;
  late List<List<int>> prevAiShipMatrix;
  late List<List<int>> prevGameBoardMatrix;
  late List<List<bool>> prevUserBombsPlaced;
  late List<List<bool>> prevAiBombsPlaced;
  late List<int> prevUserShipLocations;
  late List<List<int>> prevAiShipLocations;
  late bool prevIsShipPlacementPhase;
  late bool prevIsUserTurn;
  late bool prevIsUserButtonEnabled;
  late int prevShipsPlacedByUser;
  late int prevShipsPlacedByAI;
  late int prevUserPoints;
  late int prevAiPoints;
  late bool prevIsGameReset;

  List<List<int>> userShipMatrix =
      List.generate(5, (_) => List.filled(5, empty));
  List<List<int>> aiShipMatrix = List.generate(5, (_) => List.filled(5, empty));
  List<List<int>> gameBoardMatrix =
      List.generate(5, (_) => List.filled(5, empty));
  List<List<bool>> userBombsPlaced =
      List.generate(5, (_) => List.filled(5, false));
  List<List<bool>> aiBombsPlaced =
      List.generate(5, (_) => List.filled(5, false));

  List<int> userShipLocations = List.filled(5, -1); // Added this line
  List<List<int>> aiShipLocations = List.generate(5, (_) => List.filled(2, -1));

  bool isShipPlacementPhase = true;
  bool isUserTurn = true;
  bool isUserButtonEnabled = true;
  int shipsPlacedByUser = 0;
  int shipsPlacedByAI = 0;
  int userPoints = 0;
  int aiPoints = 0;
  bool isGameReset = false;

  @override
  Widget build(BuildContext context) {
    Widget _buildTile(int row, int col) {
      IconData? iconData;
      Color tileColor = Colors.white;
      String imagePath = '';

      if (isUserTurn ||
          gameBoardMatrix[row][col] == aiMiss ||
          gameBoardMatrix[row][col] == aiHit) {
        // Show the user's board or AI's misses/hits
        switch (gameBoardMatrix[row][col]) {
          case userShip:
            iconData = null;
            tileColor = Colors.white;
            imagePath = 'assets/imgs/user-ship.png';
            break;
          case aiShip:
            iconData = null;
            tileColor =
                Colors.white; // Change to your preferred color for hidden ships
            break;
          case aiHit:
            iconData = null;
            tileColor = Colors.white;
            imagePath = 'assets/imgs/wreck.png';
            break;
          case aiMiss:
            iconData = Icons.close;
            tileColor = Colors.grey;
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
      } else {
        // Hide AI's ships during the user's turn
        switch (gameBoardMatrix[row][col]) {
          case userShip:
            iconData = null;
            tileColor = Colors.blue;
            imagePath = 'assets/imgs/user-ship.png';
            break;
          case aiShip:
            iconData = null;
            tileColor =
                Colors.white; // Change to your preferred color for hidden ships
            break;
          case aiHit:
            iconData = null;
            tileColor = Colors.red;
            imagePath = 'assets/imgs/wreck.png';
            break;
          case aiMiss:
            iconData = Icons.close;
            tileColor = Colors.grey;
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
      }

      return GestureDetector(
        onTap: () {
          if (isShipPlacementPhase) {
            _placeShip(row, col);
          } else {
            if (isUserTurn && isUserButtonEnabled) {
              _placeBomb(row, col);
            }
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
        title: const Text('Battleship Game'),
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
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (isGameReset) {
                _initializeGame();
              } else {
                _promptResetGame();
              }
            },
            child: const Text(
              'Reset Game',
            ),
          ),
        ],
      ),
    );
  }

  void _submitUserShips() {
    for (int i = 0; i < 5; i++) {
      userShipLocations[i] =
          gameBoardMatrix.indexWhere((row) => row.contains(userShip), i * 5);
    }

    _placeAIShips();
    setState(() {
      isShipPlacementPhase = false;
      isUserButtonEnabled = false;
    });

    _startGame();
  }

  void _endUserTurn() {
    setState(() {
      isUserTurn = false;
      isUserButtonEnabled = false;
      _botPlay();
    });
  }

  void _placeShip(int row, int col) {
    if (gameBoardMatrix[row][col] == userShip) {
      setState(() {
        gameBoardMatrix[row][col] = empty;
        shipsPlacedByUser--;
      });
    } else if (gameBoardMatrix[row][col] == empty && shipsPlacedByUser < 5) {
      setState(() {
        gameBoardMatrix[row][col] = userShip;
        userShipMatrix[row][col] = userShip;
        shipsPlacedByUser++;
      });
    }
  }

  void _placeAIShips() {
    for (int i = 0; i < 5; i++) {
      int randomRow, randomCol;

      do {
        randomRow = Random().nextInt(5);
        randomCol = Random().nextInt(5);
      } while (gameBoardMatrix[randomRow][randomCol] != empty);

      aiShipLocations[i] = [randomRow, randomCol];
      aiShipMatrix[randomRow][randomCol] = aiShip;
      gameBoardMatrix[randomRow][randomCol] = aiShip;
      shipsPlacedByAI++;
    }
  }

  void _handleTurn() {
    // Check if the game is already over
    if (_isGameOver()) {
      return;
    }

    // Close any remaining Snackbars
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    if (isUserTurn) {
      _showSnackbar("User's Turn!");
      setState(() {
        isUserButtonEnabled = true;
      });
    } else {
      _botPlay();
    }
  }

  bool _isGameOver() {
    return userPoints == 5 ||
        aiPoints == 5 ||
        shipsPlacedByUser == 0 ||
        shipsPlacedByAI == 0 ||
        isGameReset;
  }

  void _placeBomb(int row, int col) {
    setState(() {
      if (gameBoardMatrix[row][col] == aiShip) {
        userPoints++;
        _showSnackbar("User hit an AI ship! User points: $userPoints");
        gameBoardMatrix[row][col] = aiHit; // Mark the hit on the board
      } else if (gameBoardMatrix[row][col] == empty) {
        gameBoardMatrix[row][col] = userBomb; // Mark the miss on the board
      } else {
        // Bomb already placed on this tile or user hit their own ship, show warning
        _showSnackbar("Warning: Same spot hit again!");
        return;
      }

      _checkGameOver();
      _endUserTurn();

      // Add a delay before resetting the tile to give a visual cue for miss
      Future.delayed(const Duration(milliseconds: 500), () {
        if (gameBoardMatrix[row][col] == userBomb) {
          setState(() {
            gameBoardMatrix[row][col] = empty; // Reset the tile to normal state
          });
        }
      });
    });
  }

  void _botPlay() {
    int randomRow, randomCol;

    do {
      randomRow = Random().nextInt(5);
      randomCol = Random().nextInt(5);
    } while (gameBoardMatrix[randomRow][randomCol] == aiMiss ||
        gameBoardMatrix[randomRow][randomCol] == aiHit ||
        gameBoardMatrix[randomRow][randomCol] == userBomb ||
        aiShipMatrix[randomRow][randomCol] == aiShip ||
        aiBombsPlaced[randomRow][randomCol]);

    // Mark the tile as attacked by the AI
    aiBombsPlaced[randomRow][randomCol] = true;

    // Check if the tile contains the user's ship
    bool isHit = gameBoardMatrix[randomRow][randomCol] == userShip;

    // Update the game board with hit or miss
    gameBoardMatrix[randomRow][randomCol] = isHit ? userHit : aiMiss;

    if (isHit) {
      aiPoints++;
    }

    isUserTurn = true;
    isUserButtonEnabled = true;
    _checkGameOver();

    // Add a delay before resetting the tile to give a visual cue for miss
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        // Reset the tile to normal state only if it's a miss
        if (!isHit && gameBoardMatrix[randomRow][randomCol] == aiMiss) {
          gameBoardMatrix[randomRow][randomCol] = empty;
        }
      });
    });
  }

  void _checkGameOver() {
    bool isGameOver = false;

    if (userPoints == 5) {
      _showSnackbar("Congratulations! You sank all the enemy ships!");
      isGameOver = true;
    } else if (aiPoints == 5) {
      _showSnackbar("Game Over! Enemy sank all your ships!");
      isGameOver = true;
    } else if (shipsPlacedByUser == 0 || shipsPlacedByAI == 0) {
      // Check if either the user or AI has no ships left
      isGameOver = true;

      if (shipsPlacedByUser == 0) {
        _showSnackbar("Game Over! All your ships are sunk. Enemy wins!");
      } else if (shipsPlacedByAI == 0) {
        _showSnackbar("Congratulations! You've sunk all enemy ships. You win!");
      }
    }

    if (isGameOver) {
      _promptResetGame();
    } else {
      _handleTurn();
    }
  }

  void _resetGame() {
    // Store the current state before resetting
    prevUserShipMatrix = List.from(userShipMatrix);
    prevAiShipMatrix = List.from(aiShipMatrix);
    prevGameBoardMatrix = List.from(gameBoardMatrix);
    prevUserBombsPlaced = List.from(userBombsPlaced);
    prevAiBombsPlaced = List.from(aiBombsPlaced);
    prevUserShipLocations = List.from(userShipLocations);
    prevAiShipLocations = List.from(aiShipLocations);
    prevIsShipPlacementPhase = isShipPlacementPhase;
    prevIsUserTurn = isUserTurn;
    prevIsUserButtonEnabled = isUserButtonEnabled;
    prevShipsPlacedByUser = shipsPlacedByUser;
    prevShipsPlacedByAI = shipsPlacedByAI;
    prevUserPoints = userPoints;
    prevAiPoints = aiPoints;
    prevIsGameReset = isGameReset;

    // Reset the game state
    setState(() {
      // Clear the game board
      gameBoardMatrix = List.generate(5, (_) => List.filled(5, empty));

      // Clear ship locations and other game state variables
      userShipMatrix = List.generate(5, (_) => List.filled(5, empty));
      aiShipMatrix = List.generate(5, (_) => List.filled(5, empty));
      userBombsPlaced = List.generate(5, (_) => List.filled(5, false));
      aiBombsPlaced = List.generate(5, (_) => List.filled(5, false));
      shipsPlacedByUser = 0;
      shipsPlacedByAI = 0;
      isShipPlacementPhase = true;
      isUserTurn = true; // Set it to user's turn
      isUserButtonEnabled = true;
      userPoints = 0;
      aiPoints = 0;
      isGameReset = false;
    });

    // Close any remaining Snackbars
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    // Determine the winner message
    String winnerMessage;
    if (userPoints == 5) {
      winnerMessage = "Congratulations! You won!";
    } else if (aiPoints == 5) {
      winnerMessage = "Game Over! AI won!";
    } else {
      winnerMessage = "Game Reset!";
    }

    _showSnackbar(winnerMessage);

    // Start a new game
    _initializeGame();
  }

  void _promptResetGame() {
    if (!isGameReset) {
      setState(() {
        isGameReset = true;
      });

      // Determine the winner message for the dialog
      String winnerMessage;
      if (userPoints == 5) {
        winnerMessage = "Congratulations! You won!";
      } else if (aiPoints == 5) {
        winnerMessage = "Game Over! AI won!";
      } else {
        winnerMessage = "Do you want to reset the game?";
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Game Over"),
            content: Text(winnerMessage),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _resetGame(); // Reset the game
                },
                child: const Text("Yes"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  // Restore the previous state without triggering a rebuild
                  userShipMatrix = List.from(prevUserShipMatrix);
                  aiShipMatrix = List.from(prevAiShipMatrix);
                  gameBoardMatrix = List.from(prevGameBoardMatrix);
                  userBombsPlaced = List.from(prevUserBombsPlaced);
                  aiBombsPlaced = List.from(prevAiBombsPlaced);
                  userShipLocations = List.from(prevUserShipLocations);
                  aiShipLocations = List.from(prevAiShipLocations);
                  isShipPlacementPhase = prevIsShipPlacementPhase;
                  isUserTurn = prevIsUserTurn;
                  isUserButtonEnabled = prevIsUserButtonEnabled;
                  shipsPlacedByUser = prevShipsPlacedByUser;
                  shipsPlacedByAI = prevShipsPlacedByAI;
                  userPoints = prevUserPoints;
                  aiPoints = prevAiPoints;
                  isGameReset = prevIsGameReset;
                },
                child: const Text("No"),
              ),
            ],
          );
        },
      );
    }
  }

  void _startGame() {
    _showSnackbar("Game Started!");

    // Start a new game
    _initializeGame();
  }

  void _initializeGame() {
    // Check if it's the ship placement phase
    if (isShipPlacementPhase) {
      _handleTurn();
    } else {
      // If it's not the ship placement phase, determine the player's turn
      if (isUserTurn) {
        setState(() {
          isUserButtonEnabled = true;
        });
      } else if (!widget.isHumanVsHuman) {
        // If it's not Human vs Human, it's the AI's turn
        _botPlay();
      }
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
