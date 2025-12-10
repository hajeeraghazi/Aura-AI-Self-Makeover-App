import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  // ⭐ UPDATE YOUR SERVER IP HERE
  static const String baseUrl = "http://localhost:8000";

  // =========================================================================
  //  HELPER → Convert File/XFile/Uint8List → MultipartFile
  // =========================================================================
  static Future<http.MultipartFile> _prepareImageFile(
      dynamic imageSource, String fieldName) async {
    // Web → Uint8List
    if (kIsWeb && imageSource is Uint8List) {
      return http.MultipartFile.fromBytes(
        fieldName,
        imageSource,
        filename: "upload.jpg",
        contentType: MediaType("image", "jpeg"),
      );
    }

    // XFile (mobile)
    if (imageSource is XFile) {
      final bytes = await imageSource.readAsBytes();
      return http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: "upload.jpg",
        contentType: MediaType("image", "jpeg"),
      );
    }

    // File (mobile)
    if (imageSource is File) {
      return await http.MultipartFile.fromPath(
        fieldName,
        imageSource.path,
        contentType: MediaType("image", "jpeg"),
      );
    }

    throw Exception("Unsupported image type for upload");
  }

  // =========================================================================
  //  FACE SCAN API → Skin Tone + Face Shape
  // =========================================================================
  static Future<Map<String, dynamic>> faceScanApi(
      dynamic imageFileOrBytes) async {
    try {
      final url = Uri.parse("$baseUrl/api/classify");

      print("📡 Sending POST → $url");
      print("📦 Preparing file...");

      var request = http.MultipartRequest("POST", url);

      // MUST BE FIELD NAME: "file"
      request.files.add(await _prepareImageFile(imageFileOrBytes, "file"));

      var response = await request.send();
      var respBody = await response.stream.bytesToString();

      print("🔍 CLASSIFY RESPONSE RAW => $respBody");

      if (response.statusCode == 200) {
        print("✅ CLASSIFY SUCCESS");
        return jsonDecode(respBody);
      } else {
        throw Exception(
            "Face scan failed: HTTP ${response.statusCode} | $respBody");
      }
    } catch (e) {
      print("❌ faceScanApi error: $e");
      return {};
    }
  }

  // =========================================================================
  //  SKIN TONE ONLY API
  // =========================================================================
  static Future<Map<String, dynamic>> skinToneApi(
      dynamic imageFileOrBytes) async {
    try {
      final url = Uri.parse("$baseUrl/api/skin_tone");

      print("📡 Sending POST → $url");

      var request = http.MultipartRequest("POST", url);

      request.files.add(await _prepareImageFile(imageFileOrBytes, "file"));

      var response = await request.send();
      var respBody = await response.stream.bytesToString();

      print("🔍 SKIN TONE RESPONSE RAW => $respBody");

      if (response.statusCode == 200) {
        return jsonDecode(respBody);
      } else {
        throw Exception(
            "skinToneApi failed: ${response.statusCode} | $respBody");
      }
    } catch (e) {
      print("❌ skinToneApi error: $e");
      return {};
    }
  }

  // =========================================================================
  //  MAKEUP + FASHION RECOMMENDATION API
  // =========================================================================
  static Future<Map<String, dynamic>> getMakeupRecommendation({
    required String faceShape,
    required String skinTone,
    required String gender,
    required String event,
    required String bodyType,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/api/makeup_recommendation");

      final payload = {
        "face_shape": faceShape,
        "skin_tone": skinTone,
        "gender": gender,
        "event": event,
        "body_type": bodyType,
      };

      print("📡 Sending POST → $url");
      print("📦 Payload: $payload");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("🔍 RECOMMEND RESPONSE RAW => ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            "Recommendation API failed: HTTP ${response.statusCode} | ${response.body}");
      }
    } catch (e) {
      print("❌ getMakeupRecommendation error: $e");
      return {};
    }
  }

  // =========================================================================
  //  FINAL MAKEUP APPLICATION (Lipstick / Blush / etc)
  // =========================================================================
  static Future<Uint8List?> applyMakeup(
      dynamic imageFileOrBytes, Map<String, dynamic> makeupPayload) async {
    try {
      final url = Uri.parse("$baseUrl/api/lipstick/apply_makeup");

      print("📡 Sending POST → $url");
      print("💄 Sending PAYLOAD: $makeupPayload");

      var request = http.MultipartRequest("POST", url);

      // must be field "image"
      request.files.add(await _prepareImageFile(imageFileOrBytes, "image"));

      // send JSON field
      request.fields["req"] = jsonEncode({"makeup": makeupPayload});

      var response = await request.send();
      var respRaw = await response.stream.bytesToString();

      print("🔍 MAKEUP APPLY RESPONSE RAW => $respRaw");

      if (response.statusCode == 200) {
        final jsonRes = jsonDecode(respRaw);
        return base64Decode(jsonRes["makeup_image_base64"]);
      } else {
        throw Exception(
            "applyMakeup failed: HTTP ${response.statusCode} | $respRaw");
      }
    } catch (e) {
      print("❌ applyMakeup error: $e");
      return null;
    }
  }
}
