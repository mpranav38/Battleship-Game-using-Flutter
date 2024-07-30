class Game {
  final int id;
  final String player1;
  final String player2;
  final String status;
  final bool hasStarted;
  final int position;
  final int turn;
  final List<List<String>> board;
  List<List<String>> ships;
  List<String> wrecks;

  Game({
    required this.id,
    required this.player1,
    required this.player2,
    required this.status,
    required this.hasStarted,
    required this.position,
    required this.turn,
    required this.board,
    required this.ships,
    required this.wrecks,
  });

  factory Game.newGameWithHuman({
    required String currentPlayer,
    required String opponent,
  }) {
    return Game(
      id: DateTime.now().millisecondsSinceEpoch,
      player1: currentPlayer,
      player2: opponent,
      status: 'Pending',
      hasStarted: false,
      board: List.generate(10, (_) => List.filled(10, '')),
      ships: List.generate(5, (_) => List.filled(5, '')),
      wrecks: [],
      position: 0,
      turn: 0,
    );
  }

  factory Game.newGameWithAI({required String currentPlayer}) {
    return Game(
      id: DateTime.now().millisecondsSinceEpoch,
      player1: currentPlayer,
      player2: 'Computer',
      status: 'Pending',
      hasStarted: false,
      board: List.generate(10, (_) => List.filled(10, '')),
      ships: [],
      wrecks: [],
      position: 0,
      turn: 0,
    );
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    var shipsJson = json['ships'];
    List<List<String>> ships;

    if (shipsJson is List) {
      ships = List<List<String>>.from(shipsJson.map(
        (ship) {
          if (ship is List) {
            // ship is already a list of coordinates
            return List<String>.from(ship.map((coord) => coord.toString()));
          } else if (ship is String) {
            // handle the case where ship is a single coordinate represented as a String
            return [ship.toString()];
          } else {
            // handle other cases or set a default value
            return [];
          }
        },
      ));
    } else {
      // handle other cases or set a default value
      ships = [];
    }

    return Game(
      id: json['id'] ?? 0,
      player1: json['player1'] ?? '',
      player2: json['player2'] ?? '',
      position: json['position'] ?? 0,
      status: json['status'].toString(),
      hasStarted: json['hasStarted'] ?? false,
      turn: json['turn'] ?? 0,
      board: List<List<String>>.from(
        json['board']?.map(
              (row) => List<String>.from(row.map((cell) => cell.toString())),
            ) ??
            [],
      ),
      ships: ships,
      wrecks: List<String>.from(
          json['wrecks']?.map((wreck) => wreck.toString()) ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player1': player1,
      'player2': player2,
      'status': status,
      'hasStarted': hasStarted,
      'position': position,
      'turn': turn,
      'board': List<dynamic>.from(
        board.map((row) => List<dynamic>.from(row)),
      ),
      'ships': List<dynamic>.from(
        ships.map((ship) => List<dynamic>.from(ship)),
      ),
      'wrecks': List<dynamic>.from(wrecks),
    };
  }
}
