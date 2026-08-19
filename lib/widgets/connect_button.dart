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
