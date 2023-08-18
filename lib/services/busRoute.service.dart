import 'dart:async';
import 'dart:convert';
import 'package:atusum/config.dart';
import 'package:atusum/helpers/exception_helper.dart';
import 'package:atusum/models/bus_route.dart';
import 'package:http/http.dart' as http;

class BusRouteService {
  Future<BusRoute> getRouteById(String routeId) async {
    try {
      var body = <String, String>{'routeId': routeId};
      final response = await http.post(Uri.parse(Config.url + 'route/find'),
          headers: Config.httpDefaultHeaders, body: jsonEncode(body));

      return BusRoute.fromJson(jsonDecode(response.body));
    } catch (ex) {
      ExceptionHelper.handleException(ex);
    }

    return null;
  }

  Future<List<BusRoute>> getActiveRoutes() async {
    try {
      var body = <String, dynamic>{'active': true};
      final response = await http.post(Uri.parse(Config.url + 'route/find'),
          headers: Config.httpDefaultHeaders, body: jsonEncode(body));

      var rawRouteList = jsonDecode(response.body) as List<dynamic>;
      List<BusRoute> routeList = [];
      for (var br in rawRouteList) {
        routeList.add(BusRoute.fromJson(br));
      }
      return routeList;
    } catch (ex) {
      ExceptionHelper.handleException(ex);
    }

    return [];
  }
}
