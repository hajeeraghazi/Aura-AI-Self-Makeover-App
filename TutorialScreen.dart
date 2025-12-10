// ---------------------- TUTORIAL SCREEN ----------------------
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../main.dart' show MakeupAppState; // ✅ app state provider

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  // ---------------- IMAGE PICKER HANDLER ----------------
  Future<void> _pickImage(BuildContext context, bool completed) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null || !context.mounted) return;
    final appState = context.read<MakeupAppState>();

    try {
      if (kIsWeb) {
        // ✅ Proper byte handling for web
        final bytes = await pickedFile.readAsBytes();
        appState.setWebImage(bytes, completed);

        if (completed) {
          await appState.analyzeMakeup();
        }
      } else {
        // ✅ Proper file handling for Android/iOS
        final file = File(pickedFile.path);
        if (completed) {
          appState.setCompletedImage(file);
          await appState.analyzeMakeup();
        } else {
          appState.setUserImage(file);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error loading image: $e")),
      );
    }
  }

  // ---------------- MAIN UI ----------------
  @override
  Widget build(BuildContext context) {
    final state = context.watch<MakeupAppState>();

    if (state.selectedLook == null) {
      // fallback if user opens this screen without a selected look
      return const Scaffold(
        body: Center(child: Text("No makeup look selected.")),
      );
    }

    final look = state.selectedLook!;
    final step = look.steps[state.currentStep];

    return Scaffold(
      appBar: AppBar(
        title: Text(look.name),
        backgroundColor: Colors.pink,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step ${state.currentStep + 1} of ${look.steps.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // ---------------- STEP CARD ----------------
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.area,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(step.instruction),
                    const SizedBox(height: 6),
                    Text("Tips: ${step.tips}",
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ---------------- STARTING PHOTO ----------------
            const Text(
              'Your Starting Photo:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            if (kIsWeb && state.userWebImage != null)
              Image.memory(state.userWebImage!, height: 200, fit: BoxFit.cover)
            else if (state.userImage != null)
              Image.file(state.userImage!, height: 200, fit: BoxFit.cover)
            else
              OutlinedButton.icon(
                onPressed: () => _pickImage(context, false),
                icon: const Icon(Icons.upload),
                label: const Text("Upload Starting Photo"),
              ),
            const SizedBox(height: 16),

            // ---------------- COMPLETED STEP PHOTO ----------------
            const Text(
              'Upload After Completing This Step:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            if (kIsWeb && state.completedWebImage != null)
              Image.memory(state.completedWebImage!,
                  height: 200, fit: BoxFit.cover)
            else if (state.completedImage != null)
              Image.file(state.completedImage!, height: 200, fit: BoxFit.cover)
            else
              OutlinedButton.icon(
                onPressed: () => _pickImage(context, true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Upload Completed Step"),
              ),
            const SizedBox(height: 16),

            // ---------------- FEEDBACK SECTION ----------------
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.feedback != null)
              Card(
                color: Colors.pink.shade50,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('AI Feedback',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${state.feedback!.score}/100'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Positive: ${state.feedback!.positive}'),
                      Text('Improvement: ${state.feedback!.improvement}'),
                      Text('Tip: ${state.feedback!.tip}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // ---------------- NAVIGATION BUTTONS ----------------
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.redoStep,
                    child: const Text('Redo Step'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      state.currentStep < look.steps.length - 1
                          ? 'Next Step'
                          : 'Complete',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
