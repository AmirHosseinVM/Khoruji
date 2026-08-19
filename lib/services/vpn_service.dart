import 'dart:async';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/server_config.dart';

class VpnService {
  static FlutterV2ray? _instance;
  static final StreamController<V2RayStatus> _statusController =
      StreamController<V2RayStatus>.broadcast();

  static Stream<V2RayStatus> get statusStream => _statusController.stream;
  static V2RayStatus currentStatus = V2RayStatus();

  static Future<void> init() async {
    if (_instance != null) return;
    _instance = FlutterV2ray(
      onStatusChanged: (status) {
        currentStatus = status;
        _statusController.add(status);
      },
    );
    await _instance!.initializeV2Ray();
  }

  static Future<bool> requestPermission() async {
    await init();
    return await _instance!.requestPermission();
  }

  static Future<void> connect(ServerConfig server) async {
    await init();
    if (server.port == 1) return;
    if (!await requestPermission()) return;

    await _instance!.startV2Ray(
      remark: server.name,
      config: server.rawConfigJson,
      proxyOnly: false,
      bypassSubnets: null,
    );
  }

  static Future<void> disconnect() async {
    if (_instance == null) return;
    await _instance!.stopV2Ray();
  }

  static Future<int> getDelay(ServerConfig server) async {
    await init();
    if (server.port == 1) return -1;
    try {
      final delay = await _instance!.getConnectedV2rayServerDelay(
        server.rawConfigJson,
        url: 'https://www.google.com/gen_204',
      );
      return delay;
    } catch (_) {
      return -1;
    }
  }
}
