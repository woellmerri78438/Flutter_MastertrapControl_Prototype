import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import './ChatPage.dart';
import './BluetoothDeviceListEntry.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  //for devices list:
  List<_DeviceWithAvailability> masterDevicesPaired =
      List<_DeviceWithAvailability>.empty(growable: true);
  List<Container> list = List<Container>.empty(growable: true);
  bool _isGettingPairedDevices = false;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });

    _getPairedDevices();
  }

  void _getPairedDevices() {
    list.clear();
    masterDevicesPaired.clear();
    setState(() {
      _isGettingPairedDevices = true;
    });
    //get paired devices, (only HC-05s)
    FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((List<BluetoothDevice> bondedDevices) {
      for (var bdevice in bondedDevices) {
        if (bdevice.name == "MasterTrap") {
          masterDevicesPaired
              .add(_DeviceWithAvailability(bdevice, _DeviceAvailability.maybe));
        }
      }
      setState(() {
        list = masterDevicesPaired
            .map((e) => Container(
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    border: Border.symmetric(
                        horizontal:
                            BorderSide(color: Colors.black, width: 0.5))),
                child: BluetoothDeviceListEntry(
                    device: e.device,
                    onTap: () => _startControl(context, e.device))))
            .toList();
        _isGettingPairedDevices = false;
      });
    });
  }

  List<Widget> listOrEmpty() {
    if (list.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.all(15.0),
          child: Container(
              decoration: BoxDecoration(
                  color: Color.fromARGB(48, 228, 226, 226),
                  border: Border.symmetric(
                      horizontal: BorderSide(color: Colors.black, width: 0.5))),
              child: Text(
                "None...",
                style: TextStyle(fontSize: 18),
              )),
        )
      ];
    } else {
      return list;
    }
  }

  Widget getRefreshButton() {
    if (_isGettingPairedDevices) {
      return FittedBox(
        child: Container(
          margin: new EdgeInsets.all(16.0),
          child: const CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(
              Colors.white,
            ),
          ),
        ),
      );
    } else {
      return IconButton(
        color: Colors.black,
        iconSize: 28,
        icon: const Icon(Icons.replay),
        onPressed: _getPairedDevices,
      );
    }
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('Trap Indicator Master Control App')),
      ),
      // ignore: avoid_unnecessary_containers
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/Falle.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          children: <Widget>[
            SwitchListTile(
              title: Text(
                'Bluetooth is ${stateToText()} ',
                style: TextStyle(fontSize: 18),
              ),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async {
                  // async lambda seems to not working
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }

                future().then((_) {
                  setState(() {});
                });
              },
            ),
            Container(
              decoration: BoxDecoration(
                  color: Color.fromARGB(48, 228, 226, 226),
                  border: Border.symmetric(
                      horizontal: BorderSide(color: Colors.black, width: 0.5))),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Flexible(
                          child: Text(
                            "Before connecting to a master trap device, it has to be paired",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        ElevatedButton(
                          child: const Text('Settings'),
                          onPressed: () {
                            FlutterBluetoothSerial.instance.openSettings();
                          },
                        ),
                      ],
                    ),
                    const Text(
                        "If it has not been paired yet, please search it in your Bluetooth settings and pair with the PIN 1234",
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Column(
              children: [
                Container(
                  color: Color.fromARGB(48, 255, 255, 255),
                  child: ListTile(
                    leading: const Text(
                      'Paired master devices:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    trailing: getRefreshButton(),
                  ),
                ),
                ListView(shrinkWrap: true, children: listOrEmpty()),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _startControl(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server); //ControlPage(server: server); //
        },
      ),
    );
  }

  String stateToText() {
    return _bluetoothState.isEnabled ? 'enabled' : 'disabled';
  }
}

enum _DeviceAvailability {
  no,
  maybe,
  yes,
}

class _DeviceWithAvailability {
  BluetoothDevice device;
  _DeviceAvailability availability;
  int? rssi;

  _DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}
