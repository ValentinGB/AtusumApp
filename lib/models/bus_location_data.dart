import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'bus.dart';

class BusLocationData {
  String busId;
  String routeId;
  String deviceId;
  LatLng position;
  LatLng previousPosition;
  double busDistanceToUser;
  double timeToArrive;
  bool isInsideRoute;
  int timesOutOfRoute;
  double angle;
  double speed;
  DateTime date;
  Bus bus;
  int ticksWithoutMovement;

  BusLocationData({
    this.busId,
    this.routeId,
    this.deviceId,
    this.position,
    this.speed,
    this.date,
  });

  BusLocationData.fromJson(Map<String, dynamic> json) {
    ticksWithoutMovement = 0;
    timesOutOfRoute = 0;
    busDistanceToUser = null;
    timeToArrive = null;
    isInsideRoute = false;
    if (json["bus"] != null && json["bus"] is! String) {
      bus = Bus.fromJson(json["bus"]);
      busId = bus.id;
    } else {
      busId = json["bus"];
    }
    routeId = json["route"];
    deviceId = json["device"];
    position = LatLng(double.parse(json["lat"].toString()),
        double.parse(json["lng"].toString()));
    previousPosition = position;
    speed = _knotsToKm(double.parse(json["speed"].toString()));
    date = DateTime.parse(json["date"].toString());
  }

  double _knotsToKm(double knots) {
    return knots * 1.852;
  }
}
