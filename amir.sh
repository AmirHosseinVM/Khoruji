#!/bin/bash
set -e

echo "🚀 در حال اصلاح خطاهای کامپایل Flutter..."

mkdir -p lib/services lib/screens .github/workflows

# ۱. اصلاح lib/services/vpn_service.dart (افزودن onStatusChanged و اصلاح متد getServerDelay)
cat << 'OUTER' > lib/services/vpn_service.dart
import 'dart:async';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/server_config.dart';

class VpnService {
  static FlutterV2ray? _instance;
  static void Function(V2RayStatus status)? onStatusChanged;
  static final StreamController<V2RayStatus> _statusController =
      StreamController<V2RayStatus>.broadcast();

  static Stream<V2RayStatus> get statusStream => _statusController.stream;
  static V2RayStatus currentStatus = V2RayStatus();

  static Future<void> init() async {
    if (_instance != null) return;
    _instance = FlutterV2ray(
      onStatusChanged: (status) {
        currentStatus = status;
        onStatusChanged?.call(status);
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
      final delay = await _instance!.getServerDelay(
        config: server.rawConfigJson,
        url: 'https://www.google.com/gen_204',
      );
      return delay;
    } catch (_) {
      return -1;
    }
  }
}
OUTER

# ۲. جایگزینی فراخوانی pingServer با VpnService.getDelay در dashboard_screen.dart
if [ -f "lib/screens/dashboard_screen.dart" ]; then
  sed -i 's/await pingServer(s.address, s.port)/await VpnService.getDelay(s)/g' lib/screens/dashboard_screen.dart
fi

echo "🎉 خطاهای کامپایل با موفقیت برطرف شدند!"
