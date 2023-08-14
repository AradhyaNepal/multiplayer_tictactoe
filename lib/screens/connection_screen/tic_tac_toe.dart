import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

enum Handshake {
  sendToOther,
  otherPersonReceived,
  handshakeSuccess,
}

enum OtherUserAction {
  restart,
  giveUp,
}

class TicTacToeScreen extends StatefulWidget {
  final Socket socket;
  final bool isServer;

  const TicTacToeScreen({
    super.key,
    required this.socket,
    required this.isServer,
  });

  @override
  _TicTacToeScreenState createState() => _TicTacToeScreenState();
}

typedef CanUnlock = bool Function();

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  String? whoAmI;
  late List<List<String>> board;
  late String currentPlayer;
  late bool gameOver;
  Timer? handshakeLock;
  CanUnlock canUnlock = () => false;

  @override
  void initState() {
    super.initState();
    _multiplayerSetup();
    startNewGame(fromInit: true,fromAnotherUser: false);
  }

  @override
  void dispose() {
    widget.socket.close();
    handshakeLock?.cancel();
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
      } else if (event case [var otherUserAction]) {
        if (otherUserAction == OtherUserAction.restart.index) {
          startNewGame(fromInit: false,fromAnotherUser: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Another Player gave up")));
          Navigator.pop(context);
        }
      }
    });
  }

  void startNewGame({required bool fromInit,required bool fromAnotherUser}) async{

    setState(() {
      board = List<List<String>>.generate(3, (_) => List<String>.filled(3, ''));
      if (fromInit) {
        whoAmI = widget.isServer ? 'X' : '0';
      } else {
        whoAmI = switchZeroCross(whoAmI ?? 'X');
      }
      if(!fromAnotherUser && !fromInit){
        widget.socket.add([OtherUserAction.restart.index]);
      }
      currentPlayer = 'X';
      gameOver = false;

    });
  }

  void makeMove(int row, int col, Handshake handshake) {
    log("Make Move. Row: $row Column:$col Handshake:$handshake");
    if (handshake == Handshake.sendToOther) {
      canUnlock = () => board[row][col].isNotEmpty;
      handshakeLock = Timer(const Duration(milliseconds: 250), () {
        if (canUnlock()) {
          handshakeLock?.cancel();
          handshakeLock = null;
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
      if (board[row][col] == '' && !gameOver) {
        setState(() {
          board[row][col] = currentPlayer;
          checkWinner(row, col);
          currentPlayer = switchZeroCross(currentPlayer);
          handshakeLock?.cancel();
          handshakeLock = null;
        });
      }
    }
  }

  String switchZeroCross(String value) {
    return value == 'X' ? '0' : 'X';
  }

  void checkWinner(int row, int col) {
    // Check row
    if (board[row][0] == board[row][1] &&
        board[row][1] == board[row][2] &&
        board[row][0] != '') {
      setState(() {
        gameOver = true;
      });
    }

    // Check column
    if (board[0][col] == board[1][col] &&
        board[1][col] == board[2][col] &&
        board[0][col] != '') {
      setState(() {
        gameOver = true;
      });
    }

    // Check diagonal
    if (board[0][0] == board[1][1] &&
        board[1][1] == board[2][2] &&
        board[0][0] != '') {
      setState(() {
        gameOver = true;
      });
    }
    if (board[0][2] == board[1][1] &&
        board[1][1] == board[2][0] &&
        board[0][2] != '') {
      setState(() {
        gameOver = true;
      });
    }

    bool isTie = false;
    // Check for a tie
    if (!board.any((row) => row.any((cell) => cell == '')) && !gameOver) {
      setState(() {
        gameOver = true;
        isTie = true;
      });
    }

    if (gameOver && !isTie) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$currentPlayer Won the game!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final value = await showDialog(
            context: context,
            builder: (context) {
              return const GiveUpDialog();
            });
        if(value==true){
          widget.socket.add([OtherUserAction.giveUp.index]);
          if(!mounted)return Future.value(false);
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
              Text(
                'You are $whoAmI \n(${whoAmI == currentPlayer ? "Your" : "Opponent"}\'s Turn)',
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
                          if (currentPlayer != whoAmI || handshakeLock != null || gameOver) return;
                          makeMove(row, col, Handshake.sendToOther);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 183, 233, 185),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Container(
                            color: board[row][col] == 'X'
                                ? Colors.amberAccent
                                : (board[row][col] == "O")
                                    ? Colors.redAccent
                                    : const Color.fromARGB(255, 183, 233, 185),
                            child: Center(
                              child: Text(
                                board[row][col],
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
              const SizedBox(height: 20),
              if (gameOver) const Text("Start a new game!!"),
              if (gameOver)
                ElevatedButton(
                  onPressed: () {
                    startNewGame(fromInit: false,fromAnotherUser: false);
                  },
                  child: const Text('New Game'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class GiveUpDialog extends StatelessWidget {
  const GiveUpDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Give Up!"),
      content: const Text(
          "Are you okay if your friends mock you for a guy who easily give up?"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text("Yes"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text("No"),
        ),
      ],
    );
  }
}
