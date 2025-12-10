class ShoppingLinkHelper {
  static String generate({
    required String item,
    required String color,
    required String gender,
    required String event,
  }) {
    // Clean text
    final safeItem = item.trim();
    final safeColor = color.trim();
    final safeGender = gender.trim().toLowerCase();
    final safeEvent = event.trim().toLowerCase();

    // Example: "beige t-shirt for women casual"
    final phrase = "$safeColor $safeItem for $safeGender $safeEvent";

    // Encode safely
    final query = Uri.encodeQueryComponent(phrase);

    // ⭐ ALWAYS WORKS – Google Shopping Search
    return "https://www.google.com/search?tbm=shop&q=$query";
  }
}
