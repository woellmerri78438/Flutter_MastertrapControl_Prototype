import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import './BluetoothDeviceListEntry.dart';

class SelectBondedDeviceSection extends StatefulWidget {
  /// If true, on page start there is performed discovery upon the bonded devices.
  /// Then, if they are not avaliable, they would be disabled from the selection.

  const SelectBondedDeviceSection();

  @override
  _SelectBondedDeviceSection createState() => _SelectBondedDeviceSection();
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

class _SelectBondedDeviceSection extends State<SelectBondedDeviceSection> {
  List<_DeviceWithAvailability> masterDevicesPaired =
      List<_DeviceWithAvailability>.empty(growable: true);
  List<BluetoothDeviceListEntry> list =
      List<BluetoothDeviceListEntry>.empty(growable: true);

  bool _isGettingPairedDevices = false;

  // Availability

  _SelectBondedDeviceSection();

  @override
  void initState() {
    super.initState();
    _getPairedDevices();

    // Setup a list of the bonded devices
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
        //if (bdevice.name == "MasterTrap") {
        masterDevicesPaired
            .add(_DeviceWithAvailability(bdevice, _DeviceAvailability.maybe));
        //}
      }
      setState(() {
        list = masterDevicesPaired
            .map((e) => BluetoothDeviceListEntry(device: e.device))
            .toList();
        _isGettingPairedDevices = false;
      });
    });
  }

  List<Widget> listOrEmpty() {
    if (list.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("No suitable devices paired..."),
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
        icon: const Icon(Icons.replay),
        onPressed: _getPairedDevices,
      );
    }
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Paired master devices found:'),
          getRefreshButton(),
        ]),
        ListView(children: listOrEmpty()),
      ],
    );
  }
}
