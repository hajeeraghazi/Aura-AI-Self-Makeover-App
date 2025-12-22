import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/makeup_guide_models.dart';

class ComparisonWidget extends StatelessWidget {
  final MakeupComparisonData comparisonData;
  final VoidCallback onTryAgain;
  final VoidCallback onStartOver;

  const ComparisonWidget({
    super.key,
    required this.comparisonData,
    required this.onTryAgain,
    required this.onStartOver,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List comparisonBytes = comparisonData.comparisonBytes;
    final feedback = comparisonData.feedback;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // --------------------------------------------
          // ❇️ BEFORE/AFTER IMAGE
          // --------------------------------------------
          comparisonBytes.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    comparisonBytes,
                    height: 300,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                )
              : const Text(
                  "Comparison image unavailable",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

          const SizedBox(height: 25),

          // --------------------------------------------
          // ❇️ SCORE
          // --------------------------------------------
          Text(
            "Score: ${feedback.score}/100",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------
          // ❇️ OVERALL RATING
          // --------------------------------------------
          Text(
            feedback.overall,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          // --------------------------------------------
          // ❇️ TIPS
          // --------------------------------------------
          Column(
            children: feedback.tips
                .map(
                  (tip) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("• ",
                            style:
                                TextStyle(fontSize: 16, color: Colors.black87)),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(fontSize: 16, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 30),

          // --------------------------------------------
          // ❇️ BUTTONS
          // --------------------------------------------
          ElevatedButton(
            onPressed: onTryAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text("Try Again"),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: onStartOver,
            child: const Text(
              "Start Over",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
