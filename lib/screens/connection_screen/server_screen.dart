import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:socket_io/socket_io.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  String? ipToConnect;

  @override
  void initState() {
    super.initState();
    // Dart server
    var io = Server();
    io.on('connection', (client) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(client.toString())));
      client.on('msg', (data) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(client.toString())));
        client.emit('msg', "Welcome");
      });
    });
    io.listen(3000);
    NetworkInfo().getWifiIP().then((value) {
      ipToConnect = value;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.75;
    return Center(
      child: ipToConnect == null
          ? const CircularProgressIndicator()
          : QrImageView(
        data: ipToConnect ?? "",
        size: size,
      ),
    );
  }
}
