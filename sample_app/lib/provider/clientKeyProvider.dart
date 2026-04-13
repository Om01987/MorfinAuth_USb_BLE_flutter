import 'package:flutter/material.dart';

class clientKeyProvider extends ChangeNotifier {
  String _storedValue = '';

  String get storedValue => _storedValue;

  void updateStoredValue(String newValue) {
    _storedValue = newValue;
    notifyListeners();
  }
}
