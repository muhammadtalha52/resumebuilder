import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// HMAC-SHA256 authentication service for AI backend
/// Matches the authentication implementation from React app
class HmacAuthService {
  // App credentials loaded from .env
  static String get appId => dotenv.env['APP_ID'] ?? 'SkillResyApp';
  static String get appSecret => dotenv.env['APP_SECRET'] ?? 'SkillResy@123';

  /// Compute HMAC-SHA256 and return hex string
  /// Matches your backend's signature verification
  static String computeHmacHex(String secret, String message) {
    if (secret.isEmpty) {
      throw Exception('APP_SECRET not configured');
    }

    final key = utf8.encode(secret);
    final bytes = utf8.encode(message);

    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);

    return digest.toString(); // Returns hex string
  }

  /// Build auth headers matching your backend implementation
  /// Returns the 3 required headers:
  /// - X-App-Id: Application identifier
  /// - X-Timestamp: Current timestamp in seconds
  /// - X-App-Signature: HMAC-SHA256 signature
  static Map<String, String> buildAuthHeaders() {
    // Timestamp in seconds (matching backend implementation)
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();

    // Message format: timestamp:appId (exactly like backend expects)
    final message = '$timestamp:$appId';

    // Generate signature
    final signature = computeHmacHex(appSecret, message);

    return {
      'X-App-Id': appId,
      'X-Timestamp': timestamp,
      'X-App-Signature': signature,
    };
  }
}
