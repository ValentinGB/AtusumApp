import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusRoute {
  bool active;
  List<LatLng> wayPoints;
  int routeLength;
  String id;
  String name;
  List<String> places;
  bool isGooglePlace;

  BusRoute(
      {this.active,
      this.wayPoints,
      this.routeLength,
      this.id,
      this.name,
      this.places,
      this.isGooglePlace});

  BusRoute.fromJson(Map<String, dynamic> json) {
    active = json['active'];
    places = [];
    routeLength = json['routeLength'];
    id = json['_id'];
    name = json['name'];
    wayPoints = [];
    isGooglePlace = false;

    if (json["places"] != null) {
      var _places = json["places"];
      _places.forEach((p) {
        places.add(p);
      });
    }

    if (json["wayPoints"] == null) return;
    var _wayPoints = json["wayPoints"];
    _wayPoints.forEach((wp) {
      wayPoints.add(LatLng(wp["lat"], wp["lng"]));
    });
  }
}

class RouteDistance {
  double fromUserToRoute;
  double fromRouteToPoint;
  BusRoute route;

  RouteDistance({this.fromRouteToPoint, this.fromUserToRoute, this.route});
}
