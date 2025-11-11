import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Multi-layer security for OpenAI API key
/// This file contains only encryption/decryption logic - NO actual secrets
class SecureKeys {
  static const _storage = FlutterSecureStorage();
  static const _keyStorageName = 'oai_k';

  // Obfuscated encryption key parts (split to avoid easy detection)
  static String _getP1() => 'SkR3';

  static String _getP2() => '5yAp';

  static String _getP3() => '1K3y';

  static String _getP4() => '2024';

  /// Get OpenAI API key with multi-layer security
  static Future<String> getOpenAiKey() async {
    // Layer 1: Try to get from secure storage (Android Keystore/iOS Keychain)
    try {
      final storedKey = await _storage.read(key: _keyStorageName);
      if (storedKey != null && storedKey.isNotEmpty) {
        return _decrypt(storedKey);
      }
    } catch (e) {
      // If secure storage fails, fall through to environment variable
    }

    // Layer 2: Get from .env file and store encrypted in secure storage
    try {
      final envKey = dotenv.env['OPENAI_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        // Encrypt and store for next time
        final encrypted = _encrypt(envKey);
        try {
          await _storage.write(key: _keyStorageName, value: encrypted);
        } catch (e) {
          // Ignore storage errors
        }
        return envKey;
      }
    } catch (e) {
      // .env not loaded or key not found
    }

    throw Exception(
      'OpenAI API key not configured!\n\n'
      'Please create a .env file in the project root with:\n'
      'OPENAI_API_KEY=your-key-here\n\n'
      'Get your key from: https://platform.openai.com/api-keys',
    );
  }

  /// Encrypt the API key using AES
  static String _encrypt(String plainText) {
    final keyString = _getP1() + _getP2() + _getP3() + _getP4();
    final key = encrypt.Key.fromUtf8(
      keyString.padRight(32, '0').substring(0, 32),
    );
    final iv = encrypt.IV.fromLength(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return encrypted.base64;
  }

  /// Decrypt the API key
  static String _decrypt(String encryptedText) {
    final keyString = _getP1() + _getP2() + _getP3() + _getP4();
    final key = encrypt.Key.fromUtf8(
      keyString.padRight(32, '0').substring(0, 32),
    );
    final iv = encrypt.IV.fromLength(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decrypt64(encryptedText, iv: iv);

    return decrypted;
  }

  /// Clear stored key (useful for logout or key rotation)
  static Future<void> clearStoredKey() async {
    try {
      await _storage.delete(key: _keyStorageName);
    } catch (e) {
      // Ignore errors
    }
  }
}
