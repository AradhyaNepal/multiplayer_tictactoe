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
  late Server io;
  @override
  void initState() {
    super.initState();
    // Dart server
    getIp().then((value) {
      io= Server(server: 8000);

      io.on('connection', (client) {
        final socket=client as Socket;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(socket.data.toString())));
        client.on('msg', (data) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(client.toString())));
          client.emit('msg', "Welcome");
        });
      });
      io.listen("http://$ipToConnect:8000");
    });




  }

  Future<void> getIp()async{
    try{
      NetworkInfo().getWifiIP().then((value) {
        ipToConnect = value;
        setState(() {});
      });
    }catch(e){
      print("Was here");

      final value=await showModalBottomSheet(context: context, builder: (context){
        return Form(
          child: TextField(
            decoration: const InputDecoration(
              hintText: "Enter Your device Ip"
            ),
            onSubmitted: (value){
              Navigator.pop(context,value??"") ;
            },
          ),
        );
      });
      if(value is String){
        ipToConnect=value;
        setState(() {

        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.shortestSide<600?MediaQuery.of(context).size.width * 0.75: 500.0;
    return Center(
      child: ipToConnect == null
          ? const CircularProgressIndicator()
          : QrImageView(
        data: ipToConnect ?? "",
        size: size,
      ),
    );
  }

  @override
  void dispose() {
    io.close();
    super.dispose();
  }
}
