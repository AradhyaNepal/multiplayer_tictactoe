import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:multiplayer_tictactoe/enums.dart';

import 'custom_dialog.dart';

// The current logic worked in this application but,
// in another WebSocket practice application change the architecture,
// Client sends request to server to perform a move,
// all the logic are only is the server,
// so server perform the move and inform the child with proper handshaking
// right now both client and server are performing the same move.
// Also in another project research pre build package for handshaking.
class TicTacToeScreen extends StatefulWidget {
  final Socket socket;
  final bool isServer;

  const TicTacToeScreen({
    super.key,
    required this.socket,
    required this.isServer,
  });

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

typedef CanUnlock = bool Function();

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  bool _waitingForAnotherUser = false;
  String? _whoAmI;
  late List<List<String>> _board;
  String _currentPlayer = "X";
  bool _gameOver = false;
  Timer? _handshakeLock;
  CanUnlock _canUnlock = () => false;

  @override
  void initState() {
    super.initState();
    _multiplayerSetup();
    startNewGame(restartGame: null);
  }

  @override
  void dispose() {
    widget.socket.destroy();
    _handshakeLock?.cancel();
    super.dispose();
  }

  void _multiplayerSetup() async {
    widget.socket.listen((event) {
      log("Event $event");
      if (event case [var row, var col, var handshake]) {
        if (handshake == Handshake.sendToOther.index) {
          makeMove(row, col, Handshake.otherPersonReceived);
        } else if (handshake == Handshake.handshakeSuccess.index) {
          makeMove(row, col, Handshake.handshakeSuccess);
        }
      } else if (event case [var restartGame]) {
        startNewGame(restartGame: restartGame);
      }
    }).onDone(() {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Another Player gave up")));
      Navigator.pop(context);
    });
  }

  ///Restart game null means its called from init
  void startNewGame({required int? restartGame}) async {
    _clearBoard();
    if (restartGame == null) {
      _whoAmI = widget.isServer ? 'X' : '0';
    } else if (restartGame == RestartGameRequest.send.index) {
      log("Sending another player request to start the game");
      _waitingForAnotherUser = true;
      widget.socket.add([RestartGameRequest.received.index]);
      setState(() {});
    } else if (restartGame == RestartGameRequest.received.index) {
      _performRestartReceivedAction();
    } else if (restartGame == RestartGameRequest.bothConfirmed.index) {
      _waitingForAnotherUser = false;
      log("Another player accepted your request, you can now start playing");
      _startingTheGame();
    } else if (restartGame == RestartGameRequest.rejected.index) {
      _waitingForAnotherUser = false;
      log("Another player rejected you");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Another player rejected you",
          ),
        ),
      );
      setState(() {});
    }
  }

  void _performRestartReceivedAction() async {
    log("Restart game request received");
    if (!_gameOver) {
      _gameStartConfirmation();
      return;
    }
    final value = await showDialog(
      context: context,
      builder: (context) {
        return const CustomDialog(
          title: "Play Again",
          content: "Do you want to play again!",
          no: "I need rest.",
        );
      },
    );
    if (value == true) {
      _gameStartConfirmation();
    } else {
      widget.socket.add([RestartGameRequest.rejected.index]);
    }
  }

  void _gameStartConfirmation() {
    widget.socket.add([RestartGameRequest.bothConfirmed.index]);
    _startingTheGame();
  }

  void _startingTheGame() {
    if (_gameOver) {
      _whoAmI = switchZeroCross(_whoAmI ?? 'X');
    }
    _currentPlayer = 'X';
    _clearBoard();
    _gameOver = false;
    setState(() {});
  }

  void _clearBoard() {
    _board = List<List<String>>.generate(3, (_) => List<String>.filled(3, ''));
  }

  void makeMove(int row, int col, Handshake handshake) {
    if ((_board[row][col] != '' || _gameOver)) {
      _cancelTimer();
      return;
    }
    log("Make Move. Row: $row Column:$col $handshake");
    if (handshake == Handshake.sendToOther) {
      _canUnlock = () => _board[row][col].isNotEmpty;
      _handshakeLock = Timer(const Duration(milliseconds: 250), () {
        if (_canUnlock()) {
          _cancelTimer();
        } else {
          log("Packet get lost, resending");
          makeMove(row, col, Handshake.sendToOther);
        }
      });
      widget.socket.add([row, col, handshake.index]);
    } else {
      if (handshake == Handshake.otherPersonReceived) {
        widget.socket.add([row, col, Handshake.handshakeSuccess.index]);
      }
      setState(() {
        _board[row][col] = _currentPlayer;
        checkWinner(row, col);
        _currentPlayer = switchZeroCross(_currentPlayer);
        _cancelTimer();
      });
    }
  }

  void _cancelTimer() {
    _handshakeLock?.cancel();
    _handshakeLock = null;
  }

  String switchZeroCross(String value) {
    return value == 'X' ? '0' : 'X';
  }

  void checkWinner(int row, int col) {
    // Check row
    if (_board[row][0] == _board[row][1] &&
        _board[row][1] == _board[row][2] &&
        _board[row][0] != '') {
      setState(() {
        _gameOver = true;
      });
    }

    // Check column
    if (_board[0][col] == _board[1][col] &&
        _board[1][col] == _board[2][col] &&
        _board[0][col] != '') {
      setState(() {
        _gameOver = true;
      });
    }

    // Check diagonal
    if (_board[0][0] == _board[1][1] &&
        _board[1][1] == _board[2][2] &&
        _board[0][0] != '') {
      setState(() {
        _gameOver = true;
      });
    }
    if (_board[0][2] == _board[1][1] &&
        _board[1][1] == _board[2][0] &&
        _board[0][2] != '') {
      setState(() {
        _gameOver = true;
      });
    }

    bool isTie = false;
    // Check for a tie
    if (!_board.any((row) => row.any((cell) => cell == '')) && !_gameOver) {
      setState(() {
        _gameOver = true;
        isTie = true;
      });
    }

    if (_gameOver && !isTie) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "${_currentPlayer == _whoAmI ? "You" : "Opponent"} won the game!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final value = await showDialog(
            context: context,
            builder: (context) {
              return const CustomDialog(
                title: "Give Up!",
                content:
                    "Are you okay if your friends mock you for a guy who easily give up?",
              );
            });
        if (value == true) {
          if (!mounted) return Future.value(false);
          Navigator.pop(context);
        }
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tic Tac Toe'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_gameOver) ...[
                Text(
                  'You are $_whoAmI \n(${_whoAmI == _currentPlayer ? "Your" : "Opponent"}\'s Turn)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 400, maxWidth: 400),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, index) {
                        final row = index ~/ 3;
                        final col = index % 3;
                        return GestureDetector(
                          onTap: () {
                            if (_currentPlayer != _whoAmI ||
                                _handshakeLock != null ||
                                _gameOver) return;
                            makeMove(row, col, Handshake.sendToOther);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 183, 233, 185),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Container(
                              color: _board[row][col] == 'X'
                                  ? Colors.amberAccent
                                  : (_board[row][col] == "O")
                                      ? Colors.redAccent
                                      : const Color.fromARGB(
                                          255, 183, 233, 185),
                              child: Center(
                                child: Text(
                                  _board[row][col],
                                  style: const TextStyle(fontSize: 40),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  "Game Over!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _waitingForAnotherUser
                      ? null
                      : () {
                          startNewGame(
                              restartGame: RestartGameRequest.send.index);
                        },
                  child: Text(_waitingForAnotherUser
                      ? "Waiting For Another Player"
                      : 'Start New Game'),
                ),
                const SizedBox(
                  height: 20,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
