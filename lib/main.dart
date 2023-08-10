import 'package:flutter/material.dart';
import 'package:multiplayer_tictactoe/screens/connection_screen/connection_screen.dart';
import 'package:multiplayer_tictactoe/screens/connection_screen/server_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ConnectionScreen(),
    );
  }
}
