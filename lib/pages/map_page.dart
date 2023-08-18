// ignore_for_file: library_prefixes
import 'dart:async';
import 'package:atusum/helpers/maps.helper.dart';
import 'package:atusum/models/bus.dart';
import 'package:atusum/models/bus_location_data.dart';
import 'package:atusum/models/bus_route.dart';
import 'package:atusum/services/bus.service.dart';
import 'package:atusum/services/location.service.dart';
import 'package:atusum/services/service_locator.dart';
import 'package:atusum/services/snackbar.service.dart';
import 'package:atusum/services/socket.service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animarker/widgets/animarker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config.dart';

class MapPage extends StatefulWidget {
  final BusRoute selectedRoute;
  final bool locateOnMap;
  const MapPage({Key key, this.selectedRoute, this.locateOnMap})
      : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final mapController = Completer<GoogleMapController>();
  BusRoute selectedRoute;
  BusLocationData selectedBus;
  List<Bus> activeBuses = [];
  Map<String, BusLocationData> busesData = <String, BusLocationData>{};
  final Set<Polyline> _routePolylines = {};
  final mapMarkers = <MarkerId, Marker>{};
  final _icons = <String, BitmapDescriptor>{};
  final IO.Socket _socket = serviceLocator<SocketService>().getSocket();
  final _busService = serviceLocator<BusService>();
  StreamSubscription<LocationData> userLocationSubscription;
  LatLng userLastPos;

  @override
  void initState() {
    super.initState();
    _initUserLocation();
    _initIcons();
    _initRoute();
    _initSocket();
  }

  @override
  void deactivate() {
    _socket.emit('quitRoom', {'room': 'all'});
    _socket.clearListeners();
    userLocationSubscription.cancel();
    super.deactivate();
  }

  void _initUserLocation() async {
    var locationService = serviceLocator<LocationService>();
    if (!await locationService.init()) {
      serviceLocator<SnackBarService>().show(
          'Es necesario aceptar permisos de ubicación para darle sugerencias.',
          context);
      return;
    }

    userLocationSubscription = serviceLocator<LocationService>()
        .location
        .onLocationChanged
        .listen((currentLocation) {
      _updateUserLocation(
          LatLng(currentLocation.latitude, currentLocation.longitude));
    });
  }

  void _initRoute() async {
    selectedRoute = widget.selectedRoute;
    if (selectedRoute == null || selectedRoute.wayPoints.isEmpty) return;

    _routePolylines.add(Polyline(
      polylineId: PolylineId(selectedRoute.id),
      points: selectedRoute.wayPoints,
      visible: true,
      width: 5,
      color: ColorPalette.primaryBase,
    ));

    await _getRouteActiveBuses(selectedRoute.id);
    _getActiveBusesLastPos(selectedRoute.id);

    mapController.future.then<void>((gController) {
      gController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: MapsHelper.getRouteCenter(selectedRoute.wayPoints),
            zoom: 14,
          ),
        ),
      );
    });
  }

  Future<void> _getActiveBusesLastPos(String routeId) async {
    List<BusLocationData> routeBusesLastPos =
        await _busService.getRouteActiveBuses(routeId);

    for (var rb in routeBusesLastPos) {
      _updateBusLocation(rb);
    }
  }

  Future<void> _getRouteActiveBuses(String routeId) async {
    List<Bus> routeBuses = await _busService.getBusesByRoute(routeId);
    setState(() {
      activeBuses = routeBuses.where((b) => b.active).toList();
    });
  }

  void _initIcons() async {
    var busIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2),
      "assets/busIcon80.png",
    );
    var userIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2),
      "assets/userIcon100.png",
    );

    setState(() {
      _icons["bus"] = busIcon;
      _icons["user"] = userIcon;
    });
  }

  void _initSocket() {
    _socket.emit('subscribeToRoute', {'routeId': selectedRoute.id});
    _socket.on('route', (jsonValue) {
      try {
        _updateBusLocation(BusLocationData.fromJson(jsonValue));
      } on Exception catch (_) {
        // ignore: avoid_print
        print(_);
      }
    });
  }

  void _updateBusLocation(BusLocationData busLocationData) {
    var busData = activeBuses.singleWhere((b) => b.id == busLocationData.busId,
        orElse: () => null);
    if (busData == null) {
      return;
    } else {
      busLocationData.bus = busData;
    }

    if (busesData[busLocationData.busId] != null) {
      busLocationData.ticksWithoutMovement = busesData[busLocationData.busId]
          .ticksWithoutMovement; //get no without movement counter
      busLocationData.timesOutOfRoute = busesData[busLocationData.busId]
          .timesOutOfRoute; //get out of route counter

      busLocationData.previousPosition =
          busesData[busLocationData.busId].position;

      //check if bus moved
      busLocationData.ticksWithoutMovement = (MapsHelper.calculateDistance(
                  busLocationData.position, busLocationData.previousPosition) >
              0.01)
          ? 0 //bus moved
          : busLocationData.ticksWithoutMovement + 1; //bus didn't move
    }

    //check if its inside the route
    busLocationData.isInsideRoute = MapsHelper.isInsideRoute(
        busLocationData.position, selectedRoute.wayPoints);
    busLocationData.timesOutOfRoute =
        busLocationData.isInsideRoute ? 0 : busLocationData.timesOutOfRoute + 1;

    //calculate bus distance to the user position trough the route
    if (userLastPos != null) {
      busLocationData.busDistanceToUser = MapsHelper.busDistanceToUserLocation(
          userLocation: userLastPos,
          bus: busLocationData,
          routeWayPoints: selectedRoute.wayPoints);

      // if (busLocationData.speed > 5 &&
      //     busLocationData.busDistanceToUser < 9999) {
      //   busLocationData.timeToArrive =
      //       busLocationData.busDistanceToUser / busLocationData.speed * 60;
      // } else if (busesData[busLocationData.busId] != null) {
      //   busLocationData.timeToArrive =
      //       busesData[busLocationData.busId].timeToArrive;
      // } else {
      //   busLocationData.timeToArrive = null;
      // }
      //fixed as 6 minutes per km
      if (busLocationData.busDistanceToUser == null ||
          busLocationData.busDistanceToUser > 30) {
        busLocationData.timeToArrive = null;
      } else {
        busLocationData.timeToArrive = busLocationData.busDistanceToUser * 6;
      }
    }

    var busMarkerId = MarkerId(busLocationData.busId);
    // if the bus has never been inside the route will not show
    if (mapMarkers[busMarkerId] == null && !busLocationData.isInsideRoute) {
      return;
    }
    setState(() {
      //if the new data is from the selected bus then 'selectedBus' value is updated
      if (selectedBus != null && busLocationData.busId == selectedBus.busId) {
        selectedBus = busLocationData;
      }
      busesData[busLocationData.busId] = busLocationData;

      try {
        mapMarkers[busMarkerId] = Marker(
          markerId: busMarkerId,
          position: busLocationData.position,
          icon: _icons["bus"],
          // infoWindow: InfoWindow(title: "Autobus #" + busLocationData.bus.number),
          onTap: () {
            setState(() {
              selectedBus = busesData[busLocationData.busId];
            });
          },
          visible: (busLocationData.timesOutOfRoute <= 30 &&
              busLocationData.ticksWithoutMovement <= 30),
        );
      } on Exception catch (ex) {
        // ignore: avoid_print
        print(ex);
      }
    });
  }

  void _updateUserLocation(LatLng newUserLocation) {
    var newUserMarker = Marker(
      markerId: const MarkerId("userPosition"),
      position: newUserLocation,
      infoWindow: const InfoWindow(title: "Tu ubicación actual"),
      icon: _icons["user"],
    );

    LatLng nearestPoint =
        MapsHelper.getNearestPoint(newUserLocation, selectedRoute.wayPoints);

    var nearestPointMarker = Marker(
      markerId: const MarkerId("nearestPoint"),
      position: nearestPoint,
      infoWindow: const InfoWindow(title: "Punto mas cercano a la ruta"),
      icon: BitmapDescriptor.defaultMarker,
    );

    setState(() {
      userLastPos = newUserLocation;
      mapMarkers[nearestPointMarker.markerId] = nearestPointMarker;
      mapMarkers[newUserMarker.markerId] = newUserMarker;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Animarker(
            mapId: mapController.future.then<int>((value) => value.mapId),
            useRotation: false,
            shouldAnimateCamera: false,
            duration: const Duration(milliseconds: 2000),
            markers: mapMarkers.values.toSet(),
            child: GoogleMap(
              polylines: _routePolylines,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              initialCameraPosition: const CameraPosition(
                target: Config.initialCameraPos,
                zoom: 14,
              ),
              onMapCreated: (gController) {
                mapController.complete(gController);
              },
            ),
          ),
          bottomSheet(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        onPressed: () {
          Navigator.pop(context);
        },
        tooltip: 'Reportar Incidente',
        child: const Icon(Icons.arrow_back),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }

  DraggableScrollableSheet bottomSheet() {
    double screenHeight = MediaQuery.of(context).size.height;
    return DraggableScrollableSheet(
      initialChildSize: 0.20,
      expand: true,
      maxChildSize: 0.75,
      minChildSize: 0.2,
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Container(
            color: const Color.fromRGBO(230, 230, 230, 1),
            height: screenHeight * 0.75,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: const Center(
                    child: Icon(Icons.drag_handle),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: routeDataTile(selectedRoute),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: busDataTile(selectedBus),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Container routeDataTile(BusRoute route) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: const Icon(
          Icons.directions,
          size: 45,
          color: Colors.orange,
        ),
        minLeadingWidth: 55,
        title: Text(route.name),
        subtitle: Text(route.places.join(", ") + "."),
      ),
    );
  }

  Container busDataTile(BusLocationData busData) {
    if (busData == null) {
      return Container(
        height: 75,
        color: Colors.white,
        child: const ListTile(
          leading: Image(image: AssetImage("assets/busIcon.png")),
          title: Text('Seleccione un Autobus'),
          subtitle: Text('Seleccione un autobus para ver la ayuda.'),
        ),
      );
    } else {
      String description = 'Calculando tiempo de llegada del autobus...';
      if (!busData.isInsideRoute) {
        description = 'Autobus fuera de ruta';
      } else if (busData.ticksWithoutMovement >= 5) {
        description = 'Este autobus no se esta moviendo';
      } else if (busData.timeToArrive != null) {
        description =
            'Este autobus pasara por el punto marcado en la ruta en aproximadamente ${busData.timeToArrive.toStringAsFixed(0)} minutos.';
      }

      return Container(
        color: Colors.white,
        child: ListTile(
          leading: const Image(image: AssetImage("assets/busIcon.png")),
          // title: Text('Autobus #' + busData.bus.number),
          subtitle: Text(description),
        ),
      );
    }
  }
}
