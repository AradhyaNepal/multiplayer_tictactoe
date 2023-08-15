import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:multiplayer_tictactoe/screens/connection_screen/tic_tac_toe.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  String? urlToConnect;
  ServerSocket? socket;
  final portController = TextEditingController();
  bool validPort = true;
  bool _startingServer = true;

  @override
  void initState() {
    super.initState();
    portController.text = "3000";
    // Dart server
    getUrl().then((value) async {
      await _startSocket();
    });
  }

  bool _checkIsValid(String value) {
    if (value.isEmpty) {
      return false;
    }

    int? port = int.tryParse(value);
    if (port == null || port < 1 || port > 65535) {
      return false;
    } else {
      return true;
    }
  }

  Future<void> _startSocket() async {
    if (!validPort) {
      log("Invalid Port to start the socket");
      return;
    }
    await Future.delayed(Duration.zero, () {
      _startingServer = true;
      setState(() {});
    });
    await socket?.close();
    log("Starting Socket");
    socket = await ServerSocket.bind(
        InternetAddress("0.0.0.0", type: InternetAddressType.IPv4),
        int.parse(portController.text));
    log("Socket Started");

    setState(() {
      _startingServer = false;
    });
    socket?.listen((newClient) async {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicTacToeScreen(
            socket: newClient,
            isServer: true,
          ),
        ),
      );
    }).onDone(() {
      log("Previous Socket Closed");
    });
  }

  Future<void> getUrl() async {
    try {
      NetworkInfo().getWifiIP().then((value) {
        urlToConnect = value;
        setState(() {});
      });
    } catch (e) {
      await Future.delayed(Duration.zero);
      if (!mounted) return;
      final value = await showModalBottomSheet(
          context: context,
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 50,
              ),
              child: TextField(
                decoration:
                    const InputDecoration(hintText: "Enter Your device Ip"),
                onSubmitted: (value) {
                  if (value.isEmpty) return;
                  Navigator.pop(context, value);
                },
              ),
            );
          });
      if (value is String) {
        urlToConnect = value;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.shortestSide < 600
        ? MediaQuery.of(context).size.width * 0.75
        : 500.0;
    return Center(
      child: urlToConnect == null || _startingServer
          ? const CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Spacer(
                      flex: 2,
                    ),
                    Expanded(
                      child: TextField(
                        controller: portController,
                        onChanged: (value) {
                          validPort = _checkIsValid(value);
                          _startSocket();
                          setState(() {});
                        },
                        decoration:
                            const InputDecoration(labelText: "Port Number"),
                      ),
                    ),
                    const Spacer(
                      flex: 2,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                if (validPort)
                  QrImageView(
                    data: "$urlToConnect--${portController.text}",
                    size: size,
                  )
                else
                  const Center(
                    child: Text("Invalid Port"),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    socket?.close();
    portController.dispose();
    super.dispose();
  }
}
