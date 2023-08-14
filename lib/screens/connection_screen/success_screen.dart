import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

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
  String anotherUserMessage = "";

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() async {
    widget.socket.listen((event) {
      log("Was here");
      anotherUserMessage = utf8.decode(event); //or String.fromCharCodes
      setState(() {});
    });
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
                log("Tries to add");
               widget.socket.add(utf8.encode(value));
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.socket.close();
    super.dispose();
  }
}
