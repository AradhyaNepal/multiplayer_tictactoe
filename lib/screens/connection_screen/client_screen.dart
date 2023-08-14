import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final GlobalKey _key = GlobalKey();
  QRViewController? controller;
  bool loaded=false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.shortestSide<600?MediaQuery.of(context).size.width * 0.75: 500.0;
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
              this.controller?.scannedDataStream.listen((event) {
                if(loaded)return;
                loaded=true;
                Future.delayed(Duration(seconds: 1),(){
                  loaded=false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(event.code.toString())));
                IO.Socket socket = IO.io('http://${event.code}:3000');
                socket.onConnect((_) async {
                  await Future.delayed(const Duration(seconds: 1));
                  socket.emit('msg', 'I am connected');
                });
                socket.on('msg', (data) async {
                  await Future.delayed(const Duration(seconds: 1));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(data.toString())));
                });
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
