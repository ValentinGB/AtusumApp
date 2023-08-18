import 'package:atusum/models/device.dart';
import 'package:atusum/models/bus_route.dart';

class Bus {
  String id;
  String name;
  String number;
  BusRoute route;
  Device device;
  bool active;

  Bus({
    this.id,
    this.name,
    this.number,
    this.route,
    this.device,
  });

  Bus.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    active = json['active'] ?? false;
    name = json['name'];
    number = json['number'];

    if (json['route'] != null && json['route'] is Map<String, dynamic>) {
      route = BusRoute.fromJson(json['route']);
    } else if (json['route'] != null && json['route'] is String) {
      route = BusRoute();
      route.id = json['route'];
    }

    if (json['device'] != null && json['device'] is Map<String, dynamic>) {
      device = Device.fromJson(json['device']);
    } else if (json['route'] != null && json['route'] is String) {
      device = Device();
      device.id = json['device'];
    }
  }
}
