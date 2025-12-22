class Recommendation {
  final Makeup makeup;
  final Fashion fashion;
  final String summary;

  Recommendation({
    required this.makeup,
    required this.fashion,
    required this.summary,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      makeup: Makeup.fromJson(json['makeup'] ?? {}),
      fashion: Fashion.fromJson(json['fashion'] ?? {}),
      summary: json['summary'] ?? '',
    );
  }
}

class Makeup {
  final String foundation;
  final String lipstick;
  final String blush;

  // ✅ LISTS
  final List<String> hairstyles;
  final List<String> hairColors;

  final List<String> accessories;

  Makeup({
    required this.foundation,
    required this.lipstick,
    required this.blush,
    required this.hairstyles,
    required this.hairColors,
    required this.accessories,
  });

  factory Makeup.fromJson(Map<String, dynamic> json) {
    return Makeup(
      foundation: json['foundation'] ?? '',
      lipstick: json['lipstick'] ?? '',
      blush: json['blush'] ?? '',

      // ✅ MAP LISTS (camelCase + snake_case safe)
      hairstyles:
          List<String>.from(json['hairstyles'] ?? json['hair_styles'] ?? []),
      hairColors:
          List<String>.from(json['hairColors'] ?? json['hair_colors'] ?? []),

      accessories: List<String>.from(json['accessories'] ?? []),
    );
  }
}

class Fashion {
  final List<String> colorPalette;
  final List<Outfit> outfits;
  final String bag;
  final String shoes;
  final String recommendedColor;

  Fashion({
    required this.colorPalette,
    required this.outfits,
    required this.bag,
    required this.shoes,
    required this.recommendedColor,
  });

  factory Fashion.fromJson(Map<String, dynamic> json) {
    final palette = json['colorPalette'] ?? json['color_palette'] ?? [];

    return Fashion(
      colorPalette: List<String>.from(palette),
      outfits: (json['outfits'] as List<dynamic>? ?? [])
          .map((e) => Outfit.fromJson(e))
          .toList(),
      bag: json['bag'] ?? '',
      shoes: json['shoes'] ?? '',
      recommendedColor:
          json['recommendedColor'] ?? json['recommended_color'] ?? '',
    );
  }
}

class Outfit {
  final String item;
  final String color;

  Outfit({
    required this.item,
    required this.color,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      item: json['item'] ?? '',
      color: json['color'] ?? '',
    );
  }
}
