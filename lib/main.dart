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

String pass = '';
Image? receivedImage;

void main() {
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

  // void _receiveData() {
  //   KnownStudents knownStudents =
  //       Provider.of<KnownStudents>(context, listen: false);
  //   List<int> buffer = []; // Buffer to accumulate incoming data

  //   _connection!.input?.listen((List<int> data) {
  //     buffer.addAll(data); // Add incoming data to the buffer
  //     print('buffer $buffer');
  //     // Check if a complete message is received
  //     if (buffer.contains(10)) {
  //       // Assuming 10 is the delimiter character indicating the end of a message
  //       String message = utf8.decode(buffer);

  //       if (message.startsWith('id')) {
  //         // Process student ID message
  //         setState(() {
  //           _message = message;
  //           pass = _message;
  //           knownStudents.getStudentId(_message);
  //         });
  //         buffer.clear(); // Clear the buffer for the next message
  //       } else {
  //         // Process image data
  //         Uint8List imageData = Uint8List.fromList(buffer);
  //         print(imageData);
  //         buffer.clear(); // Clear the buffer for the next message

  //         // Write the image data to a file (optional)
  //         _writeImageDataToFile(imageData).then((String imagePath) {
  //           // Display the image in the app
  //           setState(() {
  //             receivedImage = Image.file(File(imagePath));
  //           });
  //         });
  //       }
  //     }
  //   });
  // }

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
                // Sync();
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

Future<void> initializeFirebase() async {
  await Firebase.initializeApp();
}

// Future<void> syncData() async {
//   late DatabaseHelper _databaseHelper;
//   try {
//     // Initialize Firebase
//     await initializeFirebase();
//     _databaseHelper = DatabaseHelper.instance;

//     // Access your local database using _databaseHelper instance
//     List<Map<String, dynamic>> localData = await _databaseHelper.getStudents();

//     // Connect to Firebase Storage
//     FirebaseStorage storage = FirebaseStorage.instance;

//     // Iterate through the local data and upload images to Firebase Storage
//     for (var student in localData) {
//       if (student['sync'] == 0) {
//         // Get the image file associated with the student
//         File imageFile = File(student['image']);

//         // Generate a unique filename for the image
//         String fileName = Path.basename(imageFile.path);

//         // Create a storage reference for the image file
//         Reference storageRef = storage.ref().child('images/$fileName');

//         // Upload the image file to Firebase Storage
//         TaskSnapshot snapshot = await storageRef.putFile(imageFile);

//         // Get the download URL of the uploaded image
//         String imageUrl = await snapshot.ref.getDownloadURL();

//         // Update the student's data with the image URL
//         student['imageUrl'] = imageUrl;

//         // Update the synced value to 1 in your local database
//         student['sync'] = 1;
//         await _databaseHelper.updateStudent(student);
//       }
//     }

//     print('Data synchronization complete!');
//   } catch (e) {
//     print('Data synchronization failed: $e');
//   }
// }

Future<void> syncData() async {
  late DatabaseHelper _databaseHelper;
  try {
    // Initialize Firebase
    await initializeFirebase();
    _databaseHelper = DatabaseHelper.instance;

    // Access your local database using _databaseHelper instance
    List<Map<String, dynamic>> localData = await _databaseHelper.getStudents();

    // Connect to Firebase Storage
    FirebaseStorage storage = FirebaseStorage.instance;

    // Iterate through the local data and upload images to Firebase Storage
    for (var student in localData) {
      if (student['sync'] == 0) {
        // Get the image file associated with the student
        File imageFile = File(student['image']);

        // Generate a unique filename for the image
        String fileName = Path.basename(imageFile.path);

        // Create a storage reference for the image file
        Reference storageRef = storage.ref().child('images/$fileName');

        // Upload the image file to Firebase Storage
        TaskSnapshot snapshot = await storageRef.putFile(imageFile);

        // Get the download URL of the uploaded image
        String imageUrl = await snapshot.ref.getDownloadURL();
        Map<String, dynamic> studentData = {
          'studentId': student['student_id'],
          'imageUrl': imageUrl,
        };
        // Convert the Map to List<int>
        List<int> jsonData = utf8.encode(jsonEncode(studentData));

        // Convert List<int> to Uint8List
        Uint8List data = Uint8List.fromList(jsonData);

        // Store the student ID and image URL in Firebase
        await storageRef.putData(data);

        // Update the synced value to 1 in your local database
        student['sync'] = 1;
        await _databaseHelper.updateStudent(student);
      }
    }

    print('Data synchronization complete!');
  } catch (e) {
    print('Data synchronization failed: $e');
  }
}
