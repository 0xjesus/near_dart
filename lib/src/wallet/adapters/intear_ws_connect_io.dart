import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// VM Intear bridge socket. Protocol pings keep Android from dropping the
/// socket while the wallet app is in the foreground.
WebSocketChannel connectIntearWebSocket(Uri uri) =>
    IOWebSocketChannel.connect(uri, pingInterval: const Duration(seconds: 20));
