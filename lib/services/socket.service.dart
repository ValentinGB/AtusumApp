// ignore_for_file: library_prefixes

import 'package:atusum/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket _socket;

  IO.Socket getSocket() {
    if (_socket == null) _initSocket();
    return _socket;
  }

  _initSocket() {
    _socket = IO.io(Config.url, <String, dynamic>{
      'transports': ['websocket']
    });
  }
}
