import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

//Its technical name might not be Handshake.
///It ensure that whether the another device have also received the request.
enum Handshake {
  ///Send the request to other and wait them to send back handshakeSuccess.
  ///The player who performs the action.
  sendToOther,

  ///Player receives the request performed by some another user.
  ///It performs the action on its own, then sends the another user success
  otherPersonReceived,

  ///After a user performs an action, it send another user request to perform the same action
  ///once the another user perform that action it sends back confirmation of handshakeSuccess.
  ///If the user don't get handshakeSuccess after long wait it send to the another user request again.
  ///The receiving user must make sure that same request could be send twice due to request lost on handshakeSuccess validation
  ///because the sender don't know whether request is lost before otherPersonReceived, or after otherPersonReceived but before handshakeSuccess received
  handshakeSuccess,
}

enum OtherUserAction {
  ///Game is finished, restart the game on both user's side
  restartRequest,

  restartConfirm,
}
// The current logic worked in this application but,
// in another WebSocket practice application change the architecture,
// Client sends request to server to perform a move,
// all the logic are only is the server,
// so server perform the move and inform the child with proper handshaking
// right now both client and server are performing the same move.
//Also in another project research pre build package for handshaking.

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
    startNewGame(fromInit: true, fromAnotherUser: false);
  }

  @override
  void dispose() {
    widget.socket.destroy();
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
        if (otherUserAction == OtherUserAction.restartRequest.index) {
          startNewGame(fromInit: false, fromAnotherUser: true);
        } else {
          //Todo: Restart 2 way communication
          log("Restart 2 way communication");
        }
      }
    }).onDone(() {
      if(!context.mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Another Player gave up")));
      Navigator.pop(context);
    });
  }

  void startNewGame(
      {required bool fromInit, required bool fromAnotherUser}) async {
    setState(() {
      board = List<List<String>>.generate(3, (_) => List<String>.filled(3, ''));
      if (fromInit) {
        whoAmI = widget.isServer ? 'X' : '0';
      } else {
        whoAmI = switchZeroCross(whoAmI ?? 'X');
      }
      if (!fromAnotherUser && !fromInit) {
        widget.socket.add([OtherUserAction.restartRequest.index]);
      }
      currentPlayer = 'X';
      gameOver = false;
    });
  }

  void makeMove(int row, int col, Handshake handshake) {
    if ((board[row][col] != '' || gameOver)) {
      _cancelTimer();
      return;
    }
    log("Make Move. Row: $row Column:$col $handshake");
    if (handshake == Handshake.sendToOther) {
      canUnlock = () => board[row][col].isNotEmpty;
      handshakeLock = Timer(const Duration(milliseconds: 250), () {
        if (canUnlock()) {
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
        board[row][col] = currentPlayer;
        checkWinner(row, col);
        currentPlayer = switchZeroCross(currentPlayer);
        _cancelTimer();
      });
    }
  }

  void _cancelTimer() {
    handshakeLock?.cancel();
    handshakeLock = null;
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
                          if (currentPlayer != whoAmI ||
                              handshakeLock != null ||
                              gameOver) return;
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
                    startNewGame(fromInit: false, fromAnotherUser: false);
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
