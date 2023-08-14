import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multiplayer_tictactoe/screens/connection_screen/tic_tac_toe.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final GlobalKey _key = GlobalKey();
  QRViewController? controller;
  bool loaded = false;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return const Center(
        child: Text(
          "Device Unsupported",
        ),
      );
    }
    final size = MediaQuery.of(context).size.shortestSide < 600
        ? MediaQuery.of(context).size.width * 0.75
        : 500.0;
    return Column(
      children: [
        const Spacer(),
        const Text(
          "Scan QR",
          style: TextStyle(
            fontSize: 40,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.red,
              width: 10,
            ),
          ),
          height: size,
          width: size,
          child: QRView(
            key: _key,
            onQRViewCreated: (controller) {
              this.controller = controller;
              this.controller?.scannedDataStream.listen((event) async {
                if (loaded) return;
                loaded = true;
                Future.delayed(const Duration(seconds: 2), () {
                  loaded = false;
                });
                try {
                  final url = event.code;
                  if (url == null) return;

                  const port = 3005;
                  final address=InternetAddress(url,type: InternetAddressType.IPv4);

                  Socket socket = await Socket.connect(
                    address,
                    port,
                    sourcePort: port,
                  );
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicTacToeScreen(
                        socket: socket,
                        isServer: false,
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                    ),
                  );
                }
              });
            },
          ),
        ),
        const Spacer(
          flex: 2,
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
