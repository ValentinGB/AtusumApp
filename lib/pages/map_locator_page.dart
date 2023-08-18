// ignore_for_file: library_prefixes
import 'dart:async';
import 'package:atusum/helpers/loader.helper.dart';
import 'package:atusum/helpers/maps.helper.dart';
import 'package:atusum/models/bus_route.dart';
import 'package:atusum/services/location.service.dart';
import 'package:atusum/services/service_locator.dart';
import 'package:atusum/services/snackbar.service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../config.dart';

class MapLocatorPage extends StatefulWidget {
  final List<BusRoute> routes;
  final LatLng predefinedLocation;
  const MapLocatorPage({Key key, this.routes, this.predefinedLocation})
      : super(key: key);

  @override
  State<MapLocatorPage> createState() => _MapLocatorPageState();
}

class _MapLocatorPageState extends State<MapLocatorPage> {
  final mapController = Completer<GoogleMapController>();
  LatLng cameraPos = Config.initialCameraPos;
  LatLng userLocation;
  bool initialSearchDone = false;
  final _icons = <String, BitmapDescriptor>{};
  StreamSubscription<LocationData> userLocationSubscription;
  final mapMarkers = <MarkerId, Marker>{};

  @override
  void initState() {
    super.initState();
    _initIcons();
    Future.delayed(Duration.zero).then((val) {
      _initUserLocation();
    });
  }

  @override
  void deactivate() {
    super.deactivate();
    userLocationSubscription.cancel();
  }

  void _initIcons() async {
    var userIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2),
      "assets/userIcon100.png",
    );

    setState(() {
      _icons["user"] = userIcon;
    });
  }

  void _initUserLocation() async {
    bool loaderUp = true;
    LoaderHelper.showLoader(context);
    var locationService = serviceLocator<LocationService>();
    if (!await locationService.init()) {
      Navigator.of(context).pop();
      serviceLocator<SnackBarService>().show(
          'Es necesario aceptar permisos de ubicación para darle sugerencias.',
          context);
      return;
    }

    userLocationSubscription = serviceLocator<LocationService>()
        .location
        .onLocationChanged
        .listen((currentLocation) {
      if (loaderUp) {
        loaderUp = false;
        Navigator.of(context).pop();
      }
      setState(() {
        userLocation =
            LatLng(currentLocation.latitude, currentLocation.longitude);
        _updateUserLocation(userLocation);
      });
    });
  }

  void _updateUserLocation(LatLng newUserLocation) {
    var newUserMarker = Marker(
      markerId: const MarkerId("userPosition"),
      position: newUserLocation,
      icon: _icons["user"],
    );

    setState(() {
      mapMarkers[newUserMarker.markerId] = newUserMarker;
      if (widget.predefinedLocation != null && !initialSearchDone) {
        initialSearchDone = true;
        _findClosestRoute();
      }
    });
  }

  void _findClosestRoute() {
    if (userLocation == null) {
      serviceLocator<SnackBarService>().show(
          'Es necesario aceptar permisos de ubicación para darle sugerencias.',
          context);
      return;
    }

    var destination = widget.predefinedLocation != null
        ? cameraPos
        : widget.predefinedLocation;
    List<BusRoute> closestRoutes = MapsHelper.findClosestRoute(
        userLocation, destination, widget.routes, context);
    if (closestRoutes == null) {
      serviceLocator<SnackBarService>()
          .show("No se encontraron rutas cercanas", context);
      return;
    }

    _showRouteSelectorDialog(closestRoutes);
  }

  _showRouteSelectorDialog(List<BusRoute> routes) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Rutas mas cercanas',
              style: TextStyle(fontSize: 14),
            ),
            // ignore: sized_box_for_whitespace
            content: Container(
              height: 400.0, // Change as per your requirement
              width: 300.0, // Change as per your requirement
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: routes.length,
                itemBuilder: (BuildContext context, int i) {
                  return Column(
                    children: [
                      _routeListTile(routes[i]),
                      const Divider(),
                    ],
                  );
                },
              ),
            ),
            actions: [
              ElevatedButton(
                style: TextButton.styleFrom(
                  primary: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancelar'),
              )
            ],
          );
        });
  }

  Container _routeListTile(BusRoute route) {
    return Container(
      color: Colors.white,
      child: ListTile(
        title: Text(
          route.name,
          style: const TextStyle(fontSize: 12),
        ),
        subtitle: Text(route.places.join(", ") + "."),
        trailing: ElevatedButton(
          child: const Text('Ver'),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context, route);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresa tu destino en el mapa'),
      ),
      body: Stack(
        children: [
          // ignore: sized_box_for_whitespace
          Container(
            height: double.infinity,
            width: double.infinity,
            child: GoogleMap(
              markers: mapMarkers.values.toSet(),
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
              onCameraMove: (CameraPosition newCameraPos) {
                setState(() {
                  cameraPos = newCameraPos.target;
                });
              },
            ),
          ),
          const Align(
            alignment: Alignment.center,
            child: Icon(
              Icons.location_on,
              size: 40,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "ok",
        child: const Icon(Icons.check),
        onPressed: _findClosestRoute,
      ),
    );
  }
}
