import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    NetworkInfo().getWifiIP().then((value) {
      ipToConnect = value;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ipToConnect == null
          ? const CircularProgressIndicator()
          : QrImageView(
        data: ipToConnect ?? "",
        size: 200,
      ),
    );
  }
}
