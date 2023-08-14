import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:multiplayer_tictactoe/screens/connection_screen/connection_screen.dart';

class SuccessScreen extends StatefulWidget {
  final Socket socket;

  const SuccessScreen({
    super.key,
    required this.socket,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  Socket? client;
  String anotherUserMessage = "";

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() async {
    client?.listen((event) {
      anotherUserMessage = utf8.decode(event); //or String.fromCharCodes
      setState(() {});
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Communicate"),
        ),
        body: Column(
          children: [
            if (anotherUserMessage.isNotEmpty) ...[
              Text("Others Message: $anotherUserMessage"),
              const SizedBox(
                height: 20,
              ),
            ],
            TextField(
              onSubmitted: (value) {
                if (value.isEmpty) return;
                client?.add(utf8.encode(value));
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    client?.close();
    super.dispose();
  }
}
