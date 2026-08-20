import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/server_config.dart';

/// Thin wrapper around flutter_v2ray. Two important notes:
///
/// 1. This plugin bundles real Xray-core (not old v2ray-core) — but ONLY
///    a recent version supports REALITY / xhttp. Run
///    `flutter pub upgrade flutter_v2ray` before building, or reality
///    servers will simply fail to connect with no useful error.
///
/// 2. Servers coming from the panel as plain share-links (vless://, ss://,
///    ...) are turned into a full Xray config via the plugin's own
///    `parseFromURL` — this is far more reliable than hand-building the
///    JSON ourselves, since the plugin authors keep it in sync with
///    Xray's actual schema.
class VpnService {
  static FlutterV2ray? _instance;
  static void Function(V2RayStatus status)? onStatusChanged;

  static Future<void> init() async {
    _instance = FlutterV2ray(onStatusChanged: (status) => onStatusChanged?.call(status));
    await _instance!.initializeV2Ray();
  }

  static Future<bool> requestPermission() async => await _instance!.requestPermission();

  /// Resolves whatever format the server came in (raw share-link URI, or an
  /// already-complete JSON config) into (remark, fullConfigJson).
  static ({String remark, String config}) _resolve(ServerConfig s) {
    if (s.isUri) {
      final parser = FlutterV2ray.parseFromURL(s.rawConfig);
      return (remark: parser.remark.isNotEmpty ? parser.remark : s.name, config: parser.getFullConfiguration());
    }
    return (remark: s.name, config: s.rawConfig);
  }

  static Future<void> connect(ServerConfig server) async {
    final resolved = _resolve(server);
    await _instance!.startV2Ray(
      remark: resolved.remark,
      config: resolved.config,
      proxyOnly: false,
      bypassSubnets: null,
      // If your installed flutter_v2ray version supports it, this labels
      // the disconnect action shown in the persistent notification.
      notificationDisconnectButtonName: 'قطع اتصال',
    );
  }

  static Future<void> disconnect() async {
    try {
      await _instance?.stopV2Ray();
    } catch (_) {
      // swallow — the caller always resets UI state regardless, so a
      // failed/duplicate stop call can never leave the button stuck again.
    }
  }

  /// Real delay test through the actual protocol (not just a raw TCP
  /// connect) — this is what v2rayNG-style apps call a "real ping".
  static Future<int?> getServerDelay(ServerConfig server) async {
    try {
      final resolved = _resolve(server);
      final delay = await _instance!.getServerDelay(
        config: resolved.config,
        url: 'https://www.google.com/gen_204',
      );
      return delay;
    } catch (_) {
      return null;
    }
  }
}
