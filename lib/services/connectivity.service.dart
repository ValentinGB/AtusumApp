import 'package:connectivity/connectivity.dart';

class ConnectivityService {
  isConnected() async {
    ConnectivityResult connectivityResult =
        await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }
}
