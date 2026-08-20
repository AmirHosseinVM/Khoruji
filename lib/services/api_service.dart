import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'device_id_service.dart';
import '../models/server_config.dart';

class ApiException implements Exception {
  final String code;
  final int? limit;
  ApiException(this.code, {this.limit});
<<<<<<< HEAD

=======
>>>>>>> ce5dae0 (OneSpeed v1)
  @override
  String toString() => 'ApiException($code${limit != null ? ', limit=$limit' : ''})';
}

class SubResult {
  final PlanInfo plan;
  final List<ServerConfig> servers;
  SubResult(this.plan, this.servers);
}

class ApiService {
<<<<<<< HEAD
  // ---------------------------------------------------------------------
  // The app talks ONLY to this — never to the real panel domain directly.
  // Change this if the gateway domain ever changes; nothing else in the
  // app needs to know about the real panel.
  // ---------------------------------------------------------------------
=======
>>>>>>> ce5dae0 (OneSpeed v1)
  static const String gatewayBase = 'https://devfull.sbs/app';

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'onespeed_token';

  static Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  static Future<String?> getSavedToken() => _storage.read(key: _tokenKey);
  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

<<<<<<< HEAD
  static Future<List<dynamic>> fetchRawSub(String token) async {
=======
  /// Returns the raw response body — format (JSON array vs plain URI list)
  /// is detected by parseSub, since the panel has been observed returning
  /// either depending on the account.
  static Future<String> fetchRawSub(String token) async {
>>>>>>> ce5dae0 (OneSpeed v1)
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
<<<<<<< HEAD
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

=======
    if (res.statusCode != 200) throw ApiException('http_${res.statusCode}');
    return res.body;
  }

  static final RegExp _flagRegex = RegExp(r'[\u{1F1E6}-\u{1F1FF}]{2}', unicode: true);
  static final RegExp _dayRegex = RegExp(r'روز\s*:\s*([^\|]+)');
  static final RegExp _volRegex = RegExp(r'حجم\s*:\s*([^\|]+)');
  static final RegExp _dateRegex = RegExp(r'^(\d{4}-\d{2}-\d{2})');

  static String? _flagToCode(String emoji) {
    final chars = emoji.runes.toList();
    if (chars.length != 2) return null;
    final letters = chars.map((c) => String.fromCharCode(c - 0x1F1E6 + 65)).join();
    return letters.toLowerCase();
  }

  /// Shared logic: given a remark string + the address field a "server"
  /// entry claims to have, decide if it's really metadata (port == 1)
  /// rather than a connectable server, and if so extract day/volume/expiry.
  static ({String? days, String? vol, String? expiry, bool isMeta}) _readMeta(
      String remarks, String address, int port) {
    if (port != 1) return (days: null, vol: null, expiry: null, isMeta: false);
    final dm = _dayRegex.firstMatch(remarks);
    final vm = _volRegex.firstMatch(remarks);
    final em = _dateRegex.firstMatch(address);
    return (
      days: dm?.group(1)?.trim(),
      vol: vm?.group(1)?.trim(),
      expiry: em?.group(1),
      isMeta: true,
    );
  }

  static SubResult parseSub(String rawBody) {
    final trimmed = rawBody.trim();
    if (trimmed.startsWith('[')) {
      return _parseJsonFormat(jsonDecode(trimmed) as List);
    }
    return _parseUriListFormat(trimmed);
  }

  // ---- format A: JSON array of full Xray configs ----
  static SubResult _parseJsonFormat(List<dynamic> data) {
    String? daysText, volText, expiryDate;
    final servers = <ServerConfig>[];

>>>>>>> ce5dae0 (OneSpeed v1)
    for (final entry in data) {
      if (entry is! Map) continue;
      final remarks = (entry['remarks'] ?? '').toString();
      final outbounds = (entry['outbounds'] as List?) ?? const [];
<<<<<<< HEAD

      Map? proxyOut;
      for (final o in outbounds) {
        if (o is Map && o['tag'] == 'proxy') {
          proxyOut = o;
          break;
        }
=======
      Map? proxyOut;
      for (final o in outbounds) {
        if (o is Map && o['tag'] == 'proxy') { proxyOut = o; break; }
>>>>>>> ce5dae0 (OneSpeed v1)
      }
      if (proxyOut == null) continue;

      String? address;
      int? port;
      final settings = (proxyOut['settings'] as Map?) ?? const {};
      final vnext = settings['vnext'] as List?;
      final serversList = settings['servers'] as List?;
      if (vnext != null && vnext.isNotEmpty) {
        address = vnext[0]['address']?.toString();
<<<<<<< HEAD
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
=======
        port = _asInt(vnext[0]['port']);
      } else if (serversList != null && serversList.isNotEmpty) {
        address = serversList[0]['address']?.toString();
        port = _asInt(serversList[0]['port']);
      }
      if (address == null || port == null) continue;

      final meta = _readMeta(remarks, address, port);
      if (meta.isMeta) {
        daysText ??= meta.days;
        volText ??= meta.vol;
        expiryDate ??= meta.expiry;
        continue;
      }

      final fm = _flagRegex.firstMatch(remarks);
      final cleanName = remarks.replaceAll(_flagRegex, '').replaceAll(RegExp(r'[◆❖✅]'), '').trim();
      servers.add(ServerConfig(
        name: cleanName.isNotEmpty ? cleanName : address,
        flagCode: fm != null ? _flagToCode(fm.group(0)!) : null,
        address: address,
        port: port,
        rawConfig: jsonEncode(entry),
        isUri: false,
      ));
    }

    return SubResult(PlanInfo(daysText: daysText, volumeText: volText, expiryDate: expiryDate), servers);
  }

  // ---- format B: plain newline-separated share links ----
  static final RegExp _uriHostPort = RegExp(r'^(\w+):\/\/(?:[^@]+@)?([^:\/?#]+):(\d+)');

  static SubResult _parseUriListFormat(String body) {
    String? daysText, volText, expiryDate;
    final servers = <ServerConfig>[];

    final lines = body.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty);

    for (final line in lines) {
      try {
        final hashIdx = line.indexOf('#');
        final remarkRaw = hashIdx >= 0 ? line.substring(hashIdx + 1) : '';
        final remarks = remarkRaw.isNotEmpty ? Uri.decodeComponent(remarkRaw) : '';

        String? address;
        int? port;

        if (line.startsWith('vmess://')) {
          final b64 = line.substring('vmess://'.length).split('#').first;
          final jsonStr = utf8.decode(base64.decode(base64.normalize(b64)));
          final vm = jsonDecode(jsonStr) as Map;
          address = vm['add']?.toString();
          port = _asInt(vm['port']);
        } else {
          final m = _uriHostPort.firstMatch(line);
          if (m == null) continue;
          address = m.group(2);
          port = int.tryParse(m.group(3) ?? '');
        }
        if (address == null || port == null) continue;

        final meta = _readMeta(remarks, address, port);
        if (meta.isMeta) {
          daysText ??= meta.days;
          volText ??= meta.vol;
          expiryDate ??= meta.expiry;
          continue;
        }

        final fm = _flagRegex.firstMatch(remarks);
        final cleanName = remarks.replaceAll(_flagRegex, '').replaceAll(RegExp(r'[◆❖✅]'), '').trim();
        servers.add(ServerConfig(
          name: cleanName.isNotEmpty ? cleanName : address,
          flagCode: fm != null ? _flagToCode(fm.group(0)!) : null,
          address: address,
          port: port,
          rawConfig: line,
          isUri: true,
        ));
      } catch (_) {
        continue; // one malformed line should never break the whole list
      }
    }

    return SubResult(PlanInfo(daysText: daysText, volumeText: volText, expiryDate: expiryDate), servers);
  }

  static int? _asInt(dynamic v) => v is int ? v : int.tryParse('$v');
>>>>>>> ce5dae0 (OneSpeed v1)
}
