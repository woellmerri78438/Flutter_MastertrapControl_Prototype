import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import './MainPage.dart';
import 'ChatPage.dart';

void main() => runApp(new ExampleApplication());

class ExampleApplication extends StatelessWidget {
  late final BluetoothDevice server = BluetoothDevice(address: "Dummy123");

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainPage()

        //ChatPage(
        //server: BluetoothDevice(address: "asfd"),
        //)
        );

    //MainPage());
  }
}
