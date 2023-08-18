import 'package:flutter/material.dart';

class SnackBarService {
  show(String message, BuildContext context) {
    var snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
