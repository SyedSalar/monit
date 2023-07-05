import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path_helper;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class ImagePickerScreen extends StatefulWidget {
  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  late Future<Database> _database;
  final _picker = ImagePicker();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _database = _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = path_helper.join(directory.path, 'image_database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT
          )
        ''');
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await _picker.pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  Future<void> _saveImageToDatabase() async {
    if (_imageFile != null) {
      final imageBytes = await _imageFile!.readAsBytes();
      final imagePath = await _saveImageLocally(imageBytes);
      final Database database = await _database;
      await database.insert('images', {'path': imagePath});
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
    final Database database = await _database;
    return await database.query('images');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Picker'),
      ),
      body: Column(
        children: [
          if (_imageFile != null) ...[
            SizedBox(height: 100, width: 100, child: Image.file(_imageFile!)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveImageToDatabase,
              child: Text('Save Image to Database'),
            ),
          ],
          ElevatedButton(
            onPressed: () => _pickImage(ImageSource.camera),
            child: Text('Capture from Camera'),
          ),
          ElevatedButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            child: Text('Select from Gallery'),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _retrieveImagesFromDatabase(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final images = snapshot.data!;
                  return ListView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final imagePath = images[index]['path'] as String;
                      return SizedBox(
                          child: Image.file(
                        File(imagePath),
                        height: 100,
                        width: 100,
                      ));
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
