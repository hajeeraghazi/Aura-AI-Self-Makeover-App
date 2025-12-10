import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/makeup_guide_models.dart';

class StepGuideWidget extends StatelessWidget {
  final MakeupGuideStep currentStep;
  final int currentIndex;
  final int totalSteps;
  final bool canGoPrevious;
  final bool isLastStep;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const StepGuideWidget({
    super.key,
    required this.currentStep,
    required this.currentIndex,
    required this.totalSteps,
    required this.canGoPrevious,
    required this.isLastStep,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List baseImage =
        currentStep.imageBytes; // JPG after applying makeup
    final Uint8List maskImage =
        currentStep.maskBytes; // PNG transparent mask overlay

    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ------------------------------------------------------------
          // STEP HEADER
          // ------------------------------------------------------------
          Text(
            "Step ${currentIndex + 1} of $totalSteps",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Text(
            currentStep.makeupType.toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.pink,
            ),
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------------
          // COMBINED IMAGE (makeup + highlighted overlay mask)
          // ------------------------------------------------------------
          Container(
            height: screenHeight * 0.55,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black,
            ),
            child: Stack(
              children: [
                // BASE IMAGE
                Positioned.fill(
                  child: baseImage.isNotEmpty
                      ? Image.memory(
                          baseImage,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        )
                      : const Center(
                          child: Text(
                            "Image unavailable",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                ),

                // MASK IMAGE OVERLAY (if present)
                if (maskImage.isNotEmpty)
                  Positioned.fill(
                    child: Image.memory(
                      maskImage,
                      fit: BoxFit.contain,
                      color: Colors.white.withOpacity(0.35),
                      colorBlendMode: BlendMode.modulate,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------------------
          // DESCRIPTION
          // ------------------------------------------------------------
          Text(
            currentStep.description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.45),
          ),

          const SizedBox(height: 28),

          // ------------------------------------------------------------
          // NAVIGATION BUTTONS
          // ------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: canGoPrevious ? onPrevious : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400,
                ),
                child: const Text("Previous"),
              ),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                child: Text(isLastStep ? "Finish" : "Next"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
