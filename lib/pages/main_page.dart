import 'dart:async';

import 'package:atusum/config.dart';
import 'package:atusum/helpers/loader.helper.dart';
import 'package:atusum/pages/map_locator_page.dart';
import 'package:atusum/pages/map_page.dart';
import 'package:atusum/services/busRoute.service.dart';
import 'package:atusum/services/location.service.dart';
import 'package:atusum/services/places.service.dart';
import 'package:atusum/services/publicity.service.dart';
import 'package:atusum/services/service_locator.dart';
import 'package:atusum/services/snackbar.service.dart';
import 'package:flutter/material.dart';
import 'package:atusum/models/bus_route.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:location/location.dart';

import 'reports_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<BusRoute> availableRoutes = [];
  List<BusRoute> _filteredResults = [];
  BusRouteService routeService = serviceLocator<BusRouteService>();
  StreamSubscription<LocationData> userLocationSubscription;
  LatLng userLocation;

  @override
  void initState() {
    super.initState();
    _initUserLocation();

    Future.delayed(Duration.zero, () {
      _getRoutes();
    });
  }

  @override
  void deactivate() {
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
      setState(() {
        userLocation =
            LatLng(currentLocation.latitude, currentLocation.longitude);
      });
    });
  }

  Future<void> _getRoutes() async {
    LoaderHelper.showLoader(context);
    List<BusRoute> routes = await routeService.getActiveRoutes();
    setState(() {
      availableRoutes = routes;
      _filteredResults = routes;
    });
    Navigator.of(context).pop();
  }

  void _searchPlace(String description) async {
    List<BusRoute> matchingPlaces = [];

    if (description.trim().length >= 3) {
      AutocompleteResponse apiResponse = await serviceLocator<PlacesService>()
          .searchPlace(description, userLocation);
      if (apiResponse != null && apiResponse.predictions.isNotEmpty) {
        for (var p in apiResponse.predictions) {
          matchingPlaces.add(BusRoute(
            active: true,
            id: p.placeId,
            name: p.description,
            places: [],
            isGooglePlace: true,
          ));
        }
      }
    }
    setState(() {
      _filteredResults = matchingPlaces;
    });
  }

  List<BusRoute> _searchRouteByDescription(String description) {
    if (description.isEmpty) {
      return availableRoutes;
    } else {
      return availableRoutes.where((r) {
        List<String> routePlaces = [r.name, ...r.places];
        for (var place in routePlaces) {
          if (place.toLowerCase().contains(description.toLowerCase())) {
            return true;
          }
        }
        return false;
      }).toList();
    }
  }

  void _viewRoute(BusRoute route) async {
    await serviceLocator<PublicityService>()
        .showPublicityForRoute(route, context);

    FocusManager.instance.primaryFocus.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(selectedRoute: route),
      ),
    );
  }

  void _setLocationOnMap(LatLng predefinedLocation) async {
    if (availableRoutes == null || availableRoutes.isEmpty) {
      serviceLocator<SnackBarService>().show("Opción no disponible", context);
      return;
    }

    FocusManager.instance.primaryFocus.unfocus();
    var result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocatorPage(
            routes: availableRoutes, predefinedLocation: predefinedLocation),
      ),
    );
    if (result != null && result is BusRoute) _viewRoute(result);
  }

  void _makeReport() async {
    FocusManager.instance.primaryFocus.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          topTitle(),
          searchBar(),
          reportBar(),
          locateOnMapBar(),
          (MediaQuery.of(context).viewInsets.bottom == 0)
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 30, 10),
                  child: Text(
                    'Rutas Disponibles',
                    style: TextStyle(
                      color: ColorPalette.secondaryText,
                      fontSize: 16,
                    ),
                  ),
                )
              : Container(),
          resultsList()
        ],
      ),
    );
  }

  Expanded resultsList() {
    List<BusRoute> listToPrint;
    if (MediaQuery.of(context).viewInsets.bottom == 0) {
      listToPrint = availableRoutes;
    } else {
      listToPrint = _filteredResults;
    }

    return Expanded(
      child: Container(
        color: ColorPalette.background,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 0),
          itemCount: listToPrint.length,
          itemBuilder: (ctx, i) => Padding(
            padding: const EdgeInsets.only(top: 8),
            key: ValueKey(listToPrint[i].name),
            child: routeListTile(listToPrint[i]),
          ),
        ),
      ),
    );
  }

  Container reportBar() {
    if (MediaQuery.of(context).viewInsets.bottom == 0) {
      return Container(
        color: ColorPalette.background,
        child: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Container(
            color: Colors.white,
            child: ListTile(
              tileColor: Colors.grey,
              title: const Text(
                'Tuviste algún problema?',
                style:
                    TextStyle(color: ColorPalette.secondaryText, fontSize: 14),
              ),
              subtitle: const Text(
                'Haz un reporte',
                style: TextStyle(fontSize: 14, color: ColorPalette.primaryText),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: ColorPalette.danger),
                child: const Icon(
                  Icons.report,
                  color: Colors.white,
                ),
                onPressed: () {
                  _makeReport();
                },
              ),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Container locateOnMapBar() {
    if (MediaQuery.of(context).viewInsets.bottom != 0) {
      return Container(
        color: ColorPalette.background,
        child: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Container(
            color: Colors.white,
            child: ListTile(
              tileColor: Colors.grey,
              title: const Text(
                'No sabes cual es tu ruta?',
                style: TextStyle(
                  color: ColorPalette.secondaryText,
                ),
              ),
              subtitle: const Text(
                'Ingresa la ubicación en el mapa',
                style: TextStyle(
                  fontSize: 18,
                  color: ColorPalette.primaryText,
                ),
              ),
              trailing: ElevatedButton(
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                ),
                style: ElevatedButton.styleFrom(primary: Colors.grey),
                onPressed: () {
                  _setLocationOnMap(null);
                },
              ),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Container routeListTile(BusRoute route) {
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
          style: ElevatedButton.styleFrom(primary: Colors.grey),
          onPressed: () => viewTileClick(route),
        ),
      ),
    );
  }

  void viewTileClick(BusRoute route) async {
    if (route.isGooglePlace) {
      LoaderHelper.showLoader(context);
      var placeLocation =
          await serviceLocator<PlacesService>().getPlaceLatLng(route.id);
      Navigator.of(context).pop();
      if (placeLocation == null) {
        serviceLocator<SnackBarService>().show(
            'Ocurrio un error al buscar rutas hacia este lugar.', context);
        return;
      }
      _setLocationOnMap(placeLocation);
    } else {
      _viewRoute(route);
    }
  }

  Container topTitle() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double topTitleHeight =
        MediaQuery.of(context).size.height > 800 ? 230 : 200;

    if (MediaQuery.of(context).viewInsets.bottom == 0) {
      return Container(
        width: screenWidth,
        height: topTitleHeight,
        padding: EdgeInsets.fromLTRB(10, topTitleHeight / 4, 10, 0),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/sideBus-flipped.png"),
            scale: 2.5,
            alignment: Alignment.bottomRight,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorPalette.primaryBase,
              ColorPalette.primaryBaseDark,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Encuentra tu autobus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              'Con la App ATUSUM localiza tu autobus y espera desde un lugar comodo!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      );
    } else {
      // ignore: avoid_unnecessary_containers
      return Container(child: SizedBox(height: statusBarHeight));
    }
  }

  Padding searchBar() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        style: const TextStyle(fontSize: 22, color: Colors.black),
        decoration: const InputDecoration(
          suffixIcon: Icon(
            Icons.search,
            size: 44,
            color: ColorPalette.primaryText,
          ),
          fillColor: ColorPalette.background,
          filled: true,
          labelText: 'Hacia donde vas?',
          labelStyle: TextStyle(
            color: ColorPalette.primaryText,
            fontSize: 14,
          ),
        ),
        onChanged: (value) {
          _searchPlace(value);
          // setState(() {
          //   _filteredResults = _searchRouteByDescription(value);
          // });
        },
      ),
    );
  }
}
