<<<<<<< HEAD
/// A single connectable server parsed out of the panel's Xray-format
/// subscription. [rawConfigJson] is the full per-server JSON object exactly
/// as the panel sent it — this is what gets handed to the V2Ray core to
/// actually connect. It is NEVER rendered anywhere in the UI.
=======
/// A single connectable server. The panel has been observed returning TWO
/// different subscription formats depending on the token/account — a JSON
/// array of full Xray configs, and a plain newline-separated list of share
/// links (vless://, ss://, ...). Both are supported; [isUri] tells the rest
/// of the app which one this entry came from.
>>>>>>> ce5dae0 (OneSpeed v1)
class ServerConfig {
  final String name;
  final String? flagCode; // ISO 3166-1 alpha-2, lowercase, or null
  final String address;
  final int port;
<<<<<<< HEAD
  final String rawConfigJson;
  double? pingMs;
=======
  final String rawConfig;   // full JSON string OR a single share-link URI
  final bool isUri;
  double? pingMs;
  bool pinging = false;
>>>>>>> ce5dae0 (OneSpeed v1)

  ServerConfig({
    required this.name,
    required this.flagCode,
    required this.address,
    required this.port,
<<<<<<< HEAD
    required this.rawConfigJson,
=======
    required this.rawConfig,
    required this.isUri,
>>>>>>> ce5dae0 (OneSpeed v1)
    this.pingMs,
  });
}

/// The metadata entry the panel encodes as a fake "server" (port == 1):
/// remaining days / volume / expiry date.
class PlanInfo {
  final String? daysText;
  final String? volumeText;
  final String? expiryDate;
  final String planName;

  const PlanInfo({
    this.daysText,
    this.volumeText,
    this.expiryDate,
    this.planName = 'OneSpeed',
  });
}
