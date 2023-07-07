import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:monit/Provider/known_dataProvider.dart';
import 'package:monit/screens/data_screen.dart';
import 'package:monit/screens/form.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;
import 'package:firebase_core/firebase_core.dart';

import 'backend/database_helper.dart';
import 'firebase_options.dart';

String pass = '';
Image? receivedImage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => KnownStudents(),
      child: MyApp(),
    ),
  );
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
  List<int> receivedData = [];

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
    KnownStudents knownStudents =
        Provider.of<KnownStudents>(context, listen: false);
    List<int> buffer = []; // Buffer to accumulate incoming data
    int chunkSize = 64; // Adjust the chunk size to match the sender

    _connection!.input?.listen((List<int> data) {
      buffer.addAll(data); // Add incoming data to the buffer

      // Check if a complete message is received
      if (buffer.contains(10)) {
        // Assuming 10 is the delimiter character indicating the end of a message
        String message = utf8.decode(buffer);
        buffer.clear(); // Clear the buffer for the next message

        if (message.startsWith('id')) {
          // Process student ID message
          setState(() {
            _message = message;
            pass = _message;
            knownStudents.getStudentId(_message);
          });
        } else {
          // Process image data
          Uint8List imageData = Uint8List.fromList(buffer);
          buffer.clear(); // Clear the buffer for the next message

          // Check if the received data is equal to or larger than the chunk size
          while (imageData.length >= chunkSize) {
            Uint8List chunk =
                imageData.sublist(0, chunkSize); // Extract the chunk
            imageData = imageData.sublist(
                chunkSize); // Remove the extracted chunk from the remaining data

            // Process the chunk (e.g., write it to a file, display in UI, etc.)
            _processImageChunk(chunk);
          }

          // Store the remaining data in the buffer for the next message
          buffer.addAll(imageData);
        }
      }
    });
  }

  void _processImageChunk(Uint8List chunk) {
    // Process the received image chunk as needed (e.g., write to a file, display in UI, etc.)
    // Example: Write the chunk to a file
    _writeImageChunkToFile(chunk).then((String imagePath) {
      // Display the image chunk in the app
      setState(() {
        receivedImage = Image.file(File(imagePath));
      });
    });
  }

  Future<String> _writeImageChunkToFile(Uint8List chunk) async {
    Directory appDir = await getApplicationDocumentsDirectory();
    String imagePath = '${appDir.path}/received_image_chunk.jpg';

    File imageChunkFile = File(imagePath);
    await imageChunkFile.writeAsBytes(chunk);

    return imagePath;
  }

  Future<String> _writeImageDataToFile(Uint8List imageData) async {
    Directory appDir = await getApplicationDocumentsDirectory();
    String imagePath = '${appDir.path}/received_image.jpg';

    File imageFile = File(imagePath);
    await imageFile.writeAsBytes(imageData);

    return imagePath;
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

                  ;
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
    return (MaterialApp(
        home: DefaultTabController(
      initialIndex: 1,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Monitt'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                Sync();
              },
            ),
          ],
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

Future<void> Sync() async {
  late DatabaseHelper _databaseHelper;
  try {
    _databaseHelper = DatabaseHelper.instance;
    // Access your local database using _databaseHelper instance
    List<Map<String, dynamic>> localData = await _databaseHelper.getStudents();
    // print("localData here:");
    // print(localData);
    // Connect to Firebase Storage
    FirebaseStorage storage = FirebaseStorage.instance;

    for (var student in localData) {
      if (student['sync'] == '0') {
        File imageFile = File(student['image']);
        String studentId = student['student_id'];
        String fileName = '$studentId.png';

        Reference storageRef = storage.ref().child('images/$fileName');
        TaskSnapshot snapshot = await storageRef.putFile(imageFile);

        String imageUrl = await snapshot.ref.getDownloadURL();

        Map<String, dynamic> updatedStudent = Map.from(student);
        updatedStudent[_databaseHelper.colSync] = '1';
        await _databaseHelper.updateStudent(updatedStudent);
      }
    }

    print('Success');
  } catch (e) {
    print('Failed: $e');
  }
}
