import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'device_id_service.dart';
import '../models/server_config.dart';

class ApiException implements Exception {
  final String code;
  final int? limit;
  ApiException(this.code, {this.limit});

  @override
  String toString() => 'ApiException($code${limit != null ? ', limit=$limit' : ''})';
}

class SubResult {
  final PlanInfo plan;
  final List<ServerConfig> servers;
  SubResult(this.plan, this.servers);
}

class ApiService {
  // ---------------------------------------------------------------------
  // The app talks ONLY to this — never to the real panel domain directly.
  // Change this if the gateway domain ever changes; nothing else in the
  // app needs to know about the real panel.
  // ---------------------------------------------------------------------
  static const String gatewayBase = 'https://devfull.sbs/app';

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'onespeed_token';

  static Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  static Future<String?> getSavedToken() => _storage.read(key: _tokenKey);
  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static Future<List<dynamic>> fetchRawSub(String token) async {
    final deviceId = await DeviceIdService.getDeviceId();
    final uri = Uri.parse('$gatewayBase/sub.php').replace(queryParameters: {'token': token});

    final http.Response res;
    try {
      res = await http
          .get(uri, headers: {'Accept': 'application/json', 'X-Device-Id': deviceId})
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      throw ApiException('network_error');
    }

    if (res.statusCode == 403) {
      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}
      throw ApiException('device_limit_reached', limit: body['limit'] as int?);
    }
    if (res.statusCode != 200) {
      throw ApiException('http_${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    if (data is! List) throw ApiException('bad_format');
    return data;
  }

  /// Parses the panel's Xray-format subscription. Entries with port == 1 are
  /// metadata (remaining days / volume / expiry date), never real servers —
  /// this matches exactly what we validated against the live panel output.
  static SubResult parseSub(List<dynamic> data) {
    String? daysText, volText, expiryDate;
    final servers = <ServerConfig>[];

    final flagRegex = RegExp(r'[\u{1F1E6}-\u{1F1FF}]{2}', unicode: true);
    final dayRegex = RegExp(r'روز\s*:\s*([^\|]+)');
    final volRegex = RegExp(r'حجم\s*:\s*([^\|]+)');
    final dateRegex = RegExp(r'^(\d{4}-\d{2}-\d{2})');

    for (final entry in data) {
      if (entry is! Map) continue;
      final remarks = (entry['remarks'] ?? '').toString();
      final outbounds = (entry['outbounds'] as List?) ?? const [];

      Map? proxyOut;
      for (final o in outbounds) {
        if (o is Map && o['tag'] == 'proxy') {
          proxyOut = o;
          break;
        }
      }
      if (proxyOut == null) continue;

      String? address;
      int? port;
      final settings = (proxyOut['settings'] as Map?) ?? const {};
      final vnext = settings['vnext'] as List?;
      final serversList = settings['servers'] as List?;
      if (vnext != null && vnext.isNotEmpty) {
        address = vnext[0]['address']?.toString();
        port = vnext[0]['port'] is int ? vnext[0]['port'] as int : int.tryParse('${vnext[0]['port']}');
      } else if (serversList != null && serversList.isNotEmpty) {
        address = serversList[0]['address']?.toString();
        port = serversList[0]['port'] is int
            ? serversList[0]['port'] as int
            : int.tryParse('${serversList[0]['port']}');
      }
      if (address == null || port == null) continue;

      if (port == 1) {
        final dm = dayRegex.firstMatch(remarks);
        final vm = volRegex.firstMatch(remarks);
        final em = dateRegex.firstMatch(address);
        if (dm != null) daysText = dm.group(1)?.trim();
        if (vm != null) volText = vm.group(1)?.trim();
        if (em != null) expiryDate = em.group(1);
        continue; // metadata entry — never a connectable server
      }

      final fm = flagRegex.firstMatch(remarks);
      final flagCode = fm != null ? _flagToCode(fm.group(0)!) : null;
      final cleanName = remarks.replaceAll(flagRegex, '').replaceAll(RegExp(r'[◆❖✅]'), '').trim();

      servers.add(ServerConfig(
        name: cleanName.isNotEmpty ? cleanName : address,
        flagCode: flagCode,
        address: address,
        port: port,
        rawConfigJson: jsonEncode(entry),
      ));
    }

    return SubResult(
      PlanInfo(daysText: daysText, volumeText: volText, expiryDate: expiryDate),
      servers,
    );
  }

  static String? _flagToCode(String emoji) {
    final chars = emoji.runes.toList();
    if (chars.length != 2) return null;
    final letters = chars.map((c) => String.fromCharCode(c - 0x1F1E6 + 65)).join();
    return letters.toLowerCase();
  }
}
