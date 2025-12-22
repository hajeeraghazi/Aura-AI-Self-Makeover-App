// ignore_for_file: use_build_context_synchronously

import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'profile_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();

  // -------------------------------------------------------------------
  // ⭐ PICK FROM GALLERY (Works on Android, iOS, Web)
  // -------------------------------------------------------------------
  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return;

      final appState = context.read<MakeupAppState>();

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        appState.setWebImage(bytes, false);
      } else {
        appState.setUserImage(File(pickedFile.path));
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(imageFile: pickedFile),
        ),
      );
    } catch (e) {
      _showError("Gallery Error: $e");
    }
  }

  // -------------------------------------------------------------------
  // ⭐ TAKE SELFIE
  // Web → ImagePicker(Camera)
  // Mobile → ImagePicker(Camera)
  // (Stable and cross-platform unlike camera plugin)
  // -------------------------------------------------------------------
  Future<void> _takeSelfie(BuildContext context) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (pickedFile == null) return;

      final appState = context.read<MakeupAppState>();

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        appState.setWebImage(bytes, false);
      } else {
        appState.setUserImage(File(pickedFile.path));
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(imageFile: pickedFile),
        ),
      );
    } catch (e) {
      _showError("Camera not accessible.\n\nPlease allow camera permission.");
    }
  }

  // -------------------------------------------------------------------
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(msg, textAlign: TextAlign.center),
      ),
    );
  }

  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Upload Your Photo",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              "Choose an option",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),

            // ------------------- Gallery Button -------------------
            _actionButton(
              icon: Icons.photo_library_rounded,
              text: "Upload from Gallery",
              color: Colors.blueAccent,
              onTap: () => _pickFromGallery(context),
            ),

            const SizedBox(height: 20),

            // ------------------- Camera Button --------------------
            _actionButton(
              icon: Icons.camera_alt_rounded,
              text: "Take a Selfie",
              color: Colors.pinkAccent,
              onTap: () => _takeSelfie(context),
            ),

            const Spacer(),

            const Text(
              "AURA AI • Personal Makeover Assistant",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  Widget _actionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }
}
