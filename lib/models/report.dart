import 'dart:io';

import 'bus.dart';
import 'bus_route.dart';

class Report {
  String title;
  String ticketNumber;
  String busId;
  Bus bus;
  String description;
  String phoneId;
  String imgName;
  DateTime date;
  String contactPhoneNumber;
  String routeId;
  BusRoute route;
  ReportResponse response;
  File pickedImage;
  Report({
    this.title,
    this.bus,
    this.description,
    this.phoneId,
    this.imgName,
    this.date,
    this.route,
  });

  Report.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    description = json['description'];
    phoneId = json['phoneId'];
    imgName = json['imgName'];
    date = DateTime.parse(json['date']).toLocal();

    if (json['bus'] != null) {
      bus = Bus.fromJson(json['bus']);
    }

    if (json['bus'] != null && json['bus'] is Map<String, dynamic>) {
      bus = Bus.fromJson(json['bus']);
    } else if (json['route'] != null && json['bus'] is String) {
      bus = Bus(id: json['bus']);
    }

    if (json['route'] != null && json['route'] is Map<String, dynamic>) {
      route = BusRoute.fromJson(json['route']);
    } else if (json['route'] != null && json['route'] is String) {
      route = BusRoute(id: json['route']);
    }

    if (json['response'] != null) {
      response = ReportResponse.fromJson(json['response']);
    }
  }
}

class ReportResponse {
  String text;
  DateTime date;
  ReportResponse({
    this.text,
    this.date,
  });
  ReportResponse.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    date = DateTime.parse(json['date']);
  }
}
