import 'dart:async';
import 'dart:io';

import 'package:atusum/services/service_locator.dart';
import 'package:atusum/services/snackbar.service.dart';

import '../config.dart';

class ExceptionHelper {
  static void handleException(ex) {
    if (ex is SocketException) {
      serviceLocator<SnackBarService>()
          .show("Sin conexión", Globals.key.currentContext);
    } else if (ex is TimeoutException) {
      serviceLocator<SnackBarService>()
          .show("Servidor no responde", Globals.key.currentContext);
    }
  }
}
