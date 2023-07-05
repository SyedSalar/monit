import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../backend/database_helper.dart';

class DataScreen extends StatefulWidget {
  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    List<Map<String, dynamic>> students =
        await DatabaseHelper.instance.getStudents();
    setState(() {
      _students = students;
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
      body: RefreshIndicator(
        onRefresh: _fetchStudents,
        child: ListView.builder(
          itemCount: _students.length,
          itemBuilder: (context, index) {
            final imagePath = _students[index]['image'] as String;
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
                                    padding: const EdgeInsets.only(left: 130.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Student ID: ',
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        Text(
                                            '${_students[index]['student_id']}'),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 130.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Name: ',
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        Text(
                                            '${_students[index]['student_name']}'),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 130.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Guardian: ',
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        Text(
                                            '${_students[index]['guardian_name']}'),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 130.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Class: ',
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        Text('${_students[index]['class']}'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _students[index]['defaulter'] == 1.0
                            ? Positioned(
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
                            : Positioned(
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
                            child: Image.file(File(_students[index]['image']),
                                width: 100, height: 160, fit: BoxFit.cover),
                          ),
                        )
                      ]),
                    ],
                  );
                } else {
                  return ListTile(
                    leading: SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
