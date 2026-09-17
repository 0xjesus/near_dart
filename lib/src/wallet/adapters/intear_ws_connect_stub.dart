import 'package:web_socket_channel/web_socket_channel.dart';

/// Default Intear bridge socket (web / fallback).
WebSocketChannel connectIntearWebSocket(Uri uri) =>
    WebSocketChannel.connect(uri);
