import 'package:flutter/material.dart';

import '../helpers/shopping_link_helper.dart';
import '../models/recommendation.dart' as rec_model;
import '../screens/lipstick_screen.dart';
import '../services/recommendation_service.dart';

class RecommendationScreen extends StatefulWidget {
  final String faceShape;
  final String tone;
  final String toneName;
  final String gender;
  final String event;
  final dynamic imageFile;
  final String bodyType;

  const RecommendationScreen({
    super.key,
    required this.faceShape,
    required this.tone,
    required this.toneName,
    required this.gender,
    required this.event,
    required this.bodyType,
    this.imageFile,
  });

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  rec_model.Recommendation? _rec;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendation();
  }

  Future<void> _fetchRecommendation() async {
    final response = await RecommendationService.getRecommendations(
      widget.faceShape,
      widget.tone,
      widget.gender,
      widget.event,
      widget.bodyType,
    );

    setState(() {
      _rec = rec_model.Recommendation.fromJson(response);
      _loading = false;
    });
  }

  // ============================================================
  // UTIL: MULTI COLOR QUERY (ALL BEST SUITED COLORS)
  // ============================================================

  String _buildMultiColorQuery(List<String> colors) {
    return colors.map((c) => c.replaceAll(" ", "+")).join("+OR+");
  }

  void _openShoppingLink({
    required String item,
    String? category,
    List<String>? colors,
  }) {
    final colorQuery = colors != null && colors.isNotEmpty
        ? _buildMultiColorQuery(colors) + "+"
        : "";

    final categoryQuery =
        category != null ? "${category.replaceAll(' ', '+')}+" : "";

    final url = "https://www.google.com/search?q="
        "${item.replaceAll(' ', '+')}+"
        "$categoryQuery"
        "$colorQuery"
        "${widget.gender}+"
        "${widget.event}";

    ShoppingLinkHelper.open(url);
  }

  // ============================================================
  // COLOR NAME → MATERIAL COLOR
  // ============================================================

  Color colorFromName(String name) {
    switch (name.toLowerCase()) {
      case "pastel blue":
      case "sky blue":
        return Colors.lightBlue.shade300;
      case "rose pink":
      case "blush pink":
        return Colors.pink.shade300;
      case "lavender":
        return Colors.purple.shade300;
      case "mint green":
        return Colors.green.shade300;
      case "powder yellow":
        return Colors.yellow.shade300;
      case "ivory":
      case "cream":
        return Colors.brown.shade100;

      case "peach":
        return Colors.orange.shade200;
      case "coral":
        return Colors.deepOrange.shade300;

      case "teal":
        return Colors.teal.shade400;
      case "deep teal":
        return Colors.teal.shade800;
      case "soft teal":
        return Colors.teal.shade300;

      case "mustard":
        return Colors.amber.shade700;
      case "olive":
        return Colors.green.shade700;
      case "rust":
        return Colors.deepOrange;
      case "terracotta":
        return Colors.brown;

      case "emerald green":
        return Colors.green;
      case "navy blue":
        return Colors.indigo;
      case "gold":
      case "metallic gold":
        return Colors.amber;

      case "wine":
        return Colors.red.shade900;
      case "burgundy":
        return Colors.red.shade800;
      case "plum":
        return Colors.purple.shade800;
      case "black":
        return Colors.black;

      default:
        return Colors.grey.shade400;
    }
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  Widget _infoTile(String title, String value, {VoidCallback? onShop}) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text("$title: $value", style: const TextStyle(fontSize: 14)),
          ),
          if (onShop != null)
            TextButton(onPressed: onShop, child: const Text("Shop")),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...children,
        ]),
      ),
    );
  }

  Widget _colorItem(String colorName) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colorFromName(colorName),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 70,
          child: Text(
            colorName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _colorPaletteSection(List<String> colors) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: colors.map(_colorItem).toList(),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final rec = _rec!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 12),

          // 🎨 COLOR PALETTE
          _sectionCard(
            "Best Suited Colours for You",
            [_colorPaletteSection(rec.fashion.colorPalette)],
          ),

          const SizedBox(height: 16),

          // 👗 OUTFITS
          _sectionCard(
            "Recommended Outfits",
            rec.fashion.outfits.map((o) {
              return _infoTile(
                o.item,
                o.color,
                onShop: () => _openShoppingLink(
                  item: o.item,
                  colors: rec.fashion.colorPalette,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // 💄 MAKEUP (CATEGORY AWARE LINKS)
          _sectionCard(
            "Makeup Recommendations",
            [
              _infoTile(
                "Foundation",
                rec.makeup.foundation,
                onShop: () => _openShoppingLink(
                  item: rec.makeup.foundation,
                  category: "foundation makeup",
                ),
              ),
              _infoTile(
                "Lipstick",
                rec.makeup.lipstick,
                onShop: () => _openShoppingLink(
                  item: rec.makeup.lipstick,
                  category: "lipstick makeup",
                ),
              ),
              _infoTile(
                "Blush",
                rec.makeup.blush,
                onShop: () => _openShoppingLink(
                  item: rec.makeup.blush,
                  category: "blush cosmetic",
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 💇 HAIR (LISTS)
          _sectionCard(
            "Hair Recommendations",
            [
              _infoTile(
                "Hairstyles",
                rec.makeup.hairstyles.join(", "),
              ),
              _infoTile(
                "Hair Colors",
                rec.makeup.hairColors.join(", "),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 👜 ACCESSORIES & FOOTWEAR
          _sectionCard(
            "Accessories & Footwear",
            [
              _infoTile(
                "Accessories",
                rec.makeup.accessories.join(", "),
                onShop: () => _openShoppingLink(
                  item: "fashion accessories",
                ),
              ),
              _infoTile(
                "Bag",
                rec.fashion.bag,
                onShop: () => _openShoppingLink(item: rec.fashion.bag),
              ),
              _infoTile(
                "Shoes",
                rec.fashion.shoes,
                onShop: () => _openShoppingLink(item: rec.fashion.shoes),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 🧠 SUMMARY
          _sectionCard("AI Summary", [Text(rec.summary)]),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LipstickScreen(imageFile: widget.imageFile),
                ),
              );
            },
            icon: const Icon(Icons.face_retouching_natural),
            label: const Text("Try Virtual Lipstick"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}
