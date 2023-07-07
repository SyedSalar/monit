import 'package:flutter/material.dart';

class KnownStudents extends ChangeNotifier {
  String _id = '';
  void getStudentId(String id) {
    _id = id;
    notifyListeners();
  }

  String get id => _id;
}
