/// A single connectable server. The panel has been observed returning TWO
/// different subscription formats depending on the token/account — a JSON
/// array of full Xray configs, and a plain newline-separated list of share
/// links (vless://, ss://, ...). Both are supported; [isUri] tells the rest
/// of the app which one this entry came from.
class ServerConfig {
  final String name;
  final String? flagCode; // ISO 3166-1 alpha-2, lowercase, or null
  final String address;
  final int port;
  final String rawConfig;   // full JSON string OR a single share-link URI
  final bool isUri;
  double? pingMs;
  bool pinging = false;

  ServerConfig({
    required this.name,
    required this.flagCode,
    required this.address,
    required this.port,
    required this.rawConfig,
    required this.isUri,
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
