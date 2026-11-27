import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides a persistent device identifier for anti-abuse (e.g., limiting
/// initial free credit grants to one per device).
///
/// Uses FlutterSecureStorage (iOS Keychain / Android EncryptedSharedPreferences)
/// with SharedPreferences fallback so the ID persists across app restarts and
/// iOS reinstalls.
class DeviceIdService {
  DeviceIdService._internal();
  static final DeviceIdService instance = DeviceIdService._internal();

  static const String _storageKey = 'persistent_device_id';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  String? _cachedDeviceId;

  /// Returns a persistent UUID v4 device identifier, creating and storing it
  /// on first call.
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return _cachedDeviceId!;
    }

    try {
      final secureId = await _secureStorage.read(key: _storageKey);
      if (secureId != null && secureId.isNotEmpty) {
        _cachedDeviceId = secureId;
        return secureId;
      }
    } catch (e) {
      debugPrint('[DeviceIdService] SecureStorage read failed: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsId = prefs.getString(_storageKey);
      if (prefsId != null && prefsId.isNotEmpty) {
        _cachedDeviceId = prefsId;
        await _persistToSecureStorage(prefsId);
        return prefsId;
      }
    } catch (e) {
      debugPrint('[DeviceIdService] SharedPreferences read failed: $e');
    }

    final newId = _generateUuidV4();
    _cachedDeviceId = newId;
    await _persistToSecureStorage(newId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, newId);
    } catch (e) {
      debugPrint('[DeviceIdService] SharedPreferences write failed: $e');
    }

    return newId;
  }

  Future<void> _persistToSecureStorage(String id) async {
    try {
      await _secureStorage.write(key: _storageKey, value: id);
    } catch (e) {
      debugPrint('[DeviceIdService] SecureStorage write failed: $e');
    }
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(hex).toList();
    return '${b[0]}${b[1]}${b[2]}${b[3]}-'
        '${b[4]}${b[5]}-'
        '${b[6]}${b[7]}-'
        '${b[8]}${b[9]}-'
        '${b[10]}${b[11]}${b[12]}${b[13]}${b[14]}${b[15]}';
  }
}
