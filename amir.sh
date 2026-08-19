#!/bin/bash
set -e

echo "🚀 در حال آپدیت فایل‌های پروژه و ارتقای GitHub Actions به نسخه v4..."

mkdir -p lib/services lib/widgets .github/workflows

# ۱. به‌روزرسانی vpn_service.dart
cat << 'OUTER' > lib/services/vpn_service.dart
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
OUTER

# ۲. به‌روزرسانی connect_button.dart
cat << 'OUTER' > lib/widgets/connect_button.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/server_config.dart';
import '../services/vpn_service.dart';

class ConnectButton extends StatefulWidget {
  final ServerConfig? selectedServer;

  const ConnectButton({Key? key, required this.selectedServer}) : super(key: key);

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton> {
  V2RayStatus _status = V2RayStatus();
  StreamSubscription<V2RayStatus>? _subscription;

  @override
  void initState() {
    super.initState();
    VpnService.init();
    _subscription = VpnService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  bool get _isConnected => _status.state == 'CONNECTED';
  bool get _isConnecting => _status.state == 'CONNECTING';

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _isConnected
            ? Colors.red
            : (_isConnecting ? Colors.orange : Colors.green),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      onPressed: _isConnecting
          ? null
          : () async {
              if (_isConnected) {
                await VpnService.disconnect();
              } else {
                if (widget.selectedServer != null) {
                  await VpnService.connect(widget.selectedServer!);
                }
              }
            },
      child: Text(
        _isConnected
            ? 'قطع اتصال'
            : (_isConnecting ? 'در حال اتصال...' : 'اتصال'),
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
OUTER

# ۳. بازنویسی کامل فایل Workflow با نسخه‌های v4 (جلوگیری از خطای Deprecated)
cat << 'OUTER' > .github/workflows/build.yml
name: Build Android APK

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'
          channel: 'stable'
          cache: true

      - name: Install Dependencies
        run: flutter pub get

      - name: Build APK
        run: flutter build apk --release

      - name: Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
OUTER

echo "🎉 فایل‌ها با موفقیت آپدیت شدند!"
