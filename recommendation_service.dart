import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RecommendationService {
  // =============================================================
  // ✔ BASE URL FOR *REAL ANDROID DEVICE* (USB connected)
  // =============================================================

  // Use your LAPTOP IP here (confirmed: 10.197.217.146)
  static const String _deviceBase = "http://localhost:8000";

  // For web or iOS (same local network IP)
  static const String _webIosBase = "http://localhost:8000";

  /// Picks correct base URL
  static String get baseUrl {
    if (kIsWeb) return _webIosBase;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _deviceBase; // Real Android device via USB/WiFi
      case TargetPlatform.iOS:
        return _webIosBase;
      default:
        return _deviceBase; // Windows / Mac / Linux fallback
    }
  }

  // =============================================================
  // ✔ MAKEUP + FASHION RECOMMENDATION API
  // =============================================================
  static Future<Map<String, dynamic>> getRecommendations(
    String faceShape,
    String skinTone,
    String gender,
    String event,
    String bodyType,
  ) async {
    final url = Uri.parse("$baseUrl/api/makeup_recommendation");

    debugPrint("📡 Sending POST → $url");

    final payload = {
      "face_shape": faceShape,
      "skin_tone": skinTone,
      "gender": gender,
      "event": event,
      "body_type": bodyType,
    };

    debugPrint("📦 Payload: $payload");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      debugPrint("📥 Status: ${response.statusCode}");
      debugPrint("📥 Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            "Server error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      throw Exception("Failed to fetch recommendations: $e");
    }
  }

  // =============================================================
  // ✔ HEALTH CHECK
  // =============================================================
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/health"));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
