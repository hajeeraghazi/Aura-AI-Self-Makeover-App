import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'makeup_guide_screen.dart';

class LipstickScreen extends StatefulWidget {
  final dynamic imageFile;

  const LipstickScreen({super.key, required this.imageFile});

  @override
  State<LipstickScreen> createState() => _LipstickScreenState();
}

class _LipstickScreenState extends State<LipstickScreen> {
  int selectedLipstick = -1;
  Uint8List? _processedImage;
  Uint8List? _originalBytes;

  final List<Color> lipstickColors = [
    Colors.red,
    Colors.pink,
    Colors.deepPurple,
    Colors.orange,
    Colors.brown,
    Colors.purpleAccent,
    Colors.deepOrange,
  ];

  @override
  void initState() {
    super.initState();
    _loadOriginalBytes();
  }

  // Load original image preview
  Future<void> _loadOriginalBytes() async {
    if (widget.imageFile is XFile) {
      _originalBytes = await (widget.imageFile as XFile).readAsBytes();
    } else if (widget.imageFile is File) {
      _originalBytes = await (widget.imageFile as File).readAsBytes();
    } else {
      throw Exception(
          "Unsupported image type: ${widget.imageFile.runtimeType}");
    }
    if (mounted) setState(() {});
  }

  // --------------------------------------------------------
  // ⭐ FIXED: Sending correct JSON structure → No more 422
  // --------------------------------------------------------
  Future<void> _applyLipstick(Color shade) async {
    try {
      final rgb = [shade.red, shade.green, shade.blue];
      debugPrint("💄 Sending lips color: $rgb");

      final makeupPayload = {
        "lips": rgb,
        "intensity": 0.75,
      };

      final result =
          await ApiService.applyMakeup(widget.imageFile, makeupPayload);

      if (result != null && result.isNotEmpty) {
        setState(() => _processedImage = result);
      } else {
        _showError("Failed to apply lipstick.");
      }
    } catch (e) {
      debugPrint("❌ Lipstick error: $e");
      _showError("❌ Error: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildImagePreview() {
    if (_processedImage != null) {
      return Image.memory(_processedImage!, height: 300, fit: BoxFit.contain);
    } else if (_originalBytes != null) {
      return Image.memory(_originalBytes!, height: 300, fit: BoxFit.contain);
    }
    return const SizedBox(
      height: 300,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "💄 Lipstick Try-On",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 10),

          Expanded(child: Center(child: _buildImagePreview())),

          // Lipstick Palette
          Container(
            height: 120,
            color: Colors.grey.shade900,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: lipstickColors.length,
              itemBuilder: (context, index) {
                final selected = selectedLipstick == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => selectedLipstick = index);
                    _applyLipstick(lipstickColors[index]);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 70,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: selected ? 60 : 50,
                          height: selected ? 60 : 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: lipstickColors[index],
                            border: Border.all(
                              color:
                                  selected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Shade ${index + 1}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MakeupGuideScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text(
                "View Makeup Steps",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
