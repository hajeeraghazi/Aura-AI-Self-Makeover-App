import 'dart:convert';
import 'dart:typed_data';

/// =========================================================
/// Safe Base64 Decoder (never throws)
/// =========================================================
Uint8List safeBase64ToBytes(dynamic data) {
  if (data == null) return Uint8List(0);

  if (data is Uint8List) return data;

  if (data is String) {
    try {
      String cleaned = data.trim().replaceAll("\n", "").replaceAll(" ", "");
      // Fix base64 padding issues (common in Android & Web)
      while (cleaned.length % 4 != 0) {
        cleaned += "=";
      }
      return base64Decode(cleaned);
    } catch (_) {
      return Uint8List(0);
    }
  }

  return Uint8List(0);
}

/// =========================================================
/// Auto descriptions for each makeup step
/// =========================================================
const Map<String, String> defaultDescriptions = {
  "foundation":
      "Apply foundation evenly across the face for smooth and even coverage.",
  "blush":
      "Apply blush on the apples of your cheeks and blend upward for a natural glow.",
  "eyeshadow":
      "Blend eyeshadow smoothly across the eyelids to enhance depth and definition.",
  "eyeliner":
      "Apply eyeliner along the upper lash line for bold eye definition.",
  "lipstick": "Follow the highlighted region to apply your lipstick evenly.",
  "highlighter":
      "Apply highlighter on cheekbones, nose bridge, and brow bone for radiant shine.",
};

/// =========================================================
/// Makeup Guide Step Model
/// =========================================================
/// Backend JSON Example:
/// {
///   "step": 2,
///   "makeupType": "blush",
///   "image": "<jpg-base64>",
///   "maskPNG": "<png-base64>"
/// }
class MakeupGuideStep {
  final int step;
  final String makeupType;

  final String imageBase64;
  final String? maskPngBase64;

  /// Auto-generated description
  String get description => defaultDescriptions[makeupType] ?? "";

  Uint8List get imageBytes => safeBase64ToBytes(imageBase64);
  Uint8List get maskBytes =>
      maskPngBase64 == null ? Uint8List(0) : safeBase64ToBytes(maskPngBase64);

  MakeupGuideStep({
    required this.step,
    required this.makeupType,
    required this.imageBase64,
    this.maskPngBase64,
  });

  factory MakeupGuideStep.fromJson(Map<String, dynamic> json) {
    return MakeupGuideStep(
      step: json["step"] is int
          ? json["step"]
          : int.tryParse("${json["step"]}") ?? 0,
      makeupType: json["makeupType"]?.toString().toLowerCase() ?? "",
      imageBase64: json["image"]?.toString() ?? "",
      maskPngBase64: json["maskPNG"]?.toString(),
    );
  }
}

/// =========================================================
/// Feedback Model
/// =========================================================
/// Backend JSON:
/// {
///   "overall": "Great look! Minor tweaks needed.",
///   "score": 82,
///   "tips": ["Blend foundation more on left cheek"]
/// }
class MakeupFeedback {
  final String overall;
  final int score;
  final List<String> tips;

  MakeupFeedback({
    required this.overall,
    required this.score,
    required this.tips,
  });

  factory MakeupFeedback.fromJson(Map<String, dynamic> json) {
    return MakeupFeedback(
      overall: json["overall"]?.toString() ?? "",
      score: json["score"] is int
          ? json["score"]
          : int.tryParse("${json["score"]}") ?? 0,
      tips: json["tips"] is List
          ? List<String>.from(
              json["tips"].map((e) => e.toString()),
            )
          : [],
    );
  }
}

/// =========================================================
/// Comparison Data (Before/After Analysis)
/// =========================================================
/// {
///   "comparisonImage": "<base64>",
///   "feedback": { ... }
/// }
class MakeupComparisonData {
  final Uint8List comparisonBytes;
  final MakeupFeedback feedback;

  MakeupComparisonData({
    required this.comparisonBytes,
    required this.feedback,
  });

  factory MakeupComparisonData.fromJson(Map<String, dynamic> json) {
    return MakeupComparisonData(
      comparisonBytes: safeBase64ToBytes(json["comparisonImage"]),
      feedback: MakeupFeedback.fromJson(json["feedback"] ?? {}),
    );
  }
}

/// =========================================================
/// UI Makeup Look Model
/// =========================================================
class MakeupLook {
  final String name;
  final String icon;
  final String description;

  MakeupLook({
    required this.name,
    required this.icon,
    required this.description,
  });
}

final List<MakeupLook> availableMakeupLooks = [
  MakeupLook(name: 'foundation', icon: '💄', description: 'Smooth coverage'),
  MakeupLook(name: 'blush', icon: '🌸', description: 'Cheek color'),
  MakeupLook(name: 'eyeshadow', icon: '👁️', description: 'Eye shades'),
  MakeupLook(name: 'eyeliner', icon: '✏️', description: 'Define eyes'),
  MakeupLook(name: 'lipstick', icon: '💋', description: 'Lip color'),
  MakeupLook(name: 'highlighter', icon: '✨', description: 'Glow points'),
];
