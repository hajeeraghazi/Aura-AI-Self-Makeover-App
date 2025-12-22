import 'package:url_launcher/url_launcher.dart';

class ShoppingLinkHelper {
  // ============================================================
  // 🔹 SINGLE-COLOR SEARCH (BACKWARD COMPATIBLE)
  // ============================================================
  static String generate({
    required String item,
    required String color,
    required String gender,
    required String event,
    int maxPrice = 2000,
  }) {
    final phrase =
        "$item $color for ${gender.toLowerCase()} ${event.toLowerCase()} under ₹$maxPrice";

    final query = Uri.encodeComponent(phrase);
    return "https://www.google.com/search?tbm=shop&q=$query";
  }

  // ============================================================
  // 🔹 MULTI-COLOR SEARCH (BEST SUITED COLOURS)
  // ============================================================
  static String generateWithMultipleColors({
    required String item,
    required List<String> colors,
    required String gender,
    required String event,
    int maxPrice = 2000,
  }) {
    final colorPart = colors.join(" OR ");

    final phrase =
        "$item $colorPart for ${gender.toLowerCase()} ${event.toLowerCase()} under ₹$maxPrice";

    final query = Uri.encodeComponent(phrase);
    return "https://www.google.com/search?tbm=shop&q=$query";
  }

  // ============================================================
  // 🔹 MAKEUP PRODUCT SEARCH
  // ============================================================
  static String generateMakeupLink({
    required String product,
    required String gender,
    int maxPrice = 1500,
  }) {
    final phrase =
        "$product makeup for ${gender.toLowerCase()} under ₹$maxPrice";

    final query = Uri.encodeComponent(phrase);
    return "https://www.google.com/search?tbm=shop&q=$query";
  }

  // ============================================================
  // 🔹 ACCESSORIES SEARCH
  // ============================================================
  static String generateAccessoriesLink({
    required String accessory,
    required String gender,
    required String event,
    int maxPrice = 2500,
  }) {
    final phrase =
        "$accessory accessories for ${gender.toLowerCase()} ${event.toLowerCase()} under ₹$maxPrice";

    final query = Uri.encodeComponent(phrase);
    return "https://www.google.com/search?tbm=shop&q=$query";
  }

  // ============================================================
  // 🔹 FOOTWEAR SEARCH
  // ============================================================
  static String generateFootwearLink({
    required String footwear,
    required String gender,
    required String event,
    int maxPrice = 3000,
  }) {
    final phrase =
        "$footwear shoes for ${gender.toLowerCase()} ${event.toLowerCase()} under ₹$maxPrice";

    final query = Uri.encodeComponent(phrase);
    return "https://www.google.com/search?tbm=shop&q=$query";
  }

  // ============================================================
  // 🔹 OPEN URL
  // ============================================================
  static Future<void> open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
