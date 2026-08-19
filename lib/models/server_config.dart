/// A single connectable server parsed out of the panel's Xray-format
/// subscription. [rawConfigJson] is the full per-server JSON object exactly
/// as the panel sent it — this is what gets handed to the V2Ray core to
/// actually connect. It is NEVER rendered anywhere in the UI.
class ServerConfig {
  final String name;
  final String? flagCode; // ISO 3166-1 alpha-2, lowercase, or null
  final String address;
  final int port;
  final String rawConfigJson;
  double? pingMs;

  ServerConfig({
    required this.name,
    required this.flagCode,
    required this.address,
    required this.port,
    required this.rawConfigJson,
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
