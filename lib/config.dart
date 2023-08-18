import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class Config {
  static const String url = 'http://192.168.100.5:3000/';
  // static const String url = 'http://atusum.com:3000/';
  // static const String url = 'http://atusum.com:3002/';
  static const LatLng initialCameraPos = LatLng(25.790466, -108.985886);
  static const Map<String, String> httpDefaultHeaders = <String, String>{
    'Content-Type': 'application/json; charset=UTF-8',
  };
  static const String mapsApiKey = "AIzaSyAZ6uoUZACCL6m4DhDO8KJXFD1b6pvdfjw";
}

class Globals {
  static final GlobalKey key = GlobalKey<NavigatorState>();
}

class Formats {
  static final DateFormat _dateFormat = DateFormat("dd-MM-yyyy hh:mm a");
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }
}

class ColorPalette {
  static const Color primaryText = Color(0xFF555555);
  static const Color secondaryText = Color(0xFF888888);
  static const Color primaryBase = Color(0xFF3498db);
  static const Color primaryBaseDark = Color(0xFF287cb5);
  static const Color danger = Colors.red;
  static const Color background = Color.fromRGBO(235, 235, 235, 1);
}
