import 'dart:async';
import 'dart:convert';
import 'package:atusum/config.dart';
import 'package:atusum/helpers/exception_helper.dart';
import 'package:atusum/models/bus.dart';
import 'package:atusum/models/bus_location_data.dart';
import 'package:http/http.dart' as http;

class BusService {
  Future<Bus> getBusById(String busId) async {
    try {
      var body = <String, String>{'busId': busId};
      final response = await http.post(Uri.parse(Config.url + 'bus/find'),
          headers: Config.httpDefaultHeaders, body: jsonEncode(body));

      return Bus.fromJson(jsonDecode(response.body));
    } catch (ex) {
      ExceptionHelper.handleException(ex);
    }
    return null;
  }

  Future<List<Bus>> getAllBuses() async {
    try {
      final response = await http.post(Uri.parse(Config.url + 'bus/find'),
          headers: Config.httpDefaultHeaders);

      var busesRawList = jsonDecode(response.body) as List<dynamic>;
      List<Bus> busesList = [];
      for (var br in busesRawList) {
        busesList.add(Bus.fromJson(br));
      }
      return busesList;
    } catch (ex) {
      ExceptionHelper.handleException(ex);
    }
    return [];
  }

  Future<List<Bus>> getBusesByRoute(String routeId) async {
    try {
      // var body = <String, dynamic>{'active': true, 'route': routeId};
      var body = <String, dynamic>{'route': routeId};
      final response = await http.post(Uri.parse(Config.url + 'bus/find'),
          headers: Config.httpDefaultHeaders, body: jsonEncode(body));

      var busesRawList = jsonDecode(response.body) as List<dynamic>;
      List<Bus> busesList = [];
      for (var br in busesRawList) {
        busesList.add(Bus.fromJson(br));
      }
      return busesList;
    } catch (ex) {
      ExceptionHelper.handleException(ex);
    }
    return [];
  }

  Future<List<BusLocationData>> getRouteActiveBuses(String routeId) async {
    try {
      var body = <String, dynamic>{'route': routeId};
      final response = await http.post(
          Uri.parse(Config.url + 'history/getRouteBusesLastPos'),
          headers: Config.httpDefaultHeaders,
          body: jsonEncode(body));

      var busesRawList = jsonDecode(response.body) as List<dynamic>;
      List<BusLocationData> busesList = [];
      for (var br in busesRawList) {
        busesList.add(BusLocationData.fromJson(br));
      }
      return busesList;
    } catch (ex) {
      ExceptionHelper.handleException(ex);
    }
    return [];
  }
}
