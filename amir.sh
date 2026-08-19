#!/bin/bash
set -e

echo "🚀 در حال اعمال تغییرات جامع و رفع کلیه مشکلات پروژه..."

mkdir -p lib/services lib/widgets lib/screens .github/workflows

# ۱. بازنویسی کامل lib/services/vpn_service.dart با مدیریت کامل Xray، پینگ و ریست وضعیت
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
    
    // ریست کامل وضعیت UI پس از قطع اتصال
    final resetStatus = V2RayStatus();
    currentStatus = resetStatus;
    onStatusChanged?.call(resetStatus);
    _statusController.add(resetStatus);
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

# ۲. ایجاد ویجت انتخاب سرور همراه با دکمه تست پینگ دستی (lib/widgets/server_selector_sheet.dart)
cat << 'OUTER' > lib/widgets/server_selector_sheet.dart
import 'package:flutter/material.dart';
import '../models/server_config.dart';
import '../services/vpn_service.dart';

class ServerSelectorSheet extends StatefulWidget {
  final List<ServerConfig> servers;
  final ServerConfig? selectedServer;
  final Function(ServerConfig) onSelect;

  const ServerSelectorSheet({
    Key? key,
    required this.servers,
    required this.selectedServer,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<ServerSelectorSheet> createState() => _ServerSelectorSheetState();
}

class _ServerSelectorSheetState extends State<ServerSelectorSheet> {
  bool _isPingingAll = false;

  Future<void> _pingAllServers() async {
    setState(() => _isPingingAll = true);
    for (var server in widget.servers) {
      if (server.port == 1) continue;
      final delay = await VpnService.getDelay(server);
      if (mounted) {
        setState(() {
          server.pingMs = delay > 0 ? delay.toDouble() : -1;
        });
      }
    }
    if (mounted) {
      setState(() => _isPingingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'انتخاب سرور / لوکیشن',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _isPingingAll ? null : _pingAllServers,
                icon: _isPingingAll
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.speed, size: 18),
                label: Text(_isPingingAll ? 'در حال تست...' : 'بررسی پینگ'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: widget.servers.length,
              itemBuilder: (context, index) {
                final server = widget.servers[index];
                if (server.port == 1) return const SizedBox.shrink();

                final isSelected = widget.selectedServer?.address == server.address &&
                    widget.selectedServer?.port == server.port;

                return ListTile(
                  leading: Icon(
                    Icons.dns,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  title: Text(server.name),
                  subtitle: Text('${server.address}:${server.port}'),
                  trailing: Text(
                    server.pingMs == null
                        ? '-- ms'
                        : (server.pingMs! < 0 ? 'خطا' : '${server.pingMs!.toInt()} ms'),
                    style: TextStyle(
                      color: server.pingMs == null || server.pingMs! < 0
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    widget.onSelect(server);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
OUTER

# ۳. اصلاح فراخوانی پینگ در dashboard_screen در صورت وجود
if [ -f "lib/screens/dashboard_screen.dart" ]; then
  sed -i 's/await pingServer(s.address, s.port)/await VpnService.getDelay(s)/g' lib/screens/dashboard_screen.dart
fi

# ۴. تنظیم دقیق فایل GitHub Actions Workflow (.github/workflows/build.yml) با نسخه v4
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

echo "🎉 تمام اصلاحات با موفقیت اعمال شدند!"
