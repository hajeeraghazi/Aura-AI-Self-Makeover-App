import 'package:flutter/material.dart';

class ImageUploadWidget extends StatelessWidget {
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;

  const ImageUploadWidget({
    super.key,
    required this.onCameraPressed,
    required this.onGalleryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.pink.shade400, Colors.pink.shade200],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.shade300.withOpacity(0.5),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.face_retouching_natural,
                size: 75,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              "Upload Your Photo",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Choose a clear, front-facing picture\nfor the most accurate makeup guide.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 45),
            GestureDetector(
              onTap: onCameraPressed,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade500, Colors.pink.shade300],
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      "Take Photo",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onGalleryPressed,
              icon: Icon(Icons.photo, color: Colors.pink.shade400),
              label: Text(
                "Choose From Gallery",
                style: TextStyle(
                  color: Colors.pink.shade400,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.pink.shade300),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
