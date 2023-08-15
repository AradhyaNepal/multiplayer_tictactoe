import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multiplayer_tictactoe/tic_tac_toe.dart';
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
    final size=MediaQuery.of(context).size;
    final scannerSize = size.width * 0.6;
    return SizedBox(
      height:size.height,
      width: size.width,
      child: Stack(
        children: [
          Positioned.fill(
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
                    final data = event.code;
                    if (data == null) return;
                    log("Url To Connect $data");
                    final [url,port]=data.split("--");
                    final address=InternetAddress(url,type: InternetAddressType.IPv4);

                    Socket socket = await Socket.connect(
                      address,
                      int.parse(port),
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
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.red,
                      width: 10,
                    ),
                  ),
                  height: scannerSize,
                  width: scannerSize,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
