import 'package:atusum/services/busRoute.service.dart';
import 'package:atusum/services/connectivity.service.dart';
import 'package:atusum/services/location.service.dart';
import 'package:atusum/services/places.service.dart';
import 'package:atusum/services/publicity.service.dart';
import 'package:atusum/services/report.service.dart';
import 'package:atusum/services/snackbar.service.dart';
import 'package:atusum/services/socket.service.dart';
import 'package:get_it/get_it.dart';

import 'bus.service.dart';

GetIt serviceLocator = GetIt.instance;

setupServiceLocator() {
  serviceLocator.registerLazySingleton<BusService>(() => BusService());
  serviceLocator
      .registerLazySingleton<BusRouteService>(() => BusRouteService());
  serviceLocator.registerLazySingleton<SocketService>(() => SocketService());
  serviceLocator
      .registerLazySingleton<LocationService>(() => LocationService());
  serviceLocator
      .registerLazySingleton<SnackBarService>(() => SnackBarService());
  serviceLocator
      .registerLazySingleton<PublicityService>(() => PublicityService());
  serviceLocator.registerLazySingleton<ReportService>(() => ReportService());
  serviceLocator
      .registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  serviceLocator.registerLazySingleton<PlacesService>(() => PlacesService());
}
