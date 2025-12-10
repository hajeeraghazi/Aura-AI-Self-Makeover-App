import 'dart:typed_data';

import 'package:flutter/material.dart';

class MakeupSelectionWidget extends StatelessWidget {
  final Uint8List? selectedImageBytes;

  final List<String> selectedLooks;
  final Function(String) onLookToggle;
  final VoidCallback onGenerateGuide;
  final VoidCallback onChangePhoto;
  final VoidCallback onColorPicker;

  const MakeupSelectionWidget({
    super.key,
    required this.selectedImageBytes,
    required this.selectedLooks,
    required this.onLookToggle,
    required this.onGenerateGuide,
    required this.onChangePhoto,
    required this.onColorPicker,
  });

  // IMAGE PREVIEW — BYTES ONLY
  Widget _buildImage() {
    if (selectedImageBytes != null) {
      return Image.memory(
        selectedImageBytes!,
        width: 240,
        height: 240,
        fit: BoxFit.cover,
      );
    }
    return const Icon(Icons.person, size: 120, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> looks = {
      'foundation': '💄',
      'blush': '🌸',
      'eyeshadow': '👁️',
      'eyeliner': '✏️',
      'lipstick': '💋',
      'highlighter': '✨',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildImage(),
          ),
          const SizedBox(height: 20),
          const Text(
            "Select Makeup Looks",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: looks.entries.map((entry) {
              final lookKey = entry.key;
              final icon = entry.value;
              final isSelected = selectedLooks.contains(lookKey);

              return GestureDetector(
                onTap: () => onLookToggle(lookKey),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.pink : Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        lookKey[0].toUpperCase() + lookKey.substring(1),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (selectedLooks.contains("lipstick"))
            ElevatedButton.icon(
              onPressed: onColorPicker,
              icon: const Icon(Icons.color_lens, color: Colors.white),
              label: const Text("Choose Lipstick Color"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onGenerateGuide,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Generate Guide",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: onChangePhoto,
            child: const Text(
              "Change Photo",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
