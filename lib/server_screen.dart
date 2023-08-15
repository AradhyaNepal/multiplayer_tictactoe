import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multiplayer_tictactoe/tic_tac_toe.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  String appDriveLink =
      "https://drive.google.com/drive/folders/1j2jfecUFIdPj8l5yBlbCEIjkxHZEPqk6?usp=sharing";
  String? ipAddress;
  ServerSocket? socket;
  final portController = TextEditingController();
  bool validPort = true;
  bool _startingServer = true;
  String? wifiName;

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
    try {
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
    } catch (e, s) {
      log(e.toString());
      log(s.toString());
      setState(() {
        validPort = false;
        _startingServer = false;
      });
    }
  }

  Future<void> getUrl() async {
    try {
      final networkInfo = NetworkInfo();
      ipAddress = await networkInfo.getWifiIP();
      wifiName = await networkInfo.getWifiName();
      setState(() {});
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
        ipAddress = value;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.shortestSide < 600
        ? MediaQuery.of(context).size.width * 0.75
        : 500.0;
    return ipAddress == null || _startingServer
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                if (wifiName != null && wifiName != "")
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        "Wifi required to connect the QR:\n$wifiName",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
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
                SizedBox(
                  height: size / 7,
                ),
                if (validPort) ...[
                  QrImageView(
                    data: "$ipAddress--${portController.text}",
                    size: size,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 30,
                              ),
                              child: QrImageView(
                                data: appDriveLink,
                                size: size,
                              ),
                            );
                          });
                    },
                    child: const Text("Share App with QR"),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: appDriveLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Copied to Clipboard",
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.copy,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ] else
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
