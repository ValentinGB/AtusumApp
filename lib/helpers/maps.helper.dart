import 'dart:math' as math;
import 'package:atusum/models/bus_location_data.dart';
import 'package:atusum/models/bus_route.dart';
import 'package:atusum/services/service_locator.dart';
import 'package:atusum/services/snackbar.service.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config.dart';

class MapsHelper {
  static LatLng getRouteCenter(List<LatLng> wayPoints) {
    double biggestDistance = 0;
    LatLng routeCenter = Config.initialCameraPos;
    if (wayPoints.isEmpty) return routeCenter;

    for (var i = 0; i < wayPoints.length; i++) {
      for (var j = 0; j < wayPoints.length; j++) {
        double newDistance = calculateDistance(wayPoints[i], wayPoints[j]);
        if (newDistance > biggestDistance) {
          biggestDistance = newDistance;
          routeCenter = LatLng(
            (wayPoints[i].latitude + wayPoints[j].latitude) / 2,
            (wayPoints[i].longitude + wayPoints[j].longitude) / 2,
          );
        }
      }
    }
    return routeCenter;
  }

  static double getRouteLength(List<LatLng> routeWayPoints) {
    double routeLength = 0;
    for (var i = 0; i < routeWayPoints.length; i++) {
      routeLength += calculateDistance(routeWayPoints[i],
          routeWayPoints[(i < routeWayPoints.length) ? i + 1 : 0]);
    }
    return routeLength;
  }

  static double calculateDistance(LatLng a, LatLng b) {
    int R = 6371; // km
    double dLat = toRad(b.latitude - a.latitude);
    double dLon = toRad(b.longitude - a.longitude);

    double _a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(a.latitude)) *
            math.cos(toRad(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    var c = 2 * math.atan2(math.sqrt(_a), math.sqrt(1 - _a));
    return R * c;
  }

  static double toRad(double value) {
    return value * math.pi / 180;
  }

  static List<BusRoute> findClosestRoute(LatLng userPos, LatLng destination,
      List<BusRoute> allRoutes, BuildContext context) {
    //validate if inside the city
    if (calculateDistance(userPos, Config.initialCameraPos) > 5.5) {
      serviceLocator<SnackBarService>()
          .show('Ingrese una ubicación dentro de la ciudad', context);
      return null;
    }

    List<RouteDistance> routesWithDistance = [];
    for (BusRoute route in allRoutes) {
      LatLng nearestPointFromUserToRoute =
          getNearestPoint(userPos, route.wayPoints);
      LatLng nearestPointFromRouteToDestination =
          getNearestPoint(destination, route.wayPoints);

      if (nearestPointFromUserToRoute == null ||
          nearestPointFromRouteToDestination == null) continue;

      routesWithDistance.add(
        RouteDistance(
          route: route,
          fromUserToRoute:
              calculateDistance(userPos, nearestPointFromUserToRoute),
          fromRouteToPoint: calculateDistance(
              destination, nearestPointFromRouteToDestination),
        ),
      );
    }

    routesWithDistance =
        routesWithDistance.where((r) => r.fromRouteToPoint <= 0.3).toList();

    routesWithDistance.sort((a, b) =>
        (a.fromRouteToPoint /* + a.fromUserToRoute*/)
            .compareTo(b.fromRouteToPoint /* + b.fromUserToRoute*/));

    if (routesWithDistance.length <= 3) {
      return routesWithDistance.map((r) => r.route).toList();
    } else {
      return routesWithDistance.sublist(0, 3).map((r) => r.route).toList();
    }
  }

  static LatLng getNearestPoint(LatLng a, List<LatLng> routeWayPoints) {
    LatLng nearestPoint;
    double nearestDistance = 999999;
    for (var i = 0; i < routeWayPoints.length; i++) {
      LatLng wpA = routeWayPoints[i];
      LatLng wpB = (i == routeWayPoints.length - 1)
          ? routeWayPoints[0]
          : routeWayPoints[i + 1];

      if (calculateDistance(wpA, wpB) < 0.011) {
        //if the distance is less than 11 meters there is no need to create virtual waypoints
        double newDistance = calculateDistance(a, wpA);
        if (newDistance < nearestDistance) {
          nearestDistance = newDistance;
          nearestPoint = wpA;
        }
      } else {
        List<LatLng> virtualWayPoints = getWayPointsFromAToB(wpA, wpB);
        for (var j = 0; j < virtualWayPoints.length; j++) {
          double newDistance = calculateDistance(a, virtualWayPoints[j]);
          if (newDistance < nearestDistance) {
            nearestDistance = newDistance;
            nearestPoint = virtualWayPoints[j];
          }
        }
      }
    }

    return nearestPoint;
  }

  static List<LatLng> getWayPointsFromAToB(LatLng a, LatLng b) {
    double distance = calculateDistance(a, b);
    double latDistance = a.latitude - b.latitude;
    double lngDistance = a.longitude - b.longitude;
    int totalPoints = (distance * 1000 / 10).floor();

    List<LatLng> virtualWayPoints = [];

    virtualWayPoints.add(a);
    for (var i = 1; i <= totalPoints; i++) {
      virtualWayPoints.add(LatLng(
          a.latitude - ((latDistance / totalPoints) * i),
          a.longitude - ((lngDistance / totalPoints) * i)));
    }

    if (virtualWayPoints.length > 1) virtualWayPoints.removeLast();
    virtualWayPoints.add(b);
    return virtualWayPoints;
  }

  static double getAngle(LatLng a, LatLng b) {
    double lngDiff = b.longitude - a.longitude;
    double latDiff = b.latitude - a.latitude;
    double theta = math.atan2(lngDiff, latDiff);
    theta *= 180 / math.pi;
    if (theta < 0) theta = 360 + theta;

    return theta;
  }

  static bool isInsideRoute(LatLng location, List<LatLng> routeWayPoints) {
    LatLng nearestPoint = getNearestPoint(location, routeWayPoints);

    return calculateDistance(location, nearestPoint) < 0.2;
  }

  static double busDistanceToUserLocation(
      {LatLng userLocation, BusLocationData bus, List<LatLng> routeWayPoints}) {
    if (!isInsideRoute(bus.position, routeWayPoints)) return 9999;

    LatLng nearestPointToRoute = getNearestPoint(userLocation, routeWayPoints);
    double distance = 0;

    bool foundBus = false;
    int i = 0;

    //first searches the bus inside the route and then starts
    //calculating the distance from the bus position to the "me" position traveling through the route
    while (i < routeWayPoints.length * 2) {
      LatLng a = routeWayPoints[i];
      i++;
      if (i >= routeWayPoints.length) i = 0;
      LatLng b = routeWayPoints[i];

      double angleFromAToB = getAngle(a, b);
      List<LatLng> virtualWayPoints = getWayPointsFromAToB(a, b);

      if (!foundBus) {
        //bus has not been found

        if (bus.angle != null &&
            ((angleFromAToB - bus.angle).abs() - 180).abs() > 45) {
          //not going in the same direction
          continue;
        }
        if (!isInsideRoute(bus.position, virtualWayPoints)) {
          continue;
        }
        if (isInsideRoute(nearestPointToRoute, virtualWayPoints)) {
          return calculateDistance(bus.position, nearestPointToRoute);
        } else {
          foundBus = true;
          distance += calculateDistance(bus.position, b);
          continue;
        }
      } else {
        //bus was already found
        if (!isInsideRoute(nearestPointToRoute, virtualWayPoints)) {
          distance += calculateDistance(a, b);
          continue;
        } else {
          distance += calculateDistance(a, nearestPointToRoute);
          return distance;
        }
      }
    }

    return 9999; //it should never come to this
  }
}
