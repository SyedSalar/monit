import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:monit/main.dart';
import 'package:monit/screens/data_screen.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;
import 'package:path_provider/path_provider.dart';
import '../Provider/known_dataProvider.dart';
import '../backend/database_helper.dart';

class FormScreen extends StatefulWidget {
  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final _picker = ImagePicker();
  File? _imageFile;
  late DatabaseHelper _databaseHelper;

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await _picker.pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  Future<String> _saveImageLocally(List<int> imageBytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final imageName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final imagePath = path_helper.join(directory.path, imageName);
    await File(imagePath).writeAsBytes(imageBytes);
    return imagePath;
  }

  Future<List<Map<String, dynamic>>> _retrieveImagesFromDatabase() async {
    final List<Map<String, dynamic>> images =
        await _databaseHelper.getStudents();
    return images;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please add an image!')),
        );
        return;
      }

      final imageBytes = await _imageFile!.readAsBytes();
      final imagePath = await _saveImageLocally(imageBytes);

      Map<String, dynamic> student = {
        'student_id': _studentIdController.text,
        'student_name': _studentNameController.text,
        'guardian_name': _guardianNameController.text,
        'class': _classController.text,
        'image': imagePath,
        'defaulter': 1,
        'sync': 0,
      };
      print('Student Data: $student');
      List<Map<String, dynamic>> existingStudents =
          await _databaseHelper.getStudents();
      bool isDuplicate = existingStudents.any((existingStudent) =>
          existingStudent['student_id'] == student['student_id']);

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student with this ID already exists!')),
        );
        return;
      }

      int result = await DatabaseHelper.instance.insertStudent(student);
      if (result != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student added successfully!')),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add student!')),
        );
      }
    }
  }

  void _resetForm() {
    _studentIdController.clear();
    _studentNameController.clear();
    _guardianNameController.clear();
    _classController.clear();
    setState(() {
      _imageFile = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _pickImage(ImageSource.camera),
                      child: Row(
                        children: [
                          Icon(Icons.camera),
                          Text('Camera'),
                        ],
                      ),
                    ),
                    SizedBox(width: 50.0),
                    ElevatedButton(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      child: Row(
                        children: [
                          Icon(Icons.photo_library_outlined),
                          Text('Gallery'),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_imageFile != null) ...[
                  Center(
                    child: SizedBox(
                        height: 200,
                        width: 200,
                        child: Image.file(_imageFile!)),
                  ),
                  SizedBox(height: 10),
                ],
                TextFormField(
                  controller: _studentIdController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter Student ID';
                    }
                    return null;
                  },
                  decoration: InputDecoration(labelText: 'Student ID'),
                ),
                TextFormField(
                  controller: _studentNameController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter Student Name';
                    }
                    return null;
                  },
                  decoration: InputDecoration(labelText: 'Student Name'),
                ),
                TextFormField(
                  controller: _guardianNameController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter Father/Guardian Name';
                    }
                    return null;
                  },
                  decoration:
                      InputDecoration(labelText: 'Father/Guardian Name'),
                ),
                TextFormField(
                  controller: _classController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter Class';
                    }
                    return null;
                  },
                  decoration: InputDecoration(labelText: 'Class'),
                ),
                // TextFormField(
                //   controller: TextEditingController(text: sync.toString()),
                //   enabled: false,
                //   decoration: InputDecoration(
                //     labelText: 'Synced',
                //   ),
                // ),
                SizedBox(height: 16.0),
                SizedBox(height: 8.0),
                SizedBox(height: 16.0),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _submitForm();
                    },
                    child: Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RetrieveScreen extends StatefulWidget {
  @override
  _RetrieveScreenState createState() => _RetrieveScreenState();
}

class _RetrieveScreenState extends State<RetrieveScreen> {
  String _studentId = '';

  late DatabaseHelper _databaseHelper;
  List<Map<String, dynamic>> _students = [];
  List<bool> isChecked = [];
  List<bool> populateList(int length) {
    return List.filled(length, false);
  }

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper.instance;
  }

  Future<void> _retrieveStudent() async {
    String studentId = _studentId;
    Map<String, dynamic>? student = await _databaseHelper.getStudentById(pass);

    if (student != null) {
      // Perform the asynchronous work outside of setState()
      await _updateStudentAndDatabase(student);
    } else {
      setState(() {
        _students = [];
      });
    }
  }

  _updateStudentAndDatabase(Map<String, dynamic> student) {
    setState(() {
      _students.add(student);
      print(_students);
      if (student['defaulter'] == 0.0)
        isChecked.add(true);
      else
        isChecked.add(false);
      print(isChecked);
    });
  }

  Future<File?> getImageFile(String imageName) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String filePath = '${appDocDir.path}/$imageName';
    File imageFile = File(filePath);
    if (await imageFile.exists()) {
      return imageFile;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter Student ID:'),
            SizedBox(height: 8.0),
            Consumer<KnownStudents>(builder: (context, knownstudents, child) {
              return Text(knownstudents.id);
            }),
            SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: _retrieveStudent,
                child: Text('Retrieve'),
              ),
            ),
            SizedBox(height: 16.0),
            // receivedImage == null
            //     ?
            Expanded(
              child: ListView.builder(
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final imagePath = _students[index]['image'] as String;
                  Map<String, dynamic> student = _students[index];
                  if (student['col_defaulter'] == 0.0)
                    isChecked[index] == true;
                  else if (student['col_defaulter'] == 1.0)
                    isChecked[index] == false;
                  return FutureBuilder<File?>(
                      future: getImageFile(imagePath),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          final imageFile = snapshot.data;
                          return Column(
                            children: [
                              SizedBox(
                                height: 20,
                              ),
                              Stack(children: [
                                SizedBox(
                                  height: 200,
                                  width: screenWidth,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Card(
                                      color: Colors.white,
                                      elevation: 6,
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 130.0),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Student ID: ',
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16),
                                                ),
                                                Text(
                                                    '${student['student_id']}'),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 130.0),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Name: ',
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16),
                                                ),
                                                Text(
                                                    '${student['student_name']}'),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 130.0),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Guardian: ',
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16),
                                                ),
                                                Text(
                                                    '${student['guardian_name']}'),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 130.0),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Class: ',
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16),
                                                ),
                                                Text('${student['class']}'),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 130.0),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Synced: ',
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16),
                                                ),
                                                Text('${student['sync']}'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (isChecked[index] == false)
                                  Positioned(
                                    bottom: 2,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Container(
                                        alignment: Alignment.center,
                                        width: screenWidth,
                                        height: 50,
                                        child: Text(
                                          'Verified',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        color: Colors.green,
                                      ),
                                    ),
                                  )
                                else if (isChecked[index] == true)
                                  Positioned(
                                    bottom: 2,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Container(
                                        alignment: Alignment.center,
                                        width: screenWidth,
                                        height: 50,
                                        child: Text(
                                          'Defaulter',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  left: 10,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Image.file(
                                        File(_students[index]['image']),
                                        width: 100,
                                        height: 160,
                                        fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                    right: 30,
                                    child: Switch(
                                      value: isChecked[index],
                                      onChanged: (value) {
                                        setState(() {
                                          isChecked[index] = !isChecked[index];
                                          print(isChecked[index]);
                                          if (isChecked[index]) {
                                            // Update the 'defaulter' column in the database
                                            _true(student);
                                          }
                                          if (!isChecked[index]) {
                                            // Update the 'defaulter' column in the database
                                            _false(student);
                                          }
                                        });
                                      },
                                    ))
                              ]),
                            ],
                          );
                        } else {
                          return ListTile(
                            leading: SizedBox(
                              height: 100,
                              width: 100,
                              child: Text('Unknown'),
                            ),
                          );
                        }
                      });
                },
              ),
            )
            // : Image(
            //     image: receivedImage!
            //         .image, // Access the ImageProvider if receivedImage is not null
            //   )
          ],
        ),
      ),
    );
  }

  Future<void> _true(Map<String, dynamic> student) async {
    Map<String, dynamic> updatedStudent = Map.from(student);
    updatedStudent[_databaseHelper.colDefaulter] = 0.0;
    await _databaseHelper.updateStudent(updatedStudent);
  }

  Future<void> _false(Map<String, dynamic> student) async {
    Map<String, dynamic> updatedStudent = Map.from(student);
    updatedStudent[_databaseHelper.colDefaulter] = 1.0;
    await _databaseHelper.updateStudent(updatedStudent);
  }
}
