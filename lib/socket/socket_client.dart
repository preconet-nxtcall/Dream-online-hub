import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/api_endpoints.dart';

class SocketClient {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String authToken) {
    _socket = io.io(
      ApiEndpoints.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': authToken})
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      // Socket connected
    });

    _socket?.onDisconnect((_) {
      // Socket disconnected
    });
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
