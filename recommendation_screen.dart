// FULLY UPDATED RecommendationScreen.dart
// Supports STONE tone names + readable color_name for UI

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/shopping_link_helper.dart';
import '../models/recommendation.dart' as rec_model;
import '../screens/lipstick_screen.dart';
import '../services/recommendation_service.dart';

class RecommendationScreen extends StatefulWidget {
  final String faceShape;
  final String tone; // backend bucket name (caramel_brown)
  final String toneName; // readable pretty name (Caramel Brown)
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
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _fetchRecommendation();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // -------------------------------------------------------------
  // URL OPEN SAFELY
  // -------------------------------------------------------------
  Future<void> _openLink(String url) async {
    debugPrint("🛒 Opening: $url");

    final uri = Uri.tryParse(url);
    if (uri == null) {
      debugPrint("❌ Invalid URL: $url");
      return;
    }

    if (!await canLaunchUrl(uri)) {
      debugPrint("❌ Device cannot open URL");
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // -------------------------------------------------------------
  // FETCH RECOMMENDATIONS FROM API
  // -------------------------------------------------------------
  Future<void> _fetchRecommendation() async {
    debugPrint("📡 Fetching recommendations...");

    try {
      final response = await RecommendationService.getRecommendations(
        widget.faceShape,
        widget.tone,
        widget.gender,
        widget.event,
        widget.bodyType,
      );

      if (_disposed) return;

      setState(() {
        _rec = rec_model.Recommendation.fromJson(response);
        _loading = false;
      });
    } catch (e) {
      if (_disposed) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading recommendations: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // -------------------------------------------------------------
  // PROFILE IMAGE DISPLAY
  // -------------------------------------------------------------
  Widget _buildProfileImage() {
    final img = widget.imageFile;

    if (img == null) {
      return const Icon(Icons.person, size: 140, color: Colors.grey);
    }

    try {
      if (kIsWeb && img.bytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            img.bytes as Uint8List,
            width: 140,
            height: 140,
            fit: BoxFit.cover,
          ),
        );
      }

      if (!kIsWeb && img.path != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(img.path),
            width: 140,
            height: 140,
            fit: BoxFit.cover,
          ),
        );
      }
    } catch (e) {
      debugPrint("Image render error: $e");
    }

    return const Icon(Icons.person, size: 140, color: Colors.grey);
  }

  // -------------------------------------------------------------
  // COLOR PALETTE VIEW
  // -------------------------------------------------------------
  Widget _buildColorPalette(List<String> palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Color Palette",
          style: TextStyle(
            fontSize: 18,
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: palette
              .map(
                (colorName) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurple),
                  ),
                  child: Text(colorName),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // -------------------------------------------------------------
  // MAIN UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_rec == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: _fetchRecommendation,
            child: const Text("Retry"),
          ),
        ),
      );
    }

    final rec = _rec!;

    // Shopping Links
    final outfitLinks = [
      for (var o in rec.fashion.outfits)
        ShoppingLinkHelper.generate(
          item: o.item,
          color: o.color,
          gender: widget.gender,
          event: widget.event,
        )
    ];

    final bagLink = ShoppingLinkHelper.generate(
      item: rec.fashion.bag,
      color: rec.fashion.recommendedColor,
      gender: widget.gender,
      event: widget.event,
    );

    final shoesLink = ShoppingLinkHelper.generate(
      item: rec.fashion.shoes,
      color: rec.fashion.recommendedColor,
      gender: widget.gender,
      event: widget.event,
    );

    final foundationLink = ShoppingLinkHelper.generate(
      item: rec.makeup.foundation,
      color: "neutral",
      gender: widget.gender,
      event: widget.event,
    );

    final lipstickLink = ShoppingLinkHelper.generate(
      item: rec.makeup.lipstick,
      color: rec.makeup.lipstick,
      gender: widget.gender,
      event: widget.event,
    );

    final blushLink = ShoppingLinkHelper.generate(
      item: rec.makeup.blush,
      color: "blush",
      gender: widget.gender,
      event: widget.event,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileImage(),
            const SizedBox(height: 18),

            /// ⭐ READABLE SKIN-TONE NAME (Caramel Brown)
            Text(
              "Face: ${widget.faceShape} | Tone: ${widget.toneName}\n"
              "Gender: ${widget.gender} | Event: ${widget.event}\n"
              "Body Type: ${widget.bodyType}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 24),

            // Makeup Card
            _buildCard(
              "Makeup Recommendations",
              [
                "Foundation: ${rec.makeup.foundation}",
                "Lipstick: ${rec.makeup.lipstick}",
                "Blush: ${rec.makeup.blush}",
                "Hairstyle: ${rec.makeup.hairstyle}",
              ],
              linkMap: {
                0: foundationLink,
                1: lipstickLink,
                2: blushLink,
              },
            ),

            _buildCard(
              "Face Accessories",
              rec.makeup.accessories.map((e) => "• $e").toList(),
            ),

            _buildColorPalette(rec.fashion.colorPalette),

            // Outfits
            _buildCard(
              "Outfits",
              rec.fashion.outfits.map((o) => "${o.item} — ${o.color}").toList(),
              linkMap: {
                for (int i = 0; i < outfitLinks.length; i++) i: outfitLinks[i]
              },
            ),

            // Bag + Shoes
            _buildCard(
              "Accessories",
              ["Bag: ${rec.fashion.bag}", "Shoes: ${rec.fashion.shoes}"],
              linkMap: {0: bagLink, 1: shoesLink},
            ),

            _buildCard("AI Summary", [rec.summary]),

            const SizedBox(height: 20),

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // CARD BUILDER
  // -------------------------------------------------------------
  Widget _buildCard(
    String title,
    List<String> items, {
    Map<int, String>? linkMap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(items.length, (index) {
              final link = linkMap?[index];

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      items[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (link != null)
                    IconButton(
                      icon: const Icon(
                        Icons.shopping_bag,
                        color: Colors.pinkAccent,
                      ),
                      onPressed: () => _openLink(link),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
