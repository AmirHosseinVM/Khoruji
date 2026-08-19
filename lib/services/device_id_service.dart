import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Generates a UUID once per install and keeps it in Android Keystore-backed
/// secure storage. This is what the server (sub.php) uses to enforce the
/// per-token device limit (.X1 / .X2 / ...). It is intentionally NOT a
/// hardware serial — those are blocked/unreliable on modern Android and
/// would break on many devices; an app-generated persistent id is the
/// approach actually used by comparable apps.
class DeviceIdService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'onespeed_device_id';

  static Future<String> getDeviceId() async {
    final existing = await _storage.read(key: _key);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await _storage.write(key: _key, value: id);
    return id;
  }
}
