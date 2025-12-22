import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/api_service.dart';
import 'recommendation_screen.dart';

class ProfileScreen extends StatefulWidget {
  final dynamic imageFile;

  const ProfileScreen({super.key, this.imageFile});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? gender = 'FEMALE';
  String? bodyType = 'AVERAGE';
  String? eventType = 'CASUAL';

  String? faceShape;
  String? tone;        // bucket e.g. caramel_brown
  String? toneName;    // readable e.g. Caramel Brown

  bool _loading = true;

  Uint8List? _webImageBytes;
  File? _localImageFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndAnalyzeImage();
    });
  }

  // ---------------------------------------------------------------------------
  //  🔥 /api/classify — Extract Tone + ToneName + FaceShape
  // ---------------------------------------------------------------------------
  Future<void> _loadAndAnalyzeImage() async {
    final appState = context.read<MakeupAppState>();

    try {
      if (mounted) setState(() => _loading = true);

      // -------- LOAD (Web or Mobile) --------
      if (kIsWeb) {
        final bytes = await widget.imageFile.readAsBytes();
        _webImageBytes = bytes;
        appState.setWebImage(bytes, false);
      } else {
        final file = File(widget.imageFile.path);
        _localImageFile = file;
        appState.setUserImage(file);
      }

      // -------------------------------------------------------------------
      //  🔥 CLASSIFY REQUEST
      // -------------------------------------------------------------------
      dynamic classifyResponse = {};

      try {
        classifyResponse = await ApiService.faceScanApi(widget.imageFile);
      } catch (e) {
        debugPrint("faceScanApi error: $e");
      }

      print("🔍 CLASSIFY RESPONSE => $classifyResponse");

      // ------------------ FIXED EXTRACTION ------------------
      if (classifyResponse is Map && classifyResponse["success"] == true) {
        // FACE SHAPE
        if (classifyResponse["face_shape"] is Map) {
          faceShape = classifyResponse["face_shape"]["shape"]?.toString() ?? "Unknown";
        }

        // SKIN TONE
        if (classifyResponse["skin_tone"] is Map) {
          tone = classifyResponse["skin_tone"]["bucket"]?.toString() ?? "Unknown";
          toneName = classifyResponse["skin_tone"]["color_name"]?.toString() ?? tone;
        }
      }

      // fallback
      faceShape ??= "Unknown";
      tone ??= "Unknown";
      toneName ??= tone;

    } catch (e) {
      debugPrint("Error analyzing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error analyzing image: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // 🚀 NAVIGATE — MUST PASS toneName NOW
  // ---------------------------------------------------------------------------
  void _getRecommendations() {
    if (_loading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please wait, analysis is still running.")),
      );
      return;
    }

    if (faceShape == "Unknown" || tone == "Unknown") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Analysis failed. Try again.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendationScreen(
          faceShape: faceShape!,
          tone: tone!,         // bucket
          toneName: toneName!, // ✅ FIXED — readable tone
          gender: gender!,
          event: eventType!,
          bodyType: bodyType!,
          imageFile: widget.imageFile,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🖼 Image Display
  // ---------------------------------------------------------------------------
  Widget _buildImageWidget() {
    if (kIsWeb && _webImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          _webImageBytes!,
          height: 220,
          width: 220,
          fit: BoxFit.cover,
        ),
      );
    } else if (!kIsWeb && _localImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          _localImageFile!,
          height: 220,
          width: 220,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return const Icon(Icons.person, size: 100, color: Colors.white70);
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text("Your Profile", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImageWidget(),
            const SizedBox(height: 24),

            if (_loading)
              const CircularProgressIndicator(color: Colors.purpleAccent)
            else ...[
              Text("Face Shape: $faceShape",
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 12),
              Text("Skin Tone: $toneName",
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
            ],

            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              decoration: _inputDecoration("Gender"),
              dropdownColor: Colors.black87,
              style: const TextStyle(color: Colors.white),
              value: gender,
              onChanged: (v) => setState(() => gender = v),
              items: ['MALE', 'FEMALE']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              decoration: _inputDecoration("Body Type"),
              dropdownColor: Colors.black87,
              style: const TextStyle(color: Colors.white),
              value: bodyType,
              onChanged: (v) => setState(() => bodyType = v),
              items: ['SLIM', 'AVERAGE', 'MUSCULAR', 'HEAVY']
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              decoration: _inputDecoration("Event"),
              dropdownColor: Colors.black87,
              style: const TextStyle(color: Colors.white),
              value: eventType,
              onChanged: (v) => setState(() => eventType = v),
              items: ['CASUAL', 'PARTY', 'BUSINESS', 'WEDDING']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6200EE),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: _getRecommendations,
              icon: const Icon(Icons.recommend, color: Colors.white),
              label: const Text("Get Recommendations",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    );
  }
}
