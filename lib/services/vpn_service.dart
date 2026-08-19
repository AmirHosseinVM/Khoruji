import 'dart:io';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/server_config.dart';

/// Thin wrapper around flutter_v2ray so the rest of the app never talks to
/// the plugin directly. If the exact method names differ slightly from the
/// version that gets pulled in by `flutter pub get` (the plugin's API has
/// shifted between versions), this is the ONLY file that needs adjusting —
/// check `flutter pub deps` / the example on pub.dev for your resolved
/// version and fix the calls below.
class VpnService {
  static FlutterV2ray? _instance;
  static void Function(V2RayStatus status)? onStatusChanged;

  static Future<void> init() async {
    _instance = FlutterV2ray(
      onStatusChanged: (status) => onStatusChanged?.call(status),
    );
    await _instance!.initializeV2Ray();
  }

  static Future<bool> requestPermission() async {
    return await _instance!.requestPermission();
  }

  static Future<void> connect(ServerConfig server) async {
    await _instance!.startV2Ray(
      remark: server.name,
      config: server.rawConfigJson,
      proxyOnly: false,
      bypassSubnets: null,
    );
  }

  static Future<void> disconnect() async {
    await _instance!.stopV2Ray();
  }
}

/// Real TCP-level latency probe — unlike a browser (no raw sockets
/// available), Dart on Android can open an actual socket, so this is a
/// genuine measurement, not an approximation.
Future<int?> pingServer(String address, int port, {Duration timeout = const Duration(seconds: 3)}) async {
  final sw = Stopwatch()..start();
  try {
    final socket = await Socket.connect(address, port, timeout: timeout);
    sw.stop();
    socket.destroy();
    return sw.elapsedMilliseconds;
  } catch (_) {
    return null;
  }
}
