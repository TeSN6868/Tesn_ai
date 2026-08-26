import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BJoDeviceSecurity {
  static const _storage = FlutterSecureStorage();

  static const _secretKey = 'bjo_device_secret_v1';
  static const _deviceIdKey = 'bjo_device_id_v1';

  /// Membuat rahasia perangkat sekali saja.
  /// Rahasia ini tidak dikirim ke server.
  static Future<String> _getOrCreateSecret() async {
    var secret = await _storage.read(key: _secretKey);

    if (secret != null && secret.isNotEmpty) {
      return secret;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));

    secret = base64UrlEncode(bytes);

    await _storage.write(key: _secretKey, value: secret);

    return secret;
  }

  /// ID stabil perangkat yang berasal dari rahasia perangkat.
  /// Yang dikirim ke server hanya hash-nya.
  static Future<String> getDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final secret = await _getOrCreateSecret();

    final digest = sha256.convert(utf8.encode(secret));

    final deviceId = digest.toString();

    await _storage.write(key: _deviceIdKey, value: deviceId);

    return deviceId;
  }

  /// Menghapus identitas perangkat lokal.
  /// Jangan dipanggil saat logout biasa.
  static Future<void> resetDeviceIdentity() async {
    await _storage.delete(key: _secretKey);
    await _storage.delete(key: _deviceIdKey);
  }
}
