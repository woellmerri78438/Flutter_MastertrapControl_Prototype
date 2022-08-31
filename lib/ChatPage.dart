import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({required this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  BluetoothConnection? connection;

  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  bool nonbusyButtonactive = true;
  bool validnrinput = false;
  String validnrtext = "";

  bool validmininput = false;
  String validmintext = "";

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Row> list = messages.map((_message) {
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                (text) {
                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                }(_message.text.trim()),
                style: TextStyle(color: Colors.white)),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 300.0,
            decoration: BoxDecoration(
                color:
                    _message.whom == clientID ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();

    final serverName = widget.server.name ?? "Unknown";
    return Scaffold(
      appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting to $serverName...')
              : isConnected
                  ? Text('Live Connection with $serverName')
                  : Text('Connection lost with $serverName'))),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Flexible(
              child: ListView(
                  padding: const EdgeInsets.all(12.0),
                  controller: listScrollController,
                  children: list),
            ),
            Container(
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.black))),
              height: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Commandbutton(
                        onPress: () {
                          _sendMessage("GSMTest");
                        },
                        text: "GSM-Test",
                        active: isConnected && nonbusyButtonactive,
                      ),
                      Commandbutton(
                        onPress: () {
                          _sendMessage("Batterytest");
                        },
                        text: "Batterytest",
                        active: isConnected && nonbusyButtonactive,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Commandbutton(
                        onPress: () {
                          _sendMessage("LoRaDevices");
                        },
                        text: "Register slaves",
                        active: isConnected && nonbusyButtonactive,
                      ),
                      Commandbutton(
                        onPress: () {
                          _sendMessage("Startsleep");
                        },
                        text: "Start trapmode",
                        active: isConnected && nonbusyButtonactive,
                      ),
                    ],
                  ),
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.black))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 150,
                          child: TextField(
                            maxLength: 14,
                            decoration:
                                InputDecoration(hintText: "+49XXXXXXXXXXX"),
                            keyboardType: TextInputType.phone,
                            onChanged: (textinput) {
                              setState(() {
                                if (textinput.startsWith('+') &&
                                    textinput.length == 14 &&
                                    isNumericUsingRegularExpression(
                                        textinput.substring(1))) {
                                  validnrinput = true;
                                  validnrtext = textinput;
                                } else {
                                  validnrinput = false;
                                }
                              });
                            },
                          ),
                        ),
                        Commandbutton(
                            onPress: () {
                              _sendMessage("NewNr: " + validnrtext);
                            },
                            text: "Set new target-nr.",
                            active: validnrinput &&
                                isConnected &&
                                nonbusyButtonactive)
                      ],
                    ),
                  ),
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.black))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 150,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  textAlign: TextAlign.end,
                                  maxLength: 8,
                                  decoration: InputDecoration(
                                      hintText: "0", counterText: ""),
                                  keyboardType: TextInputType.numberWithOptions(
                                      signed: false, decimal: false),
                                  onChanged: (textinput) {
                                    setState(() {
                                      if (RegExp(r'^[0-9]+$')
                                              .hasMatch(textinput) &&
                                          textinput
                                              .contains(RegExp(r'[1-9]'))) {
                                        validmininput = true;
                                        validmintext = textinput;
                                      } else {
                                        validmininput = false;
                                      }
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text("min"),
                            ],
                          ),
                        ),
                        Commandbutton(
                            onPress: () {
                              String temptext8 = "";
                              if (validmintext.length < 8) {
                                int missin = 8 - validmintext.length;
                                for (var i = 1; i <= missin; i++) {
                                  temptext8 = '${temptext8}0';
                                }
                                temptext8 = temptext8 + validmintext;
                              } else {
                                temptext8 = validmintext;
                              }
                              _sendMessage("NewWakeup: $temptext8");
                            },
                            text: "Set new wakeup interval",
                            active: validmininput &&
                                isConnected &&
                                nonbusyButtonactive)
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        String msgtext = backspacesCounter > 0
            ? _messageBuffer.substring(
                0, _messageBuffer.length - backspacesCounter)
            : _messageBuffer + dataString.substring(0, index);

        messages.add(
          _Message(
            1,
            msgtext,
          ),
        );
        _messageBuffer = dataString.substring(index);

        bool busystart = msgtext.contains('Reading') ||
            msgtext.contains('GSM-Test started') ||
            msgtext.contains('Searching LoRa') ||
            msgtext.contains('Initializing Sleep') ||
            msgtext.contains('Storing');
        bool busyend = msgtext.contains('Error') ||
            msgtext.contains('-> GSM-Test') ||
            msgtext.contains('LoRa TX Error') ||
            msgtext.contains('Registration process completed') ||
            msgtext.contains('Extreme') ||
            msgtext.contains('That') ||
            msgtext.contains('Initiation of sleep mode canceled') ||
            msgtext.contains('Successfully stored') ||
            msgtext.contains('No valid');

        if (busystart) {
          nonbusyButtonactive = false;
        }
        if (busyend) {
          nonbusyButtonactive = true;
        }
      });
      Future.delayed(Duration(milliseconds: 100)).then((_) {
        listScrollController.animateTo(
            listScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 100),
            curve: Curves.easeOut);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();
    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode("$text\r\n")));
        await connection!.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}

class Commandbutton extends StatelessWidget {
  void Function()? onPress;
  String text;
  bool active;

  Commandbutton({
    required this.onPress,
    required this.text,
    required this.active,
    Key? key,
  }) : super(key: key);

  ButtonStyle isactivated(bool active) {
    if (active) {
      return ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) return Colors.lightBlue;
            return Colors.blue; // Use the component's default.
          },
        ),
        maximumSize: MaterialStateProperty.all<Size>(Size(150, 45)),
        minimumSize: MaterialStateProperty.all<Size>(Size(150, 45)),
      );
    } else {
      return ButtonStyle(
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) return Colors.grey;
            return Colors.grey; // Use the component's default.
          },
        ),
        maximumSize: MaterialStateProperty.all<Size>(Size(150, 45)),
        minimumSize: MaterialStateProperty.all<Size>(Size(150, 45)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: active ? onPress : () {},
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              decoration:
                  active ? TextDecoration.none : TextDecoration.lineThrough),
        ),
        style: isactivated(active));
  }
}

bool isNumericUsingRegularExpression(String string) {
  final numericRegex = RegExp(r'^-?(([0-9]*)|(([0-9]*)\.([0-9]*)))$');

  return numericRegex.hasMatch(string);
}
