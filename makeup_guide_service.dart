import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class MakeupGuideService {
  // ==========================================================
  // BASE URL (UNCHANGED AS REQUESTED)
  // ==========================================================
  static const String _base = "http://localhost:8000/api/makeup_guide";

  static String get baseUrl => _base;

  // ==========================================================
  // FILE CONVERSION (MOST IMPORTANT FIX)
  // ==========================================================
  static Future<http.MultipartFile> _file(dynamic img,
      {String name = "image"}) async {
    Uint8List bytes;
    String filename = "$name.jpg";

    print("UPLOAD TYPE → ${img.runtimeType}");

    // ---------------------------------------------------------
    // 🟣 CASE 1 — XFile (Camera/Gallery)
    // ---------------------------------------------------------
    if (img is XFile) {
      print("Using XFile → readAsBytes()");
      bytes = await img.readAsBytes();
      filename = img.name.isNotEmpty ? img.name : "$name.jpg";
    }

    // ---------------------------------------------------------
    // 🟣 CASE 2 — Uint8List (WEB / Memory images)
    // ---------------------------------------------------------
    else if (img is Uint8List) {
      print("Received Uint8List (${img.length})");
      bytes = img;
      filename = "$name.jpg";
    }

    // ---------------------------------------------------------
    // 🟣 CASE 3 — File (Mobile Only)
    // ---------------------------------------------------------
    else if (img is File) {
      print("Reading File");
      bytes = await img.readAsBytes();
      filename = img.path.split("/").last;
    } else {
      throw Exception("Unsupported image type: ${img.runtimeType}");
    }

    // ---------------------------------------------------------
    // Detect PNG
    // ---------------------------------------------------------
    final isPng = bytes.length > 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;

    return http.MultipartFile.fromBytes(
      name,
      bytes,
      filename: filename,
      contentType: MediaType("image", isPng ? "png" : "jpeg"),
    );
  }

  // ==========================================================
  // HEALTH CHECK
  // ==========================================================
  static Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/health"));
      print("Health → ${res.statusCode} : ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      print("Health check error: $e");
      return false;
    }
  }

  // ==========================================================
  // ANALYZE FACE
  // ==========================================================
  static Future<Map<String, dynamic>> analyzeFace(dynamic img) async {
    final req =
        http.MultipartRequest("POST", Uri.parse("$baseUrl/analyze_face"));

    req.files.add(await _file(img));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    print("AnalyzeFace → ${res.statusCode} : ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Analyze failed: ${res.body}");
    }

    return jsonDecode(res.body);
  }

  // ==========================================================
  // GET MAKEUP GUIDE
  // ==========================================================
  static Future<Map<String, dynamic>> getMakeupGuide(
    dynamic img,
    List<String> looks, {
    String? lipstickHex,
  }) async {
    final req =
        http.MultipartRequest("POST", Uri.parse("$baseUrl/get_makeup_guide"));

    req.files.add(await _file(img));

    req.fields["makeupLooks"] = looks.join(",");

    if (lipstickHex != null && lipstickHex.isNotEmpty) {
      req.fields["lipstickColor"] = lipstickHex.replaceAll("#", "");
    }

    req.fields["returnMaskPNG"] = "true";

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    print("Guide → ${res.statusCode} : ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Guide generation failed: ${res.body}");
    }

    return jsonDecode(res.body);
  }

  // ==========================================================
  // COMPARE BEFORE / AFTER (NOW RETURNS FEEDBACK)
  // ==========================================================
  static Future<Map<String, dynamic>> compareMakeup(
      dynamic before, dynamic after) async {
    final req =
        http.MultipartRequest("POST", Uri.parse("$baseUrl/compare_makeup"));

    req.files.add(await _file(before, name: "originalImage"));
    req.files.add(await _file(after, name: "afterImage"));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    print("Compare → ${res.statusCode} : ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Compare failed: ${res.body}");
    }

    return jsonDecode(res.body);
  }
}
