// import 'package:flutter/material.dart';
// import 'package:monit/screens/data_screen.dart';
// import 'package:monit/screens/form.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         home: DefaultTabController(
//       initialIndex: 1,
//       length: 3,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text('Monitt'),
//           centerTitle: true,
//           bottom: const TabBar(
//             tabs: <Widget>[
//               Tab(
//                 text: 'Student Form',
//               ),
//               Tab(
//                 text: 'Registration',
//               ),
//               Tab(
//                 text: 'Monitoring',
//               ),
//             ],
//           ),
//         ),
//         body: TabBarView(
//           children: <Widget>[
//             Center(
//               child: FormScreen(),
//             ),
//             Center(child: DataScreen()),
//             Center(
//               child: RetrieveScreen(),
//             ),
//           ],
//         ),

//         // Stack(
//         //   children: [
//         //     SizedBox(
//         //       height: 50,
//         //     ),
//         //     Container(
//         //       color: Colors.green,
//         //     ),
//         //     const Positioned(
//         //       top: 100, // Adjust the position of the card as needed
//         //       left: 20, // Adjust the position of the card as needed
//         //       right: 20, // Adjust the position of the card as needed
//         //       child: Card(
//         //         elevation: 10,
//         //         color: Colors.blue, // Set the desired color for the card
//         //         child: Padding(
//         //           padding: EdgeInsets.all(20.0),
//         //           child: Text(
//         //             'Hello, Card!',
//         //             style: TextStyle(
//         //               fontSize: 20,
//         //               fontWeight: FontWeight.bold,
//         //               color: Colors.white,
//         //             ),
//         //           ),
//         //         ),
//         //       ),
//         //     ),
//         //   ],
//         // ),
//       ),
//     ));
//   }
// }

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:monit/screens/data_screen.dart';
import 'package:monit/screens/form.dart';

String pass = '';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Example',
      home: BluetoothScreen(),
    );
  }
}

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _getDevices();
  }

  Future<void> _getDevices() async {
    _devices = await _bluetooth.getBondedDevices();
    setState(() {});
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_connection != null) {
      await _connection!.close();
    }

    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      print('Connected to ${device.name}');
      setState(() {
        _connection = connection;
        _selectedDevice = device;
        _isConnected = true;
      });
      _receiveData();
    } catch (error) {
      print('Connection failed: $error');
      setState(() {
        _isConnected = false;
      });
    }
  }

  Future<void> _disconnect() async {
    if (_connection != null) {
      await _connection!.close();
      setState(() {
        _isConnected = false;
        _selectedDevice = null;
      });
    }
  }

  void _sendMessage(String message) async {
    if (_connection != null) {
      List<int> messageBytes = utf8.encode(message);
      _connection!.output.add(Uint8List.fromList(messageBytes));
      await _connection!.output.allSent;
      setState(() {
        _message = message;
      });
    }
  }

  void _receiveData() {
    List<int> buffer = []; // Buffer to accumulate incoming data

    _connection!.input?.listen((List<int> data) {
      buffer.addAll(data); // Add incoming data to the buffer

      // Check if a complete message is received
      if (buffer.contains(10)) {
        // Assuming 10 is the delimiter character indicating the end of a message
        String message = utf8.decode(buffer);
        setState(() {
          _message = message;
          pass = _message;
        });
        buffer.clear(); // Clear the buffer for the next message
      }
    });
  }

  void _navigateToNextScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Example'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyHomePage()),
              );
            },
            icon: Icon(Icons.navigate_next_sharp),
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Bluetooth Devices:',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_devices[index].name ?? ''),
                    onTap: () {
                      _connectToDevice(_devices[index]);
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Selected Device: ${_selectedDevice?.name ?? 'None'}',
              style: TextStyle(fontSize: 18.0),
            ),
            SizedBox(height: 8.0),
            ElevatedButton(
              child: Text(_isConnected ? 'Disconnect' : 'Connect'),
              onPressed: _isConnected ? _disconnect : null,
            ),
            SizedBox(height: 16.0),
            Text(
              'Received Message:',
              style: TextStyle(fontSize: 18.0),
            ),
            SizedBox(height: 8.0),
            Text(_message),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Send Message',
              ),
              onChanged: (value) {
                setState(() {
                  _message = value;
                });
              },
            ),
            SizedBox(height: 8.0),
            ElevatedButton(
              child: Text('Send'),
              onPressed: _isConnected ? () => _sendMessage(_message) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return (MaterialApp(
        home: DefaultTabController(
      initialIndex: 1,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Monitt'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(
                text: 'Student Form',
              ),
              Tab(
                text: 'Registration',
              ),
              Tab(
                text: 'Monitoring',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            Center(
              child: FormScreen(),
            ),
            Center(child: DataScreen()),
            Center(
              child: RetrieveScreen(),
            ),
          ],
        ),
      ),
    )));
  }
}
