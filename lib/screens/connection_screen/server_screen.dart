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

  @override
  void initState() {
    super.initState();
    // Dart server
    getUrl().then((value) async {
      socket = await ServerSocket.bind("0.0.0.0", 3000);
      socket?.listen((newClient) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicTacToeScreen(
              socket: newClient,
              isServer: true,
            ),
          ),
        );
      });
    });
  }

  Future<void> getUrl() async {
    try {
      NetworkInfo().getWifiIP().then((value) {
        urlToConnect =value;
        setState(() {});
      });
    } catch (e) {
      await Future.delayed(Duration.zero);
      if(!mounted)return;
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
                  if(value.isEmpty)return;
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
      child: urlToConnect == null
          ? const CircularProgressIndicator()
          : QrImageView(
              data: urlToConnect ?? "",
              size: size,
            ),
    );
  }

  @override
  void dispose() {
    socket?.close();
    super.dispose();
  }
}
