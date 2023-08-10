import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final GlobalKey _key = GlobalKey();
  QRViewController? controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.75;
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
        const SizedBox(height: 20,),
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
            },
          ),
        ),
        const Spacer(flex: 2,),
      ],
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
